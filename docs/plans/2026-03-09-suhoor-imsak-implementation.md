# Suhoor/Imsak Timing Fix — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make Suhoor display as a separate time before Fajr (using Imsak offset), not at Fajr.

**Architecture:** Add a configurable Imsak offset (default 10 min) that shifts Suhoor before Fajr. Add a dedicated Suhoor row in the prayer list above Fajr. Remove the Fajr→Suhoor relabeling so Fajr stays as a normal prayer row.

**Tech Stack:** SwiftUI, Adhan library, UserDefaults/AppStorage

---

### Task 1: Add Imsak storage key and update FastingModeManager

**Files:**
- Modify: `PrayerTimes/StorageKeys.swift:37` (add new key after suhoorPreAlertMinutes)
- Modify: `PrayerTimes/FastingModeManager.swift:36-38` (update suhoorTime to use offset)

**Step 1: Add storage key**

In `PrayerTimes/StorageKeys.swift`, add after line 37 (`suhoorPreAlertMinutes`):

```swift
static let imsakOffsetMinutes = "imsakOffsetMinutes"
```

**Step 2: Update suhoorTime() to subtract Imsak offset**

In `PrayerTimes/FastingModeManager.swift`, replace the current `suhoorTime` method:

```swift
// BEFORE:
func suhoorTime(from prayerTimes: [String: Date]) -> Date? {
    prayerTimes["Fajr"]
}

// AFTER:
func suhoorTime(from prayerTimes: [String: Date]) -> Date? {
    guard let fajr = prayerTimes["Fajr"] else { return nil }
    let offsetMinutes = UserDefaults.standard.object(forKey: StorageKeys.imsakOffsetMinutes) as? Int ?? 10
    return Calendar.current.date(byAdding: .minute, value: -offsetMinutes, to: fajr)
}
```

**Step 3: Commit**

```bash
git add PrayerTimes/StorageKeys.swift PrayerTimes/FastingModeManager.swift
git commit -m "feat: add Imsak offset and shift Suhoor time before Fajr"
```

---

### Task 2: Add Imsak offset picker to settings

**Files:**
- Modify: `PrayerTimes/FastingModeSettingsView.swift:11` (add AppStorage)
- Modify: `PrayerTimes/FastingModeSettingsView.swift:49-57` (add picker after Suhoor Alert)

**Step 1: Add AppStorage property**

In `PrayerTimes/FastingModeSettingsView.swift`, add after line 11 (`suhoorPreAlertMinutes`):

```swift
@AppStorage(StorageKeys.imsakOffsetMinutes) private var imsakOffsetMinutes: Int = 10
```

**Step 2: Add Imsak offset picker in the UI**

In `PrayerTimes/FastingModeSettingsView.swift`, add a new picker before the existing "Suhoor Alert" HStack (before line 49). Insert between the "Notifications" Text and the "Suhoor Alert" HStack:

```swift
HStack {
    Text("Imsak Offset").font(.subheadline)
    Spacer()
    Picker("", selection: $imsakOffsetMinutes) {
        ForEach([5, 10, 15, 20], id: \.self) { mins in
            Text(String(format: NSLocalizedString("x_min_short", comment: ""), LanguageManager.formatNumberStatic(mins))).tag(mins)
        }
    }
}
```

**Step 3: Commit**

```bash
git add PrayerTimes/FastingModeSettingsView.swift
git commit -m "feat: add Imsak offset picker to fasting mode settings"
```

---

### Task 3: Add separate Suhoor row and restore Fajr styling in MainView

**Files:**
- Modify: `PrayerTimes/MainView.swift:154-214` (PrayerListView — add Suhoor row before Fajr)
- Modify: `PrayerTimes/MainView.swift:257-261` (PrayerRow — remove Suhoor relabeling for Fajr)

**Step 1: Remove Suhoor relabeling from Fajr in PrayerRow**

