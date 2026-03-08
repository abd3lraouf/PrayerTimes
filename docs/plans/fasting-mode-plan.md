# Fasting Mode (Ramadan) — Implementation Plan

**Prerequisite:** This feature depends on `HijriCalendarManager` from the Hijri Calendar feature. If building independently, create a minimal `HijriCalendarManager` that can detect Ramadan (1st–30th of month 9).

## Step 1: Fasting Mode Manager
Create `FastingModeManager.swift`:

- Properties:
  - `isFastingModeEnabled: Bool` (published, stored in UserDefaults)
  - `isAutoDetectEnabled: Bool` (stored in UserDefaults, default: true)
  - `currentFastingDay: Int?` — day number within Ramadan (1–30), nil if not Ramadan
  - `totalFastingDays: Int` — days in current Ramadan month
  - `isLastTenNights: Bool` — true if day >= 21
- Methods:
  - `checkAndAutoEnable()` — called daily, enables fasting mode if Ramadan detected and auto-detect is on
  - `suhoorTime(from prayerTimes: [String: Date]) -> Date?` — returns Fajr time
  - `iftarTime(from prayerTimes: [String: Date]) -> Date?` — returns Maghrib time
  - `taraweehTime(from prayerTimes: [String: Date], minutesAfterIsha: Int) -> Date?`

## Step 2: Fasting Mode UI in Main Panel
Modify `MainView.swift`:

- When fasting mode is active, show a fasting banner above the prayer list:
  - "Day 15 of 30 — Ramadan"
  - Suhoor and Iftar times prominently displayed with labels
- Last 10 nights banner (days 21–30):
  - Subtle styled text: "These are the blessed last 10 nights — Laylat al-Qadr may be among them"
- Taraweeh time shown below Isha if enabled

## Step 3: Fasting Mode Notifications
Extend `NotificationManager.swift`:

- **Suhoor pre-alert**: schedule notification X minutes before Fajr
  - Title: "Suhoor" (localized)
  - Body: "Suhoor ends in X minutes" (localized)
  - Configurable: 30, 45, 60 minutes before
- **Iftar alert**: at Maghrib time
  - Title: "Iftar" (localized)
  - Body: "It's time to break your fast" (localized)
- **Dua reminders** (optional):
  - At Suhoor: Dua for beginning fast
  - At Iftar: Dua for breaking fast
  - Body contains the Dua text (Arabic + transliteration)
- **Taraweeh reminder** (optional):
  - Configurable minutes after Isha (default: 30)
  - Title: "Taraweeh" (localized)
- All fasting notifications only active when fasting mode is enabled
- Re-schedule daily alongside prayer time notifications

## Step 4: Menu Bar Changes
Modify `PrayerTimeViewModel.swift`:

- When fasting mode is active and next prayer is Fajr or Maghrib:
  - Show "Suhoor in X" or "Iftar in X" instead of "Fajr in X" / "Maghrib in X"
- Add fasting day counter option to menu bar display

## Step 5: Fasting Mode Settings
Create `FastingModeSettingsView.swift`:

- Fasting Mode toggle (on/off)
- Auto-detect Ramadan toggle
- Suhoor pre-alert timing picker (30, 45, 60 min)
- Iftar notification toggle
- Dua reminders toggle
- Taraweeh reminder toggle + minutes after Isha picker
- Accessible from main Settings view

## Step 6: Localization
- Add all fasting-related strings in 5 languages:
  - "Suhoor", "Iftar", "Taraweeh", "Day X of Y"
  - Last 10 nights message
  - Dua texts (Arabic script for all languages, transliteration for non-Arabic)
  - Notification bodies
- Ensure RTL layout for fasting banner
