# Menu Bar Icon Toggle — Implementation Plan

## Step 1: Add StorageKey
In `StorageKeys.swift`:

- Add `static let alwaysShowMenuBarIcon = "alwaysShowMenuBarIcon"`

## Step 2: Add Setting to ViewModel
In `PrayerTimeViewModel.swift`:

- Add `@AppStorage(StorageKeys.alwaysShowMenuBarIcon) var alwaysShowMenuBarIcon: Bool = true`
- In the `didSet`, trigger icon update

## Step 3: Update Icon Logic in AppDelegate
In `AppDelegate.swift`:

- Find `updateIconForMode()` or equivalent method that sets the status item icon
- When `alwaysShowMenuBarIcon` is false AND mode is not `.hidden` (Icon Only):
  - Set `statusItem.button?.image = nil`
- When `alwaysShowMenuBarIcon` is true OR mode is `.hidden`:
  - Set the moon icon as usual
- Subscribe to the `alwaysShowMenuBarIcon` changes to trigger icon update

## Step 4: Add Toggle in Settings UI
In `SettingsView.swift` Display section:

- Add toggle: "Always show icon in menu bar"
- Place it near the "Menu Bar Style" picker
- Disable the toggle when Menu Bar Style is "Icon Only" (since icon must show)

## Step 5: Localization
- Add "Always show icon in menu bar" string in all 5 languages
