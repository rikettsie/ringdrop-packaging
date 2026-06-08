%global crate ringdrop

Name:           %{crate}
Version:        0.14.1
Release:        1%{?dist}
Summary:        Secure, frugal P2P streamed file transfer with ring-based access control

License:        MIT
URL:            https://github.com/rikettsie/ringdrop
Source0:        %{url}/archive/v%{version}/%{crate}-%{version}.tar.gz
Source1:        %{crate}-%{version}-vendor.tar.gz
Source2:        ringdrop.metainfo.xml

# rust-packaging provides %%cargo_prep, %%cargo_build, etc.
BuildRequires:  rust-packaging >= 23

%description
Ringdrop is a secure, frugal P2P streamed file transfer tool with
ring-based access control, built on iroh-blobs and bao protocols.

To share a file, associate it with one or more rings and get back
an rdrop:// ticket. Only ring members can download it. Transfers
resume automatically if interrupted — no verified data is
re-transferred after a crash or disconnect.

The crate is named ringdrop but the installed binary is rdrop.

%prep
%autosetup -n %{crate}-%{version} -a1
%cargo_prep -v vendor

%build
%cargo_build

%install
install -Dpm 0755 target/release/rdrop %{buildroot}%{_bindir}/rdrop
install -Dpm 0644 docs/mascot.png \
    %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/ringdrop.png
install -Dpm 0644 %{SOURCE2} \
    %{buildroot}%{_datadir}/metainfo/io.github.rikettsie.ringdrop.metainfo.xml

%files
%license LICENSE-MIT
%doc README.md
%{_bindir}/rdrop
%{_datadir}/icons/hicolor/512x512/apps/ringdrop.png
%{_datadir}/metainfo/io.github.rikettsie.ringdrop.metainfo.xml

%changelog
* Mon Jun 08 2026 Enrico Fusto <enrico.fusto@protonmail.com> - 0.14.1-1
- Update to 0.14.1

* Mon Jun 08 2026 Enrico Fusto <enrico.fusto@protonmail.com> - 0.14.0-1
- Add AppStream metainfo and hicolor icon for software centers

* Sun Jun 07 2026 Enrico Fusto <enrico.fusto@protonmail.com> - 0.14.0-1
- Update to 0.14.0

* Sun Jun 07 2026 Enrico Fusto <enrico.fusto@protonmail.com> - 0.13.1-1
- Update to 0.13.1

* Fri Jun 05 2026 Enrico Fusto <enrico.fusto@protonmail.com> - 0.12.0-1
- Initial package
