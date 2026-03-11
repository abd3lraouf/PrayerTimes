#!/bin/bash
set -e

APP="PrayerTimes"
DERIVED_DATA="$HOME/Library/Developer/Xcode/DerivedData"
BUILD_DIR=$(find "$DERIVED_DATA" -maxdepth 1 -name "${APP}-*" -type d | head -1)
APP_PATH="$BUILD_DIR/Build/Products/Debug/${APP}.app"

pkill -x "$APP" 2>/dev/null && sleep 0.5 || true

xcodebuild -scheme "$APP" -configuration Debug build 2>&1 | tail -3

open "$APP_PATH"
