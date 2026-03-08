# Hijri Calendar — Implementation Plan

## Step 1: Hijri Calendar Manager
Create `HijriCalendarManager.swift` — a model that wraps Apple's `Calendar(identifier:)`.

- Properties: `selectedCalendarType` (`.islamicUmmAlQura`, `.islamic`, `.islamicCivil`), `manualDayCorrection: Int` (-1, 0, +1)
- Methods:
  - `hijriDate(from: Date) -> DateComponents` — returns Hijri day/month/year with correction applied
  - `hijriDateString(from: Date) -> String` — formatted localized string (e.g., "15 Ramadan 1447")
  - `daysInMonth(month: Int, year: Int) -> Int`
  - `gregorianDate(fromHijri: DateComponents) -> Date`
  - `monthName(month: Int) -> String` — localized Hijri month name
- Store `selectedCalendarType` and `manualDayCorrection` in UserDefaults via StorageKeys

## Step 2: Islamic Events Data
Create `IslamicEvents.swift` — static data + lookup.

- Define `IslamicEvent` struct: `month: Int, day: Int, nameKey: String, descriptionKey: String`
- Static array of all events:
  - 1 Muharram: Islamic New Year
  - 10 Muharram: Ashura
  - 12 Rabi al-Awwal: Mawlid an-Nabi
  - 27 Rajab: Isra & Mi'raj
  - 15 Sha'ban: Mid-Sha'ban
  - 1 Ramadan: Start of Ramadan
  - 1 Shawwal: Eid al-Fitr
  - 9 Dhul Hijjah: Day of Arafah
  - 10 Dhul Hijjah: Eid al-Adha
  - 11-13 Dhul Hijjah: Days of Tashreeq
- Method: `events(forMonth: Int) -> [IslamicEvent]`
- Method: `events(forMonth: Int, day: Int) -> [IslamicEvent]`
- Add localized strings for all event names in all 5 languages

## Step 3: Hijri Date Display in Main Panel
Modify `MainView.swift`:

- Add Hijri date label below the location badge
- Use `HijriCalendarManager.hijriDateString(from: Date())`
- Style: secondary text color, slightly smaller font
- Show event name alongside date if today is an Islamic event

## Step 4: Monthly Calendar View
Create `HijriCalendarView.swift`:

- Navigation accessible from main panel via calendar icon button in the footer
- Month/year header with left/right arrow buttons to browse
- 7-column grid (Sat–Fri or Sun–Sat based on locale)
- Day cells: number, today highlighted with accent color, event days marked with colored dot
- Tapping a day shows events for that day below the grid
- Uses `HijriCalendarManager` for all date calculations

## Step 5: Event Detail & Notifications
- When a day with events is tapped, show event name + description below the calendar grid
- Add settings toggle: "Notify for Islamic events" (default: on)
- When enabled, schedule system notification the day before each event
- Add notification scheduling in `NotificationManager` for events

## Step 6: Settings Integration
Add to `SettingsView.swift` or a new `HijriCalendarSettingsView.swift`:

- Hijri calendar type picker (Umm al-Qura / Islamic / Civil)
- Day correction stepper (-1, 0, +1)
- Islamic event notifications toggle

## Step 7: Localization
- Add Hijri month names in all 5 languages (en, ar, id, fa, ur)
- Add Islamic event names in all 5 languages
- Ensure RTL layout works correctly for the calendar grid