In `PrayerTimes/MainView.swift`, update the `fastingLabel` computed property (lines 257-262). Remove the Fajr→Suhoor mapping so Fajr is no longer relabeled:

```swift
// BEFORE:
private var fastingLabel: String? {
    guard fastingManager.isFastingModeEnabled, fastingManager.currentFastingDay != nil else { return nil }
    if prayerName == "Fajr" { return "Suhoor" }
    if prayerName == "Maghrib" { return "Iftar" }
    return nil
}

// AFTER:
private var fastingLabel: String? {
    guard fastingManager.isFastingModeEnabled, fastingManager.currentFastingDay != nil else { return nil }
    if prayerName == "Maghrib" { return "Iftar" }
    return nil
}
```

**Step 2: Add a dedicated Suhoor row before Fajr in PrayerListView**

In `PrayerTimes/MainView.swift`, inside the `ForEach(prayerOrder, ...)` block, add a Suhoor row before the Fajr `PrayerRow`. Insert right before the existing `PrayerRow(...)` call (line 184), inside the `if let prayerTime = vm.todayTimes[prayerName]` block:

```swift
// Add Suhoor row before Fajr when fasting mode is active
if prayerName == "Fajr" && fastingManager.isFastingModeEnabled && fastingManager.currentFastingDay != nil,
   let suhoorTime = fastingManager.suhoorTime(from: vm.todayTimes) {
    HStack(spacing: 0) {
        Text(LocalizedStringKey("Suhoor"))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(FastingColors.suhoor)
        Spacer()
        Text(vm.dateFormatter.string(from: suhoorTime))
            .font(languageManager.numberFont(size: 13, weight: .regular))
            .foregroundColor(FastingColors.suhoor)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 5)
    .background(RoundedRectangle(cornerRadius: 6).fill(FastingColors.suhoorBg))
}
```

**Step 3: Commit**

```bash
git add PrayerTimes/MainView.swift
git commit -m "feat: add separate Suhoor row before Fajr, restore Fajr normal styling"
```

---

### Task 4: Update Hijri banner to show corrected Suhoor time

**Files:**
- Modify: `PrayerTimes/MainView.swift:336` (HijriBannerView — suhoorTime already calls FastingModeManager)

**Step 1: Verify banner automatically uses updated suhoorTime()**

The `HijriBannerView` at line 336 already calls `fastingManager.suhoorTime(from: vm.todayTimes)`. Since we updated `suhoorTime()` in Task 1, the banner will automatically show the Imsak-adjusted time. **No code change needed here.**

**Step 2: Commit (skip — no change)**

---

### Task 5: Update notifications to use Imsak-adjusted Suhoor time

**Files:**
- Modify: `PrayerTimes/NotificationManager.swift:294-314` (Suhoor notifications)

**Step 1: Verify notification timing**

The notification code at line 295 already calls `fastingManager.suhoorTime(from: prayerTimes)`. Since `suhoorTime()` now returns Fajr minus Imsak offset, the pre-alert fires relative to the corrected Suhoor time. **No code change needed.**

However, the Dua notification at line 307 currently fires at the `fajr` variable — but `fajr` here is actually `fastingManager.suhoorTime(from:)`, which is now Imsak time. The Dua should fire at actual Fajr. Fix this:

