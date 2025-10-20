#[macro_use]
extern crate log;

use bottlerocket_modeled_types::Identifier;

use simplelog::{Config as LogConfig, LevelFilter, SimpleLogger};
use snafu::{ResultExt, ensure};

use std::collections::HashMap;
use std::env;
use std::ffi::OsStr;
use std::path::{Path, PathBuf};
use std::process::{self, Command};
use std::str::FromStr;

const CONFIG_FILE: &str = "/etc/compose-containers/compose-containers.toml";

mod config;

mod constants {
    pub(crate) const SYSTEMCTL_BIN: &str = "/bin/systemctl";
}

mod error {
    use snafu::Snafu;
    use std::io;
    use std::process::{Command, Output};

    #[derive(Debug, Snafu)]
    #[snafu(visibility(pub(super)))]
    pub(super) enum Error {
        #[snafu(display("Error reading config from {}: {}", config_file, source))]
        ReadConfig {
            config_file: String,
            source: io::Error,
        },

        #[snafu(display("Error parsing config toml from {}: {}", config_file, source))]
        ConfigToml {
            config_file: String,
            source: toml::de::Error,
        },

        #[snafu(display("Failed to execute '{:?}': {}", command, source))]
        ExecutionFailure {
            command: Box<Command>,
            source: std::io::Error,
        },

        #[snafu(display("'{}' failed - stderr: {}",
                        bin_path, std::str::from_utf8(&output.stderr).unwrap_or("<invalid UTF-8>")))]
        CommandFailure { bin_path: String, output: Output },

        #[snafu(display("Failed to manage {} of {} compose containers", failed, tried))]
        ManageContainersFailed { failed: usize, tried: usize },

        #[snafu(display("Logger setup error: {}", source))]
        Logger { source: log::SetLoggerError },
    }
}

type Result<T> = std::result::Result<T, error::Error>;

/// Read the currently defined compose containers from the config file
fn get_compose_containers<P>(
    config_path: P,
) -> Result<HashMap<Identifier, config::ComposeContainer>>
where
    P: AsRef<Path>,
{
    let config_path = config_path.as_ref();
    debug!(
        "Reading containers from the config file: {}",
        config_path.display()
    );
    let config = std::fs::read_to_string(config_path).context(error::ReadConfigSnafu {
        config_file: format!("{config_path:?}"),
    })?;
    let config: config::ComposeContainersConfig =
        toml::from_str(&config).context(error::ConfigTomlSnafu {
            config_file: format!("{config_path:?}"),
        })?;

    // If compose containers aren't defined, return an empty map
    Ok(config.compose_containers.unwrap_or_default())
}

/// SystemdUnit stores the systemd unit being manipulated
struct SystemdUnit<'a> {
    unit: &'a str,
}

impl<'a> SystemdUnit<'a> {
    fn new(unit: &'a str) -> Self {
        SystemdUnit { unit }
    }

    fn stop(&self) -> Result<()> {
        // This is intentionally blocking to simplify reasoning about the state
        // of the system. The stop command might fail if the unit has just been
        // created and we haven't done a `systemctl daemon-reload` yet.
        let _ = command(constants::SYSTEMCTL_BIN, ["stop", self.unit]);
        Ok(())
    }

    fn enable(&self) -> Result<()> {
        command(
            constants::SYSTEMCTL_BIN,
            ["enable", self.unit, "--no-reload", "--no-block"],
        )?;
        Ok(())
    }

    fn disable(&self) -> Result<()> {
        command(
            constants::SYSTEMCTL_BIN,
            ["disable", self.unit, "--no-reload", "--no-block"],
        )?;
        Ok(())
    }
}

/// Wrapper around process::Command that adds error checking.
fn command<I, S>(bin_path: &str, args: I) -> Result<String>
where
    I: IntoIterator<Item = S>,
    S: AsRef<OsStr>,
{
    let mut command = Command::new(bin_path);
    command.args(args);
    let output = command
        .output()
        .context(error::ExecutionFailureSnafu { command })?;

    let stdout = String::from_utf8_lossy(&output.stdout).to_string();

    trace!("stdout: {stdout}");
    trace!("stderr: {}", String::from_utf8_lossy(&output.stderr));

    ensure!(
        output.status.success(),
        error::CommandFailureSnafu { bin_path, output }
    );
    Ok(stdout)
}

/// Store the args we receive on the command line
struct Args {
    log_level: LevelFilter,
    config_path: PathBuf,
}

