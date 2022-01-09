Name:    KitchenOwl
Release: 1%{?dist}
Summary: KitchenOwl helps you organize your grocery life
License: Apache 2.0
Source0: kitchenowl
Source1: kitchenowl.desktop
Requires: jsoncpp
Requires: libsecret

%description
KitchenOwl helps you organize your grocery life.

%install
mkdir -p %{buildroot}%{_datadir}/kitchenowl
mkdir -p %{buildroot}%{_datadir}/applications
mkdir -p %{buildroot}%{_bindir}
cp -R %{SOURCE0} %{buildroot}%{_datadir}
chmod +x %{buildroot}%{_datadir}/kitchenowl/kitchenowl
ln -s %{_datadir}/kitchenowl/kitchenowl %{buildroot}%{_bindir}
install -p -m 755 %{SOURCE1} %{buildroot}%{_datadir}/applications

%files
%defattr(-,root,root)
%dir %{_datadir}/kitchenowl
%{_datadir}/applications/kitchenowl.desktop
%{_datadir}/kitchenowl
%{_bindir}/kitchenowl

%clean
rm -rf %{buildroot}

%changelog
* Tue Mar 30 2021 Tom Bursch <tombursch@gmail.com> - 22
- Initial Release

