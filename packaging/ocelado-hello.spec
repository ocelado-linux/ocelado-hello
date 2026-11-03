#
# spec file for package ocelado-hello
#
# Built on OBS from the git sources: see _service (obs_scm + cargo_vendor).
#

Name:           ocelado-hello
Version:        0.1.0
Release:        0
Summary:        Welcome app for Ocelado Linux (desktop and handheld)
License:        GPL-3.0-or-later
URL:            https://github.com/ocelado-linux/ocelado-hello
Source0:        %{name}-%{version}.tar.zst
Source1:        vendor.tar.zst
BuildRequires:  cargo
BuildRequires:  cargo-packaging
# edition 2024
BuildRequires:  rust >= 1.85
BuildRequires:  gcc-c++
# CXX-Qt cargo builds do not link with GNU ld.bfd (.cargo/config.toml uses lld)
BuildRequires:  lld
BuildRequires:  pkgconfig
BuildRequires:  qt6-base-devel
BuildRequires:  qt6-declarative-devel
BuildRequires:  qt6-declarative-tools
BuildRequires:  pkgconfig(libudev)
# QML modules used at runtime (QtQuick, Controls, Layouts, Shapes)
Requires:       qt6-declarative-imports
# SVG logo (imageformats/libqsvg.so)
Requires:       libQt6Svg6
# root helpers
Requires:       curl
Requires:       e2fsprogs
Requires:       jq
Requires:       parted
Requires:       polkit
Requires:       snapper
Requires:       transactional-update
Requires:       udisks2
Requires:       unzip
Requires:       util-linux
Recommends:     flatpak
Recommends:     konsole
ExclusiveArch:  x86_64

%description
ocelado-hello welcomes the user of Ocelado Linux and gathers the common
settings in one place: system updates and snapshots, kernel and boot
session, microSD cards for games, Decky Loader and its plugins,
controllers, recommended apps and bug reports. It has a desktop layout
and a handheld layout driven by a controller.

%prep
%autosetup -a1 -p1
# Crates from vendor.tar.zst (OBS builds without network)
cat >> .cargo/config.toml <<'EOF'

[source.crates-io]
replace-with = "vendored-sources"

[source.vendored-sources]
directory = "vendor"
EOF

%build
export QMAKE=%{_bindir}/qmake6
# RUSTFLAGS replaces the rustflags of .cargo/config.toml: keep lld here too
export RUSTFLAGS="%{build_rustflags} -C link-arg=-fuse-ld=lld"
cargo build --offline --release --locked

%install
install -Dm0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}
install -Dm0755 data/ocelado-hello-helper %{buildroot}%{_libexecdir}/%{name}/ocelado-hello-helper
install -Dm0755 data/ocelado-hello-query %{buildroot}%{_libexecdir}/%{name}/ocelado-hello-query
install -Dm0644 data/org.ocelado.hello.policy %{buildroot}%{_datadir}/polkit-1/actions/org.ocelado.hello.policy
install -Dm0644 data/ocelado-hello.desktop %{buildroot}%{_datadir}/applications/ocelado-hello.desktop
install -Dm0644 data/ocelado-hello-autostart.desktop %{buildroot}%{_sysconfdir}/xdg/autostart/ocelado-hello.desktop

%check
export QMAKE=%{_bindir}/qmake6
export RUSTFLAGS="%{build_rustflags} -C link-arg=-fuse-ld=lld"
cargo test --offline --release --locked

%files
%license LICENSE
%doc README.md data/novedades.example.json
%{_bindir}/%{name}
%dir %{_libexecdir}/%{name}
%{_libexecdir}/%{name}/ocelado-hello-helper
%{_libexecdir}/%{name}/ocelado-hello-query
%{_datadir}/polkit-1/actions/org.ocelado.hello.policy
%{_datadir}/applications/ocelado-hello.desktop
%config %{_sysconfdir}/xdg/autostart/ocelado-hello.desktop

%changelog
