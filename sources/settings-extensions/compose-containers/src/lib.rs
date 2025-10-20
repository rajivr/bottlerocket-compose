//! Settings related to compose containers.
use bottlerocket_model_derive::model;
use bottlerocket_modeled_types::Identifier;
use bottlerocket_settings_sdk::{GenerateResult, SettingsModel};

use serde::{Deserialize, Deserializer, Serialize, Serializer};

use std::collections::HashMap;
use std::convert::Infallible;

#[derive(Clone, Debug, Default, PartialEq)]
pub struct ComposeContainersSettingsV1 {
    pub compose_containers: HashMap<Identifier, ComposeContainer>,
}

impl Serialize for ComposeContainersSettingsV1 {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        self.compose_containers.serialize(serializer)
    }
}

impl<'de> Deserialize<'de> for ComposeContainersSettingsV1 {
    fn deserialize<D>(deserializer: D) -> std::result::Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let compose_containers = HashMap::deserialize(deserializer)?;
        Ok(Self { compose_containers })
    }
}

#[model(impl_default = true)]
struct ComposeContainer {
    enabled: bool,
}

type Result<T> = std::result::Result<T, Infallible>;

impl SettingsModel for ComposeContainersSettingsV1 {
    type PartialKind = Self;
    type ErrorKind = Infallible;

    fn get_version() -> &'static str {
        "v1"
    }

    fn set(_current_value: Option<Self>, _target: Self) -> Result<()> {
        // Set anything that can be parsed as ComposeContainersSettingsV1.
        Ok(())
    }

    fn generate(
        existing_partial: Option<Self::PartialKind>,
        _dependent_settings: Option<serde_json::Value>,
    ) -> Result<GenerateResult<Self::PartialKind, Self>> {
        Ok(GenerateResult::Complete(
            existing_partial.unwrap_or_default(),
        ))
    }

    fn validate(_value: Self, _validated_settings: Option<serde_json::Value>) -> Result<()> {
        // ComposeContainersSettingsV1 is validated during deserialization.
        Ok(())
    }
}

#[cfg(test)]
mod test {
    use super::*;
    use serde_json::json;

    #[test]
    fn test_generate_compose_containers() {
        assert_eq!(
            ComposeContainersSettingsV1::generate(None, None).unwrap(),
            GenerateResult::Complete(ComposeContainersSettingsV1 {
                compose_containers: HashMap::new(),
            })
        );
    }

    #[test]
    fn test_serde_compose_containers() {
        let test_json = json!({
            "foo": {
            "enabled": true
            }
        });

        let test_json_str = test_json.to_string();

        let compose_containers: ComposeContainersSettingsV1 =
            serde_json::from_str(&test_json_str).unwrap();

        let mut expected_compose_containers: HashMap<Identifier, ComposeContainer> = HashMap::new();
        expected_compose_containers.insert(
            Identifier::try_from("foo").unwrap(),
            ComposeContainer {
                enabled: Some(true),
            },
        );

        assert_eq!(
            compose_containers,
            ComposeContainersSettingsV1 {
                compose_containers: expected_compose_containers
            }
        );

        let serialized_json: serde_json::Value = serde_json::to_string(&compose_containers)
            .map(|s| serde_json::from_str(&s).unwrap())
            .unwrap();

	assert_eq!(serialized_json, test_json);
    }
}
