# Native Numeral System Toggle — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Let Arabic, Persian, and Urdu users toggle between native numerals and Western (0-9) numerals, defaulting to native.

**Architecture:** Add a `useNativeNumerals` boolean to `LanguageManager` backed by `@AppStorage`. A computed `numeralLocale` property returns the language locale (native) or `"en"` (Western). All formatters use this locale. A conditional toggle in SettingsView controls the preference.

**Tech Stack:** Swift, SwiftUI, AppStorage, NumberFormatter, DateFormatter

---

### Task 1: Add Storage Key

**Files:**
- Modify: `PrayerTimes/StorageKeys.swift:29` (add after `launchAtLogin`)

**Step 1: Add the key**

In `StorageKeys.swift`, add after line 29 (`launchAtLogin`):

```swift
static let useNativeNumerals = "useNativeNumerals"
```

**Step 2: Commit**

```bash
git add PrayerTimes/StorageKeys.swift
git commit -m "feat: add useNativeNumerals storage key"
```

---

### Task 2: Add Tests for LanguageManager Numeral Support

**Files:**
- Modify: `PrayerTimesTests/PrayerTimesTests.swift` (add after line ~626, after existing LanguageManager tests)

**Step 1: Write failing tests**

Add these test methods inside the existing test class, after `testLanguageManagerLTRForIndonesian()`:

```swift
// MARK: - Native Numerals Support Tests

func testSupportsNativeNumeralsForArabic() {
    let manager = LanguageManager()
    manager.language = "ar"
    XCTAssertTrue(manager.supportsNativeNumerals)
}

func testSupportsNativeNumeralsForPersian() {
    let manager = LanguageManager()
    manager.language = "fa"
    XCTAssertTrue(manager.supportsNativeNumerals)
}

func testSupportsNativeNumeralsForUrdu() {
    let manager = LanguageManager()
    manager.language = "ur"
    XCTAssertTrue(manager.supportsNativeNumerals)
}

func testDoesNotSupportNativeNumeralsForEnglish() {
    let manager = LanguageManager()
    manager.language = "en"
    XCTAssertFalse(manager.supportsNativeNumerals)
}

func testDoesNotSupportNativeNumeralsForIndonesian() {
    let manager = LanguageManager()
    manager.language = "id"
    XCTAssertFalse(manager.supportsNativeNumerals)
}

func testNumeralLocaleReturnsLanguageLocaleWhenNativeOn() {
    let manager = LanguageManager()
    manager.language = "ar"
    manager.useNativeNumerals = true
    XCTAssertEqual(manager.numeralLocale.identifier, "ar")
}

func testNumeralLocaleReturnsEnglishLocaleWhenNativeOff() {
    let manager = LanguageManager()
    manager.language = "ar"
    manager.useNativeNumerals = false
    XCTAssertEqual(manager.numeralLocale.identifier, "en")
}

func testNumeralLocaleAlwaysReturnsLanguageForEnglish() {
    let manager = LanguageManager()
    manager.language = "en"
    manager.useNativeNumerals = false
    XCTAssertEqual(manager.numeralLocale.identifier, "en")
}

func testNumeralLocaleAlwaysReturnsLanguageForIndonesian() {
    let manager = LanguageManager()
    manager.language = "id"
    manager.useNativeNumerals = true
    XCTAssertEqual(manager.numeralLocale.identifier, "id")
}
```

**Step 2: Run tests to verify they fail**

Run: `xcodebuild test -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' 2>&1 | tail -30`
Expected: FAIL — `supportsNativeNumerals`, `numeralLocale`, and `useNativeNumerals` do not exist on LanguageManager.

**Step 3: Commit failing tests**

```bash
git add PrayerTimesTests/PrayerTimesTests.swift
git commit -m "test: add failing tests for native numerals support in LanguageManager"
```

---

### Task 3: Implement LanguageManager Numeral Properties

**Files:**
- Modify: `PrayerTimes/LanguageManager.swift`

