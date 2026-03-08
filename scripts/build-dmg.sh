#!/bin/bash

# Script to build and create DMG for PrayerTimes using sindresorhus/create-dmg

set -e

VERSION=${1:-"1.0.0"}
BUILD_NUMBER=${2:-"1"}
SKIP_BUILD=${SKIP_BUILD:-false}

echo "✦ Building PrayerTimes version $VERSION (build $BUILD_NUMBER)"

# Ensure we are in the project root
cd "$(dirname "$0")/.."

# Build the app if not skipped
if [ "$SKIP_BUILD" = false ]; then
    echo "✦ Building app bundle..."
    xcodebuild -project PrayerTimes.xcodeproj \
      -scheme PrayerTimes \
      -configuration Release \
      -derivedDataPath build \
      clean build \
      CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:--}" \
      CODE_SIGNING_REQUIRED="${CODE_SIGNING_REQUIRED:-NO}" \
      CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}" \
      MARKETING_VERSION="$VERSION" \
      CURRENT_PROJECT_VERSION="$BUILD_NUMBER"
fi

# Create release directory
mkdir -p release
rm -rf release/*.dmg release/*.sha256

# Get the path to the built app
APP_PATH="build/Build/Products/Release/PrayerTimes.app"

if [ ! -d "$APP_PATH" ]; then
    echo "❌ Error: PrayerTimes.app not found in $APP_PATH"
    exit 1
fi

# Ensure the new create-dmg tool is installed
if ! command -v create-dmg &> /dev/null; then
    echo "✦ create-dmg not found. Installing via npm..."
    npm install --global create-dmg
fi

echo "✦ Creating a beautiful, clean DMG using create-dmg..."
# create-dmg takes the app path and an optional destination
# It automatically handles the background, arrow, and Application link in a standard way
create-dmg "$APP_PATH" release --overwrite

# Find the generated DMG (it uses "App Name 1.0.0.dmg" format)
GENERATED_DMG="release/PrayerTimes $VERSION.dmg"

# Rename to our standard format (hyphenated) for consistency if needed, 
# but create-dmg's default is also very clean. 
# Let's keep its default but ensure we know the filename for the checksum.
if [ -f "$GENERATED_DMG" ]; then
    FINAL_DMG="release/PrayerTimes-$VERSION.dmg"
    mv "$GENERATED_DMG" "$FINAL_DMG"
    
    # Generate checksum
    echo "✦ Generating checksum..."
    shasum -a 256 "$FINAL_DMG" > "$FINAL_DMG.sha256"
    
    echo "✅ DMG build complete!"
    echo "📍 Location: $FINAL_DMG"
    echo "📄 Checksum: $FINAL_DMG.sha256"
else
    echo "❌ Error: DMG was not generated at expected path: $GENERATED_DMG"
    ls -R release
    exit 1
fi
