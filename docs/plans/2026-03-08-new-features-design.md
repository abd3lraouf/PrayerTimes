# PrayerTimes v2.3.0 — Feature Design

## Feature 1: Hijri Calendar

### Calendar Engine
- Use Apple's built-in `Calendar` with three variants: `.islamicUmmAlQura` (default), `.islamic`, `.islamicCivil`
- User picks their preferred variant in settings
- One-day manual correction toggle for moon sighting differences

### UI — Today's Hijri Date
- Displayed in the main prayer list panel, below the location badge
- Format: "15 Ramadan 1447 AH" (localized for all 5 languages)

### UI — Monthly Calendar View
- New section accessible from the main panel via a calendar icon button
- Grid view showing the current Hijri month with day numbers
- Arrow buttons to browse months
- Today highlighted, Islamic events marked with colored dots

### Islamic Events
- Static data mapping Hijri month+day to events
- Events: 1 Muharram (Islamic New Year), 10 Muharram (Ashura), 12 Rabi al-Awwal (Mawlid), 27 Rajab (Isra & Mi'raj), 15 Sha'ban (Mid-Sha'ban), 1 Ramadan, 1 Shawwal (Eid al-Fitr), 9 Dhul Hijjah (Day of Arafah), 10 Dhul Hijjah (Eid al-Adha), 11-13 Dhul Hijjah (Tashreeq)
- Optional notification reminders for upcoming events (configurable)
- Events displayed in a list below the calendar grid when tapping a day

---

## Feature 2: Fasting Mode (Ramadan)

### Auto-detection
- Detect Ramadan from Hijri calendar (1st–30th Ramadan)
- Auto-enable fasting mode when Ramadan starts (user confirmation notification)
- Manual toggle to enable/disable outside Ramadan

### Menu Bar & Panel Changes
- Suhoor time (= Fajr) and Iftar time (= Maghrib) prominently labeled
- Fasting day counter: "Day 15 of 30"
- Last 10 nights: subtle banner "These are the blessed last 10 nights — Laylat al-Qadr may be among them"

### Notifications
- Suhoor pre-alert: configurable (30, 45, 60 min before Fajr) — "Suhoor ends in X minutes"
- Iftar alert: at Maghrib — "It's time to break your fast"
- Dua reminders: optional at Suhoor and Iftar with Dua text
- Taraweeh reminder: configurable minutes after Isha

### Settings
- Fasting Mode toggle (auto or manual)
- Suhoor pre-alert timing
- Taraweeh reminder on/off + timing (minutes after Isha)
- Dua reminders on/off

---

## Feature 3: Menu Bar Icon Toggle

### Setting
- New toggle in Display settings: "Always show icon in menu bar"
- When ON (default): moon icon always visible alongside text
- When OFF: text only, no icon

### Behavior by Mode
- Countdown/Exact Time + icon ON: icon + text (current behavior)
- Countdown/Exact Time + icon OFF: text only
- Icon Only mode: icon always shown regardless of toggle

### Implementation
- New `StorageKeys` entry: `alwaysShowMenuBarIcon`
- Applied in `AppDelegate` where the status item icon is configured
