#!/bin/bash
DIR=$(dirname "$0")
echo ""
echo "  ✦ PrayerTimes Pro — Removing quarantine flag..."
echo ""
sudo xattr -rd com.apple.quarantine "$DIR/PrayerTimes.app"
echo "  ✓ Done! Launching PrayerTimes..."
echo ""
open "$DIR/PrayerTimes.app"
