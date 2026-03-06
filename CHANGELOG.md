# Changelog

All notable changes to PrayerTimes will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-03-06

### Added
- Initial release of PrayerTimes
- Menu bar app for macOS showing prayer times
- Automatic location detection for accurate prayer times
- Manual location search with support for any city worldwide
- Multiple calculation methods (MWL, ISNA, Umm al-Qura, Kemenag, Diyanet, etc.)
- Hanafi madhhab support for Asr prayer time
- Prayer time correction feature (±60 minutes per prayer)
- Customizable menu bar display options
  - Simple moon icon
  - Countdown to next prayer
  - Exact time of next prayer
  - Compact text mode
- Optional sunnah prayers (Tahajud and Dhuha)
- Native macOS notifications for prayer times
- Custom adhan sound support
- Multi-language support (English, Arabic, Indonesian)
- Light and dark mode support
- Launch at login feature
- Beautiful onboarding experience

### Security
- Properly sandboxed with minimal entitlements
- No data collection or tracking
- Only one legitimate network call to OpenStreetMap for geocoding
- All prayer calculations done locally

### Acknowledgments
- Forked from [Sajda](https://github.com/ikoshura/Sajda) by [ikoshura](https://github.com/ikoshura)
- Uses [Adhan](https://github.com/batoulapps/Adhan) library for prayer time calculations
- Uses [FluidMenuBarExtra](https://github.com/lfroms/fluid-menu-bar-extra) for menu bar UI
- Uses [NavigationStack](https://github.com/indieSoftware/NavigationStack) for navigation

## Release Notes Template

### [Unreleased]

#### Added
- 

#### Changed
- 

#### Fixed
- 

#### Security
- 
