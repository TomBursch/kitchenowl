#!/bin/sh

# Test requirements
if ! type "shyaml" > /dev/null; then
  echo "shyaml is required, install with pip3 install shyaml"
fi

# Go to project folder
cd $(dirname $0)
cd ../

# Read project information
NAME=$(cat pubspec.yaml | shyaml get-value name)
VERSION=$(cat pubspec.yaml | shyaml get-value version | grep -oE "^[^+]+")
DESCRIPTION=$(cat pubspec.yaml | shyaml get-value description)

# Build project and create structure
flutter build linux
mkdir -p build/debian/release
cp -r debian/$NAME build/debian/release/
cp -r build/linux/release/bundle/ build/debian/release/$NAME/usr/lib/$NAME/
cp debian/icon.png build/debian/release/$NAME/usr/lib/$NAME/

# DEB settings
CONTROL_FILE="build/debian/release/$NAME/DEBIAN/control"
echo "Package: $NAME" > $CONTROL_FILE
echo "Version: $VERSION" >> $CONTROL_FILE
echo "Description: $DESCRIPTION" >> $CONTROL_FILE
cat debian/$NAME/DEBIAN/control >> $CONTROL_FILE


DESKTOP_FILE="build/debian/release/$NAME/usr/share/applications/$NAME.desktop"
echo "[Desktop Entry]" > $DESKTOP_FILE
echo "Exec=$NAME" >> $DESKTOP_FILE
# echo "Name=$NAME" >> $DESKTOP_FILE
echo "Comment=$DESCRIPTION" >> $DESKTOP_FILE
echo "Version=$VERSION" >> $DESKTOP_FILE
cat debian/$NAME.desktop >> $DESKTOP_FILE


# Build and cleanup
cd build/debian/release/
dpkg-deb --build --root-owner-group $NAME
rm -r $NAME
