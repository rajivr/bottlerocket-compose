%global _cross_first_party 1
%undefine _debugsource_packages

# Do not prefer shared linking, since the libstd we use at build time
# may not match the one installed on the final image.
%global __global_rustflags_shared %__global_rustflags -C link-arg=-Wl,-soname=libsettings.so

%global _cross_pluginsdir %{_cross_libdir}/settings-plugins

Name: %{_cross_os}settings-plugins
Version: 0.0
Release: 1%{?dist}
Summary: Settings plugins
License: Apache-2.0 OR MIT
URL: https://github.com/bottlerocket-os/bottlerocket
BuildRequires: %{_cross_os}glibc-devel
Requires: %{_cross_os}glibc
Requires: %{_cross_os}settings-plugin(any)

%description
%{summary}.

%package aws-compose
Summary: Settings plugin for the aws-compose variant
Requires: %{_cross_os}variant(aws-compose)
Provides: %{_cross_os}settings-plugin(any)
Provides: %{_cross_os}settings-plugin(aws-compose)
Conflicts: %{_cross_os}settings-plugin(any)

%description aws-compose
%{summary}.

%package aws-dev
Summary: Settings plugin for the aws-dev variant
Requires: %{_cross_os}variant(aws-dev)
Provides: %{_cross_os}settings-plugin(any)
Provides: %{_cross_os}settings-plugin(aws-dev)
Conflicts: %{_cross_os}settings-plugin(any)

%description aws-dev
%{summary}.

%package metal-dev
Summary: Settings plugin for the metal-dev variant
Requires: %{_cross_os}variant(metal-dev)
Provides: %{_cross_os}settings-plugin(any)
Provides: %{_cross_os}settings-plugin(metal-dev)
Conflicts: %{_cross_os}settings-plugin(any)

%description metal-dev
%{summary}.

%prep
%setup -T -c
%cargo_prep

%build
%cargo_build --manifest-path %{_builddir}/sources/Cargo.toml \
  -p settings-plugin-aws-compose \
  -p settings-plugin-aws-dev \
  -p settings-plugin-metal-dev \
  %{nil}

%install
install -d %{buildroot}%{_cross_pluginsdir}
install -d %{buildroot}%{_cross_factorydir}%{_cross_sysconfdir}/ld.so.conf.d
install -d %{buildroot}%{_cross_tmpfilesdir}

for plugin in \
  aws-compose \
  aws-dev \
  metal-dev \
  ;
do
  install -d "%{buildroot}%{_cross_pluginsdir}/${plugin}"
  plugin_so="libsettings_$(echo "${plugin}" | sed -e 's,-,_,g' -e 's,\.,_,g').so"
  install -p -m 0755 \
    "${HOME}/.cache/%{__cargo_target}/release/${plugin_so}" \
    "%{buildroot}%{_cross_pluginsdir}/${plugin}/libsettings.so"
  echo \
    "%{_cross_pluginsdir}/${plugin}" > \
    "%{buildroot}%{_cross_factorydir}%{_cross_sysconfdir}/ld.so.conf.d/${plugin}.conf"
  echo \
    "C /etc/ld.so.conf.d/${plugin}.conf" > \
    "%{buildroot}%{_cross_tmpfilesdir}/settings-plugin-${plugin}.conf"
done

%files
%dir %{_cross_pluginsdir}

%files aws-compose
%{_cross_pluginsdir}/aws-compose/libsettings.so
%{_cross_factorydir}%{_cross_sysconfdir}/ld.so.conf.d/aws-compose.conf
%{_cross_tmpfilesdir}/settings-plugin-aws-compose.conf

%files aws-dev
%{_cross_pluginsdir}/aws-dev/libsettings.so
%{_cross_factorydir}%{_cross_sysconfdir}/ld.so.conf.d/aws-dev.conf
%{_cross_tmpfilesdir}/settings-plugin-aws-dev.conf

%files metal-dev
%{_cross_pluginsdir}/metal-dev/libsettings.so
%{_cross_factorydir}%{_cross_sysconfdir}/ld.so.conf.d/metal-dev.conf
%{_cross_tmpfilesdir}/settings-plugin-metal-dev.conf