/// Print a usage message in the event a bad arg is passed
fn usage() -> ! {
    let program_name = env::args().next().unwrap_or_else(|| "program".to_string());
    eprintln!(
        r"Usage: {program_name}
            [ --config-path PATH ]
            [ --log-level trace|debug|info|warn|error ]

    Config path defaults to {CONFIG_FILE}",
    );
    process::exit(2);
}

/// Prints a more specific message before exiting through usage().
fn usage_msg<S: AsRef<str>>(msg: S) -> ! {
    eprintln!("{}\n", msg.as_ref());
    usage();
}

/// Parse the args to the program and return an Args struct
fn parse_args(args: env::Args) -> Args {
    let mut log_level = None;
    let mut config_path = None;

    let mut iter = args.skip(1);
    while let Some(arg) = iter.next() {
        match arg.as_ref() {
            "--log-level" => {
                let log_level_str = iter
                    .next()
                    .unwrap_or_else(|| usage_msg("Did not give argument to --log-level"));
                log_level =
                    Some(LevelFilter::from_str(&log_level_str).unwrap_or_else(|_| {
                        usage_msg(format!("Invalid log level '{log_level_str}'"))
                    }));
            }

            "--config-path" => {
                config_path = Some(
                    iter.next()
                        .unwrap_or_else(|| usage_msg("Did not give argument to --config-path"))
                        .into(),
                )
            }

            _ => usage(),
        }
    }

    Args {
        log_level: log_level.unwrap_or(LevelFilter::Info),
        config_path: config_path.unwrap_or_else(|| CONFIG_FILE.into()),
    }
}

fn handle_compose_container<S>(name: S, image_details: &config::ComposeContainer) -> Result<()>
where
    S: AsRef<str>,
{
    let name = name.as_ref();

    let enabled = image_details.enabled.unwrap_or(false);

    info!("Compose container '{name}' is enabled: {enabled}");

    // Now start/stop the container according to the 'enabled' setting
    let unit_name = format!("compose-containers@{name}.service");
    let systemd_unit = SystemdUnit::new(&unit_name);

    // Unconditionally stop the container, and wait for it to complete. Don't worry about
    // the enabled or disabled status for the unit yet - we'll fix that up later.
    debug!("Stopping compose container: '{unit_name}'");
    systemd_unit.stop()?;

    if enabled {
        debug!("Enabling compose container: '{unit_name}'");
        systemd_unit.enable()?;
    } else {
        debug!("Disabling compose container: '{unit_name}'");
        systemd_unit.disable()?;
    }

    Ok(())
}

fn run() -> Result<()> {
    let args = parse_args(env::args());

    // SimpleLogger will send errors to stderr and anything less to stdout.
    SimpleLogger::init(args.log_level, LogConfig::default()).context(error::LoggerSnafu)?;

    info!("compose-containers started");

    let mut failed = 0usize;
    let compose_containers = get_compose_containers(args.config_path)?;

    for (name, compose_container) in compose_containers.iter() {
        if let Err(e) = handle_compose_container(name, compose_container) {
            failed += 1;
            error!("Failed to handle compose container '{}': {}", &name, e);
        }
    }

    ensure!(
        failed == 0,
        error::ManageContainersFailedSnafu {
            failed,
            tried: compose_containers.len()
        }
    );

    Ok(())
}

// Returning a Result from main makes it print a Debug representation of the error, but with Snafu
// we have nice Display representations of the error, so we wrap "main" (run) and print any error.
// https://github.com/shepmaster/snafu/issues/110
fn main() {
    if let Err(e) = run() {
        eprintln!("{e}");
        process::exit(1);
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use bottlerocket_modeled_types::Identifier;

    #[test]
    fn test_get_compose_containers() {
        let config_toml = r#"[compose-containers."foo"]
        enabled = true
        "#;

        let temp_dir = tempfile::TempDir::new().unwrap();
        let temp_config = Path::join(temp_dir.path(), "compose-containers.toml");
        std::fs::write(&temp_config, config_toml).unwrap();

        let compose_containers = get_compose_containers(&temp_config).unwrap();

        let mut expected_compose_containers = HashMap::new();
        expected_compose_containers.insert(
            Identifier::try_from("foo").unwrap(),
            config::ComposeContainer {
                enabled: Some(true),
            },
        );

        assert_eq!(compose_containers, expected_compose_containers)
    }
}
