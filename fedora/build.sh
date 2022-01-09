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
flutter build linux --release
mkdir -p build/fedora/release
cp -r build/linux/x64/release/bundle/ build/fedora/release/kitchenowl
cp linux/icon.png build/fedora/release/kitchenowl

SPEC_FILE="build/fedora/release/$NAME.spec"
echo "Version: v$VERSION" > $SPEC_FILE
cat fedora/$NAME.spec >> $SPEC_FILE

DESKTOP_FILE="build/fedora/release/$NAME.desktop"
echo "[Desktop Entry]" > $DESKTOP_FILE
echo "Exec=$NAME" >> $DESKTOP_FILE
echo "Icon=/usr/$NAME/icon.png" >> $DESKTOP_FILE
# echo "Name=$NAME" >> $DESKTOP_FILE
echo "Comment=$DESCRIPTION" >> $DESKTOP_FILE
echo "Version=$VERSION" >> $DESKTOP_FILE
cat linux/$NAME.desktop >> $DESKTOP_FILE


# Build and cleanup
cd build/fedora/release/
QA_RPATHS=0x0002 fedpkg --release f35 local
