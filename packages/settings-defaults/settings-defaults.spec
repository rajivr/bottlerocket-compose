%global _cross_first_party 1
%undefine _debugsource_packages

%global cargo_clean %{__cargo_cross_env} %{__cargo} clean

%global _cross_defaultsdir %{_cross_datadir}/storewolf

Name: %{_cross_os}settings-defaults
Version: 0.0
Release: 1%{?dist}
Summary: Settings defaults
License: Apache-2.0 OR MIT
URL: https://github.com/bottlerocket-os/bottlerocket
BuildRequires: %{_cross_os}glibc-devel
Requires: %{_cross_os}settings-defaults(any)

%description
%{summary}.

%package aws-compose
Summary: Settings defaults for the aws-compose variant
Requires: %{_cross_os}variant(aws-compose)
Provides: %{_cross_os}settings-defaults(any)
Provides: %{_cross_os}settings-defaults(aws-compose)
Conflicts: %{_cross_os}settings-defaults(any)

%description aws-compose
%{summary}.

%package aws-dev
Summary: Settings defaults for the aws-dev variant
Requires: %{_cross_os}variant(aws-dev)
Provides: %{_cross_os}settings-defaults(any)
Provides: %{_cross_os}settings-defaults(aws-dev)
Conflicts: %{_cross_os}settings-defaults(any)

%description aws-dev
%{summary}.

%package metal-dev
Summary: Settings defaults for the metal-dev variant
Requires: %{_cross_os}variant(metal-dev)
Provides: %{_cross_os}settings-defaults(any)
Provides: %{_cross_os}settings-defaults(metal-dev)
Conflicts: %{_cross_os}settings-defaults(any)

%description metal-dev
%{summary}.

%prep
%setup -T -c
%cargo_prep

%build
declare -a projects
for defaults in \
  aws-compose \
  aws-dev \
  metal-dev \
  ;
do
  projects+=( "-p" "settings-defaults-$(echo "${defaults}" | sed -e 's,\.,_,g')" )
done

# Output is written to an unpredictable directory name, so clean it up first to
# avoid reusing any cached artifacts.
%cargo_clean --manifest-path %{_builddir}/sources/Cargo.toml \
  "${projects[@]}" \
  %{nil}

%cargo_build --manifest-path %{_builddir}/sources/Cargo.toml \
  "${projects[@]}" \
  %{nil}

%install
install -d %{buildroot}%{_cross_defaultsdir}
install -d %{buildroot}%{_cross_tmpfilesdir}

for defaults in \
  aws-compose \
  aws-dev \
  metal-dev \
  ;
do
  crate="$(echo "${defaults}" | sed -e 's,\.,_,g')"
  for f in $(find "${HOME}/.cache" -name "settings-defaults-${crate}.toml") ; do
    install -p -m 0644 "${f}" "%{buildroot}%{_cross_defaultsdir}/${defaults}.toml"
  done
  echo \
    "L+ /etc/storewolf/defaults.toml - - - - %{_cross_defaultsdir}/${defaults}.toml" > \
    "%{buildroot}%{_cross_tmpfilesdir}/storewolf-defaults-${defaults}.conf"
done

%files
%dir %{_cross_defaultsdir}

%files aws-compose
%{_cross_defaultsdir}/aws-compose.toml
%{_cross_tmpfilesdir}/storewolf-defaults-aws-compose.conf

%files aws-dev
%{_cross_defaultsdir}/aws-dev.toml
%{_cross_tmpfilesdir}/storewolf-defaults-aws-dev.conf

%files metal-dev
%{_cross_defaultsdir}/metal-dev.toml
%{_cross_tmpfilesdir}/storewolf-defaults-metal-dev.conf
