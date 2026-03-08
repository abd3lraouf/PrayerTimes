# Changelog

All notable changes to PrayerTimes will be documented in this file.

## Version: 2.2.2 (03-08-2026)

* [1131447](https://github.com/abd3lraouf/PrayerTimes/commit/1131447) fix: resolve use-after-free crash in menu bar status item
* [3244300](https://github.com/abd3lraouf/PrayerTimes/commit/3244300) fix: resolve "app is damaged" error for GitHub releases
* [f2c0fb1](https://github.com/abd3lraouf/PrayerTimes/commit/f2c0fb1) fix: use precise xattr command to remove only quarantine attribute

## Version: 2.2.1 (03-07-2026)

* [07460e7](https://github.com/abd3lraouf/PrayerTimes/commit/07460e7) fix: correct RTL countdown display in Arabic menu bar

## Version: 2.2.0 (03-07-2026)

* [e520adc](https://github.com/abd3lraouf/PrayerTimes/commit/e520adc) fix: rewrite notification system for reliability and correct prayer order
* [c37bb9c](https://github.com/abd3lraouf/PrayerTimes/commit/c37bb9c) feat: add Makkah background image to screenshot collages

## Version: 2.1.0 (03-07-2026)

* [ef4286f](https://github.com/abd3lraouf/PrayerTimes/commit/ef4286f) feat: add Urdu and Persian language support with full RTL
* [4dd7f92](https://github.com/abd3lraouf/PrayerTimes/commit/4dd7f92) feat: redesign app icon with mosque silhouette and sparkle stars
* [8267bc2](https://github.com/abd3lraouf/PrayerTimes/commit/8267bc2) feat: add global notification settings and sunnah prayer support
* [d021aaf](https://github.com/abd3lraouf/PrayerTimes/commit/d021aaf) feat: auto-detect calculation method and localize method names
* [cdba407](https://github.com/abd3lraouf/PrayerTimes/commit/cdba407) feat: show 'no results' message when location search returns empty
* [0da6fff](https://github.com/abd3lraouf/PrayerTimes/commit/0da6fff) feat: show user-facing error message when location search fails
* [b8b065a](https://github.com/abd3lraouf/PrayerTimes/commit/b8b065a) feat: add multi-language READMEs with menu bar screenshots
* [e0aef0b](https://github.com/abd3lraouf/PrayerTimes/commit/e0aef0b) feat: add collage composition script
* [bbd00ad](https://github.com/abd3lraouf/PrayerTimes/commit/bbd00ad) feat: support language override via environment variable
* [caa8e22](https://github.com/abd3lraouf/PrayerTimes/commit/caa8e22) feat: add accessibility identifiers for screenshot automation
* [236cf70](https://github.com/abd3lraouf/PrayerTimes/commit/236cf70) feat: merge codebase-hardening branch
* [37cbef5](https://github.com/abd3lraouf/PrayerTimes/commit/37cbef5) perf: reduce timer frequency when menu bar is in icon-only mode
* [ccc714d](https://github.com/abd3lraouf/PrayerTimes/commit/ccc714d) perf: cache DateFormatter to avoid per-second allocation in countdown timer
* [57bbd1e](https://github.com/abd3lraouf/PrayerTimes/commit/57bbd1e) fix: localize all remaining hardcoded user-visible strings
* [5bd242a](https://github.com/abd3lraouf/PrayerTimes/commit/5bd242a) fix: improve RTL support and dynamic version display
* [0ea5424](https://github.com/abd3lraouf/PrayerTimes/commit/0ea5424) fix: remove wake-from-sleep observer on app termination to prevent leak
* [0920d5d](https://github.com/abd3lraouf/PrayerTimes/commit/0920d5d) fix: prevent UI tests from changing system appearance
* [0a981ce](https://github.com/abd3lraouf/PrayerTimes/commit/0a981ce) fix: flip credit card link arrows for RTL layouts
* [4391be9](https://github.com/abd3lraouf/PrayerTimes/commit/4391be9) fix: localize menu bar title for non-English languages

## Version: 2.0.1 (03-06-2026)

* [6b22fba](https://github.com/abd3lraouf/PrayerTimes/commit/6b22fba) fix: inject notificationSettings as environment object

## Version: 2.0.0 (03-06-2026)

* [544c118](https://github.com/abd3lraouf/PrayerTimes/commit/544c118) feat: complete notification system overhaul

## Version: 1.0.5 (03-06-2026)

* [bf7db60](https://github.com/abd3lraouf/PrayerTimes/commit/bf7db60) feat: complete localization overhaul for Arabic, Indonesian, and English

## Version: 1.0.4 (03-06-2026)

* [fc2e3bf](https://github.com/abd3lraouf/PrayerTimes/commit/fc2e3bf) feat: localize Menu Bar Style options (Countdown, Exact Time, Icon Only)

## Version: 1.0.3 (03-06-2026)

* [e45a7d9](https://github.com/abd3lraouf/PrayerTimes/commit/e45a7d9) feat: localize time units (h/m) for Arabic and other languages

## Version: 1.0.2 (03-06-2026)

* [8ab86a6](https://github.com/abd3lraouf/PrayerTimes/commit/8ab86a6) fix: navigation ID errors and environment object propagation
* [08b39e9](https://github.com/abd3lraouf/PrayerTimes/commit/08b39e9) fix: RTL chevron arrows for Arabic language

## Version: 1.0.1 (03-06-2026)

* [c09e83b](https://github.com/abd3lraouf/PrayerTimes/commit/c09e83b) fix: RTL text display in menu bar for Arabic language

## Version: 1.0.0 (03-06-2026)

* Initial release of PrayerTimes
