# Suhoor/Imsak Timing Fix

## Problem

Suhoor is displayed at Fajr time, but eating must stop before Fajr. The app needs to show Suhoor as a distinct, earlier time using the Imsak concept (a precautionary buffer before Fajr).

## Industry Standard

- Imsak = Fajr minus 10-15 minutes (10 min most common)
- Muslim Pro, IslamicFinder, Umm Al-Qura all use this approach
- Imsak serves as a safety margin across different calculation methods

## Solution

### 1. Suhoor Time = Fajr - configurable offset (default 10 min)

- `FastingModeManager.suhoorTime()` returns `Fajr - imsakOffset`
- New `StorageKeys.imsakOffsetMinutes` with default value of 10

### 2. Separate Suhoor row above Fajr in prayer list

- Visible only when fasting mode is active (auto or manual)
- Uses existing `FastingColors.suhoor` and `FastingColors.suhoorBg`
- Fajr row returns to normal prayer styling (no longer relabeled as Suhoor)

### 3. Settings: Imsak offset picker

- New "Imsak Offset" picker in FastingModeSettingsView: 5, 10, 15, 20 minutes
- Existing "Suhoor Alert" (pre-notification) remains separate

### 4. Updated notifications

- Suhoor pre-alert fires relative to Suhoor/Imsak time (not Fajr)
- Dua reminder stays at Fajr (the actual start of the fast)

### 5. Hijri banner

- Shows corrected Suhoor time (Fajr - offset)

### 6. Menu bar countdown

- When next event is Suhoor, shows "Suhoor" with the Imsak time

## Files to modify

- `FastingModeManager.swift` — update `suhoorTime()` to accept offset
- `StorageKeys.swift` — add `imsakOffsetMinutes`
- `MainView.swift` — add Suhoor row above Fajr, restore Fajr normal styling
- `FastingModeSettingsView.swift` — add Imsak offset picker
- `NotificationManager.swift` — adjust Suhoor notification timing
- `PrayerTimeViewModel.swift` — menu bar Suhoor countdown
- Localization files — add Imsak-related strings if needed
