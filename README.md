<p align="center">
    <strong>English</strong> | <a href="README.ar.md">العربية</a> | <a href="README.id.md">Indonesia</a> | <a href="README.fa.md">فارسی</a> | <a href="README.ur.md">اردو</a>
</p>

<p align="center">
    <img src="art/en/logo.png" alt="PrayerTimes Pro" height="80">
</p>

<p align="center">A simple prayer times app that lives in your Mac's menu bar.</p>

<p align="center">
    <a href="#installation">
        <img width=200 src="https://files.lowtechguys.com/macos-app.svg">
    </a>
</p>

---

<p align="center">
    <img src="art/en/screenshots.png" alt="PrayerTimes Pro Screenshots" width="700">
</p>

## What it does

- Shows prayer times in your menu bar with countdown or exact time
- Sends notifications before each prayer
- Detects your location automatically (or set it manually)
- Supports multiple calculation methods (MWL, ISNA, Umm al-Qura, Kemenag, Diyanet, and more)
- Lets you adjust each prayer time to match your local mosque
- Works in English, Arabic, Indonesian, Persian, and Urdu
- Follows your system's light/dark mode

## Menu bar styles

Choose how prayer times appear in your menu bar:

- **Countdown** - `Asr in 24m`
- **Exact time** - `Maghrib at 6:05 PM`
- **Compact** - `Asr -2h 4m`
- **Icon only** - Just a moon icon

## Installation

**Requires macOS Ventura (13.0) or later.** Works on both Apple Silicon and Intel Macs.

### Homebrew

```bash
brew tap abd3lraouf/prayertimes
brew install --cask prayertimes
```

### Manual

1. Download the latest `.dmg` from [Releases](https://github.com/abd3lraouf/PrayerTimes/releases)
2. Open the DMG and drag **PrayerTimes** to **Applications**
3. Right-click the app in Applications and select **Open** (needed the first time since the app isn't notarized)

<details>
<summary>Still getting a security warning?</summary>

**Option A:** Go to System Settings > Privacy & Security, scroll down, and click "Open Anyway."

**Option B:** Run this in Terminal:
```bash
xattr -r -d com.apple.quarantine /Applications/PrayerTimes.app
```

The app is open-source and safe to use. macOS shows this warning for any app downloaded outside the App Store that hasn't paid for Apple's notarization service.

</details>

<details>
<summary>Build from source</summary>

```bash
git clone https://github.com/abd3lraouf/PrayerTimes.git
cd PrayerTimes
open PrayerTimes.xcodeproj
```

Then press Cmd+R in Xcode to build and run.

</details>

## Privacy

- No tracking, analytics, or data collection
- All settings stored locally on your Mac
- Network is only used for location search (OpenStreetMap)
- Fully open-source - read every line of code yourself

## Troubleshooting

**App won't open?** Follow the security steps above. The Terminal command is the guaranteed fix.

**Location not working?** Enable location access in System Settings > Privacy & Security > Location Services.

**No notifications?** Check System Settings > Notifications and make sure PrayerTimes is enabled.

## Credits

Based on [Sajda](https://github.com/ikoshura/Sajda) by [ikoshura](https://github.com/ikoshura).

Uses [Adhan](https://github.com/batoulapps/Adhan) for prayer time calculations, [FluidMenuBarExtra](https://github.com/lfroms/fluid-menu-bar-extra) for the menu bar window, and [NavigationStack](https://github.com/indieSoftware/NavigationStack) for view navigation.

## Contributing

Contributions welcome! Fork the repo, open a PR, or file an issue.

## License

MIT License. See `LICENSE` for details.

---

<p align="center">
    <img width="64" height="64" src="assets/logo.svg">
</p>