**Step 1: Add properties to LanguageManager**

In `LanguageManager.swift`, add after the `language` property (after line 11):

```swift
@AppStorage(StorageKeys.useNativeNumerals) var useNativeNumerals: Bool = true {
    didSet {
        objectWillChange.send()
    }
}

static let nativeNumeralLanguages = ["ar", "fa", "ur"]

var supportsNativeNumerals: Bool {
    return Self.nativeNumeralLanguages.contains(language)
}

var numeralLocale: Locale {
    if supportsNativeNumerals && !useNativeNumerals {
        return Locale(identifier: "en")
    }
    return Locale(identifier: language)
}
```

**Step 2: Run tests to verify they pass**

Run: `xcodebuild test -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' 2>&1 | tail -30`
Expected: All native numeral tests PASS.

**Step 3: Commit**

```bash
git add PrayerTimes/LanguageManager.swift
git commit -m "feat: add native numeral toggle properties to LanguageManager"
```

---

### Task 4: Wire Formatters to Use numeralLocale

**Files:**
- Modify: `PrayerTimes/PrayerTimeViewModel.swift`

**Step 1: Update NumberFormatter locale (line ~451)**

Change the `NumberFormatter` creation block from:

```swift
nf.locale = Locale(identifier: currentLang)
```

to:

```swift
nf.locale = languageManager.numeralLocale
```

Also update the cache check on line ~449 from:

```swift
if _cachedNumberFormatter == nil || _cachedNumberFormatter?.locale.identifier != currentLang {
```

to:

```swift
if _cachedNumberFormatter == nil || _cachedNumberFormatter?.locale.identifier != languageManager.numeralLocale.identifier {
```

**Step 2: Update DateFormatter locale (line ~565)**

Change from:

```swift
formatter.locale = Locale(identifier: languageManager.language)
```

to:

```swift
formatter.locale = languageManager.numeralLocale
```

**Step 3: Invalidate formatters when setting changes**

Find where `languageManager` changes trigger formatter invalidation. Look for `objectWillChange` subscribers or `language` change handlers. The ViewModel already observes `UserDefaults.didChangeNotification` in AppDelegate (line 28-30), which triggers `updateAndDisplayTimes()`.

We need to ensure cached formatters are invalidated. In the ViewModel, add an observer for the `useNativeNumerals` key. Find the `init()` method and add after the existing setup:

```swift
UserDefaults.standard.addObserver(self, forKeyPath: StorageKeys.useNativeNumerals, options: .new, context: nil)
```

And add this method to the class:

```swift
override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
    if keyPath == StorageKeys.useNativeNumerals {
        _cachedNumberFormatter = nil
        _cachedDateFormatter = nil
        updateAndDisplayTimes()
    } else {
        super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }
}
```

**NOTE:** Check if there is already a KVO observer or a Combine subscriber for UserDefaults changes in the ViewModel. If the existing `UserDefaults.didChangeNotification` in AppDelegate already triggers `updateAndDisplayTimes()`, then we just need to make sure the cached formatters get invalidated. In that case, the simpler approach is: in the `updateCountdown()` method, always compare the formatter locale to `languageManager.numeralLocale` (which we're already doing in Step 1's cache check), so stale formatters get recreated automatically. The `dateFormatter` computed property similarly compares cached state. If `_cachedDateFormatter` is invalidated on any UserDefaults change already, we may not need the KVO.

Review the existing code paths and pick the simplest approach that ensures both formatters get recreated when `useNativeNumerals` changes.

**Step 4: Verify build compiles**

Run: `xcodebuild build -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

**Step 5: Run all tests**

Run: `xcodebuild test -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' 2>&1 | tail -30`
Expected: All tests PASS.

**Step 6: Commit**

```bash
git add PrayerTimes/PrayerTimeViewModel.swift
git commit -m "feat: wire formatters to use numeralLocale for native numeral toggle"
```

---

### Task 5: Add Settings UI Toggle

**Files:**
- Modify: `PrayerTimes/SettingsView.swift`

