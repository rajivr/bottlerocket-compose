%global _cross_first_party 1
%undefine _debugsource_packages

Name: %{_cross_os}compose-containers
Version: 0.0
Release: 1%{?dist}
Summary: Manage compose containers
License: Apache-2.0

# sources < 100: misc
Source2: compose-containers-toml

# 1xx sources: systemd units
Source100: compose-containers@.service

# 2xx sources: tmpfilesd configs
Source200: compose-containers-tmpfiles.conf

BuildRequires: %{_cross_os}glibc-devel
Requires: %{name}(binaries)
Requires: %{_cross_os}docker-compose

%description
%{summary}.

%package bin
Summary: compose-containers binary
Provides: %{name}(binaries)

%description bin
%{summary}.

%prep
%setup -T -c
%cargo_prep

%build

%cargo_build --manifest-path %{_builddir}/sources/Cargo.toml \
  -p compose-containers \
  %{nil}

%install
install -d %{buildroot}%{_cross_bindir}
install -p -m 0755 %{__cargo_outdir}/compose-containers %{buildroot}%{_cross_bindir}

install -d %{buildroot}%{_cross_templatedir}
install -p -m 0644 %{S:2} %{buildroot}%{_cross_templatedir}

install -d %{buildroot}%{_cross_unitdir}
install -p -m 0644 %{S:100} %{buildroot}%{_cross_unitdir}

install -d %{buildroot}%{_cross_tmpfilesdir}
install -p -m 0644 %{S:200} %{buildroot}%{_cross_tmpfilesdir}/compose-containers.conf

%files
%{_cross_unitdir}/compose-containers@.service
%dir %{_cross_templatedir}
%{_cross_templatedir}/compose-containers-toml
%{_cross_tmpfilesdir}/compose-containers.conf

%files bin
%{_cross_bindir}/compose-containers

%changelog
