# Native Numeral System Toggle

## Problem
Arabic, Persian, and Urdu users have no control over numeral display. The app uses OS locale defaults, which always show native numerals. Some users (especially in North African Arabic-speaking countries) prefer Western numerals (0-9).

Additionally, localization strings have inconsistent numeral usage: Arabic uses Western numerals in "min before" strings, Persian uses native, Urdu uses Western.

## Decision
Native numerals default to ON for ar/fa/ur. A toggle in Display settings lets users switch to Western (0-9). Uses Approach 1: Locale Override — formatters use `Locale("en")` for numbers when native is OFF, keeping the language locale otherwise.

## Design

### Storage
- `StorageKeys.useNativeNumerals` — Bool, default `true`

### LanguageManager
- `@AppStorage` property `useNativeNumerals: Bool = true`
- `supportsNativeNumerals: Bool` — true for `["ar", "fa", "ur"]`
- `numeralLocale: Locale` — returns `Locale(identifier: language)` when native ON, `Locale(identifier: "en")` when OFF

### PrayerTimeViewModel
- `NumberFormatter.locale` → `languageManager.numeralLocale`
- `DateFormatter.locale` → `languageManager.numeralLocale`
- Invalidate cached formatters when setting changes

### SettingsView
- Conditional `StyledToggle` for "Native Numerals" after Language picker
- Only visible when `languageManager.supportsNativeNumerals`

### Localization
- Add "Native Numerals" key to all 5 .lproj files
- Fix hardcoded numerals in ar/ur Localizable.strings to use native numerals consistently

## Files Changed
1. `StorageKeys.swift`
2. `LanguageManager.swift`
3. `PrayerTimeViewModel.swift`
4. `SettingsView.swift`
5. `ar.lproj/Localizable.strings`
6. `fa.lproj/Localizable.strings`
7. `ur.lproj/Localizable.strings`
8. `en.lproj/Localizable.strings`
9. `id.lproj/Localizable.strings`
