#!/bin/bash

# Script to build and create DMG for PrayerTimes

set -e

VERSION=${1:-"1.0.0"}
BUILD_NUMBER=${2:-"1"}

echo "Building PrayerTimes version $VERSION (build $BUILD_NUMBER)"

# Update Info.plist with version
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" PrayerTimes/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" PrayerTimes/Info.plist

# Build the app
echo "Building app..."
xcodebuild -project PrayerTimes.xcodeproj \
  -scheme PrayerTimes \
  -configuration Release \
  -derivedDataPath build \
  clean build \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Create release directory
mkdir -p release

# Copy app bundle
echo "Copying app bundle..."
cp -r build/Build/Products/Release/PrayerTimes.app release/

# Create DMG
echo "Creating DMG..."
if command -v create-dmg &> /dev/null; then
    create-dmg \
      --volname "PrayerTimes" \
      --window-pos 200 120 \
      --window-size 660 400 \
      --icon-size 100 \
      --icon "PrayerTimes.app" 180 170 \
      --hide-extension "PrayerTimes.app" \
      --app-drop-link 480 170 \
      "release/PrayerTimes-$VERSION.dmg" \
      "release/PrayerTimes.app"
else
    echo "create-dmg not found, creating simple DMG..."
    hdiutil create -volname "PrayerTimes" \
      -srcfolder release/PrayerTimes.app \
      -ov -format UDZO \
      "release/PrayerTimes-$VERSION.dmg"
fi

# Generate checksum
echo "Generating checksum..."
cd release
shasum -a 256 PrayerTimes-$VERSION.dmg > PrayerTimes-$VERSION.dmg.sha256

echo "✅ Build complete!"
echo "DMG location: release/PrayerTimes-$VERSION.dmg"
echo "Checksum: release/PrayerTimes-$VERSION.dmg.sha256"
