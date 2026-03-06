#!/bin/bash

# Script to bump version numbers

set -e

if [ $# -eq 0 ]; then
    echo "Usage: ./scripts/bump-version.sh <version> [build_number]"
    echo "Example: ./scripts/bump-version.sh 1.1.0 2"
    exit 1
fi

VERSION=$1
BUILD_NUMBER=${2:-"1"}

echo "Updating version to $VERSION (build $BUILD_NUMBER)"

# Update Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" PrayerTimes/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" PrayerTimes/Info.plist

# Update project.pbxproj for all targets
sed -i '' "s/MARKETING_VERSION = .*;/MARKETING_VERSION = $VERSION;/g" PrayerTimes.xcodeproj/project.pbxproj
sed -i '' "s/CURRENT_PROJECT_VERSION = .*;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" PrayerTimes.xcodeproj/project.pbxproj

echo "✅ Version updated to $VERSION (build $BUILD_NUMBER)"