```swift
// BEFORE (lines 295-314):
if let fajr = fastingManager.suhoorTime(from: prayerTimes) {
    if let preTime = Calendar.current.date(byAdding: .minute, value: -suhoorMinutes, to: fajr),
       preTime > Date() {
        scheduleSimpleNotification(
            id: "fasting_suhoor_pre",
            title: NSLocalizedString("Suhoor", comment: ""),
            body: String(format: NSLocalizedString("suhoor_ends_in_minutes", comment: ""), LanguageManager.formatNumberStatic(suhoorMinutes)),
            at: preTime
        )
    }

    // Dua at actual Fajr/Suhoor time
    if duaEnabled, fajr > Date() {
        scheduleSimpleNotification(
            id: "fasting_dua_suhoor",
            title: NSLocalizedString("Suhoor", comment: ""),
            body: NSLocalizedString("dua_beginning_fast", comment: ""),
            at: fajr
        )
    }
}

// AFTER:
if let suhoor = fastingManager.suhoorTime(from: prayerTimes) {
    if let preTime = Calendar.current.date(byAdding: .minute, value: -suhoorMinutes, to: suhoor),
       preTime > Date() {
        scheduleSimpleNotification(
            id: "fasting_suhoor_pre",
            title: NSLocalizedString("Suhoor", comment: ""),
            body: String(format: NSLocalizedString("suhoor_ends_in_minutes", comment: ""), LanguageManager.formatNumberStatic(suhoorMinutes)),
            at: preTime
        )
    }
}

// Dua at actual Fajr time (not Imsak)
if duaEnabled, let fajr = prayerTimes["Fajr"], fajr > Date() {
    scheduleSimpleNotification(
        id: "fasting_dua_suhoor",
        title: NSLocalizedString("Fajr", comment: ""),
        body: NSLocalizedString("dua_beginning_fast", comment: ""),
        at: fajr
    )
}
```

**Step 2: Commit**

```bash
git add PrayerTimes/NotificationManager.swift
git commit -m "fix: fire Suhoor alert at Imsak time, Dua at actual Fajr"
```

---

### Task 6: Update menu bar Suhoor label

**Files:**
- Modify: `PrayerTimes/PrayerTimeViewModel.swift:541-542` (menu bar label)

**Step 1: Verify menu bar label**

The menu bar code at line 541 shows "Suhoor" when `nextPrayerName == "Fajr"` and fasting mode is on. This is acceptable behavior — when counting down to Fajr during fasting, showing "Suhoor" makes sense since Suhoor ends around Fajr. **No code change needed** — the countdown target is still Fajr (the prayer time in `todayTimes`), which is correct.

**Step 2: Commit (skip — no change)**

---

### Task 7: Add localization strings for Imsak

**Files:**
- Modify: `PrayerTimes/en.lproj/Localizable.strings`
- Modify: `PrayerTimes/ar.lproj/Localizable.strings`
- Modify: `PrayerTimes/fa.lproj/Localizable.strings`
- Modify: `PrayerTimes/ur.lproj/Localizable.strings`
- Modify: `PrayerTimes/id.lproj/Localizable.strings`

**Step 1: Add Imsak Offset string to each locale**

Add after the existing "Suhoor Alert" string in each file:

**English (`en.lproj/Localizable.strings`):**
```
"Imsak Offset" = "Imsak Offset";
```

**Arabic (`ar.lproj/Localizable.strings`):**
```
"Imsak Offset" = "فارق الإمساك";
```

**Farsi (`fa.lproj/Localizable.strings`):**
```
"Imsak Offset" = "فاصله امساک";
```

**Urdu (`ur.lproj/Localizable.strings`):**
```
"Imsak Offset" = "امساک آفسیٹ";
```

**Indonesian (`id.lproj/Localizable.strings`):**
```
"Imsak Offset" = "Selisih Imsak";
```

**Step 2: Commit**

```bash
git add PrayerTimes/en.lproj/Localizable.strings PrayerTimes/ar.lproj/Localizable.strings PrayerTimes/fa.lproj/Localizable.strings PrayerTimes/ur.lproj/Localizable.strings PrayerTimes/id.lproj/Localizable.strings
git commit -m "feat: add Imsak Offset localization strings"
```

---

### Task 8: Build and verify

**Step 1: Build the project**

```bash
cd /Users/abd3lraouf/Developer/PrayerTimes && xcodebuild -scheme PrayerTimes -configuration Debug build 2>&1 | tail -20
```

Expected: BUILD SUCCEEDED

**Step 2: Fix any build errors if needed**

**Step 3: Final commit if fixes were needed**
