%global goproject github.com/docker
%global gorepo compose
%global goimport %{goproject}/%{gorepo}

%global gover 2.40.3
%global rpmver %{gover}

%global _dwz_low_mem_die_limit 0

Name: %{_cross_os}docker-%{gorepo}
Version: %{rpmver}
Release: 1%{?dist}
Summary: Docker Compose
License: Apache-2.0
URL: https://%{goimport}
Source0: compose-%{gover}.tar.gz
Source1: bundled-compose-%{gover}.tar.gz

BuildRequires: git
BuildRequires: %{_cross_os}glibc-devel
Requires: %{name}(binaries)

%description
%{summary}.

%package bin
Summary: Docker Compose binaries
Provides: %{name}(binaries)
Requires: (%{_cross_os}image-feature(no-fips) and %{name})
Conflicts: (%{_cross_os}image-feature(fips) or %{name}-fips-bin)

%description bin
%{summary}.

%package fips-bin
Summary: Docker Compose binaries, FIPS edition
Provides: %{name}(binaries)
Requires: (%{_cross_os}image-feature(fips) and %{name})
Conflicts: (%{_cross_os}image-feature(no-fips) or %{name}-bin)

%description fips-bin
%{summary}.

%prep
%setup -n %{gorepo}-%{gover} -q
%setup -T -D -n %{gorepo}-%{gover} -b 1 -q

%build
%set_cross_go_flags

LD_VERSION="-X github.com/docker/compose/v2/internal.Version=%{gover}"

export GOTOOLCHAIN=local
export GO_MAJOR="1.25"

# bottlerocket-sdk v0.65.1 has GO version 1.25.3
# https://github.com/bottlerocket-os/bottlerocket-sdk/blob/v0.65.1/Dockerfile#L498

go mod edit -go 1.25.3

go build -ldflags="${GOLDFLAGS} ${LD_VERSION}" -o docker-compose ./cmd
gofips build -ldflags="${GOLDFLAGS} ${LD_VERSION}" -o fips/docker-compose ./cmd

%install
install -d %{buildroot}%{_cross_bindir}
install -p -m 0755 docker-compose %{buildroot}%{_cross_bindir}

install -d %{buildroot}%{_cross_fips_bindir}
install -p -m 0755 fips/docker-compose %{buildroot}%{_cross_fips_bindir}

%files
%license LICENSE NOTICE
%{_cross_attribution_file}

%files bin
%{_cross_bindir}/docker-compose

%files fips-bin
%{_cross_fips_bindir}/docker-compose

%changelog