**Step 1: Add the native numerals toggle**

In `SettingsView.swift`, after the Language picker line (line 44), add:

```swift
if languageManager.supportsNativeNumerals {
    StyledToggle(label: "Native Numerals", isOn: $languageManager.useNativeNumerals)
}
```

**Step 2: Verify build compiles**

Run: `xcodebuild build -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add PrayerTimes/SettingsView.swift
git commit -m "feat: add native numerals toggle to display settings"
```

---

### Task 6: Add Localization Strings

**Files:**
- Modify: `PrayerTimes/en.lproj/Localizable.strings`
- Modify: `PrayerTimes/ar.lproj/Localizable.strings`
- Modify: `PrayerTimes/fa.lproj/Localizable.strings`
- Modify: `PrayerTimes/ur.lproj/Localizable.strings`
- Modify: `PrayerTimes/id.lproj/Localizable.strings`

**Step 1: Add "Native Numerals" to all locales**

Add in the Display Settings section of each file:

**en.lproj:**
```
"Native Numerals" = "Native Numerals";
```

**ar.lproj:**
```
"Native Numerals" = "الأرقام العربية";
```

**fa.lproj:**
```
"Native Numerals" = "اعداد فارسی";
```

**ur.lproj:**
```
"Native Numerals" = "مقامی ہندسے";
```

**id.lproj:**
```
"Native Numerals" = "Angka Asli";
```

**Step 2: Fix inconsistent numerals in Arabic strings**

In `ar.lproj/Localizable.strings`, update the "min before" strings to use native Eastern Arabic numerals:

```
"1 min before" = "قبل دقيقة واحدة";
"5 min before" = "قبل ٥ دقائق";
"10 min before" = "قبل ١٠ دقائق";
"20 min before" = "قبل ٢٠ دقيقة";
"25 min before" = "قبل ٢٥ دقيقة";
"30 min before" = "قبل ٣٠ دقيقة";
```

Also fix the calculation method strings that have mixed numerals:
```
"calc_method_France (12°)" = "فرنسا (١٢°)";
"calc_method_France (18°)" = "فرنسا (١٨°)";
```

(These already use native numerals — verify they're correct.)

**Step 3: Fix Urdu strings to use native Extended Arabic-Indic numerals**

In `ur.lproj/Localizable.strings`, update:

```
"24-Hour Time" = "۲۴ گھنٹے وقت";
"1 min before" = "۱ منٹ پہلے";
"5 min before" = "۵ منٹ پہلے";
"10 min before" = "۱۰ منٹ پہلے";
"20 min before" = "۲۰ منٹ پہلے";
"25 min before" = "۲۵ منٹ پہلے";
"30 min before" = "۳۰ منٹ پہلے";
```

**Step 4: Commit**

```bash
git add PrayerTimes/en.lproj/Localizable.strings PrayerTimes/ar.lproj/Localizable.strings PrayerTimes/fa.lproj/Localizable.strings PrayerTimes/ur.lproj/Localizable.strings PrayerTimes/id.lproj/Localizable.strings
git commit -m "feat: add native numerals localization and fix inconsistent numeral strings"
```

---

### Task 7: Final Verification

**Step 1: Run full test suite**

Run: `xcodebuild test -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' 2>&1 | tail -40`
Expected: All tests PASS.

**Step 2: Build release**

Run: `xcodebuild build -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' -configuration Release 2>&1 | tail -20`
Expected: BUILD SUCCEEDED

**Step 3: Manual smoke test checklist**
- [ ] Switch to Arabic → numbers show ٠١٢٣٤٥٦٧٨٩
- [ ] Toggle "Native Numerals" OFF → numbers show 0-9
- [ ] Switch to Persian → numbers show ۰۱۲۳۴۵۶۷۸۹
- [ ] Switch to English → toggle disappears
- [ ] Switch to Indonesian → toggle disappears
- [ ] Switch back to Arabic → toggle reappears with last saved state
