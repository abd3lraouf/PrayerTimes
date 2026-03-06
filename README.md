<p align="center">
    <a href="https://github.com/abd3lraouf/PrayerTimes">
        <img width="128" height="128" src="assets/icon.png" style="filter: drop-shadow(0px 2px 4px rgba(80, 50, 6, 0.2));">
    </a>
    <h1 align="center"><code style="text-shadow: 0px 3px 10px rgba(8, 0, 6, 0.35); font-size: 3rem; font-family: ui-monospace, Menlo, monospace; font-weight: 800; background: transparent; color: #4d3e56; padding: 0.2rem 0.2rem; border-radius: 6px">PrayerTimes</code></h1>
    <h4 align="center" style="padding: 0; margin: 0; font-family: ui-monospace, monospace;">A minimalist prayer times app for macOS</h4>
    <h6 align="center" style="padding: 0; margin: 0; font-family: ui-monospace, monospace; font-weight: 400;">Simple, beautiful, and always in your menu bar</h6>
</p>

<p align="center">
    <a href="#installation">
        <img width=200 src="https://files.lowtechguys.com/macos-app.svg">
    </a>
</p>

---

## Prayer times at a glance

PrayerTimes lives in your **menu bar**, showing accurate prayer schedules and gentle reminders throughout your day.

It's designed to be **present when you need it** and **invisible when you don't**, helping you integrate moments of prayer into your workflow without distraction.

<p align="center">
    <img src="https://github.com/user-attachments/assets/6e8bd922-a446-4b33-a184-e5e89493a4b1" alt="PrayerTimes Screenshot" width="600">
</p>

## Features

### Accurate prayer times
* **Smart location detection** - Automatically finds your location for precise prayer times
* **Manual location** - Search any city or enter coordinates manually
* **Multiple calculation methods** - MWL, ISNA, Umm al-Qura, Kemenag, Diyanet, and more
* **Time correction** - Adjust each prayer time ±60 minutes to match your local mosque
* **Hanafi Asr** - Toggle for Hanafi madhhab Asr calculation

### Beautiful & native
* **Menu bar native** - Lives in your menu bar, saving screen space
* **SwiftUI built** - Modern, fast, and efficient with native macOS feel
* **Light & dark mode** - Adapts to your system appearance automatically
* **No dock icon** - Runs quietly in the background as a proper menu bar utility
* **Polished onboarding** - Helpful welcome guide to get started

### Deep customization
* **Flexible menu bar display**:
  - Simple moon icon
  - Countdown timer (`Asr in 24m`)
  - Exact time (`Maghrib at 6:05 PM`)
  - Compact mode (`Asr -2h 4m`)
* **Optional sunnah prayers** - Show/hide Tahajud and Dhuha times
* **Custom animations** - Fade, slide, or instant transitions
* **Native accent colors** - Uses your Mac's system accent color

### System integration
* **Native notifications** - Gentle reminders before each prayer
* **Custom sounds** - Default beep, no sound, or your own audio file
* **Launch at login** - Starts automatically and silently
* **Multi-language** - English, Arabic (العربية), and Indonesian with RTL support

## Installation

### Requirements
* **macOS Ventura (13.0)** or later
* Compatible with **Apple Silicon** (M1, M2, etc.) and **Intel-based** Macs

### Download
Download the latest release from the [Releases page](https://github.com/abd3lraouf/PrayerTimes/releases).

### First-time launch
Since this app isn't on the App Store, you'll need to give macOS permission to open it:

**Right-click** (or Control-click) the app icon in your Applications folder and select **Open**. Click **Open** in the warning dialog.

<details>
<summary><strong>Troubleshooting - Alternative methods</strong></summary>

#### Method 1: System Settings
1. Try opening the app normally (it will show a warning - click OK)
2. Open **System Settings** → **Privacy & Security**
3. Find the message about the app being blocked
4. Click **Open Anyway** and enter your password

#### Method 2: Terminal (guaranteed fix)
```bash
xattr -r -d com.apple.quarantine /Applications/PrayerTimes.app
```

</details>

## Acknowledgments

This project is a renamed version of **[Sajda](https://github.com/ikoshura/Sajda)**, originally created by **[ikoshura](https://github.com/ikoshura)**.

All credit for the original work goes to the original author. This repository maintains full attribution and respects the open-source nature of the original project.

### Third-party libraries
* [Adhan](https://github.com/batoulapps/Adhan) - Prayer time calculation library
* [FluidMenuBarExtra](https://github.com/lfroms/fluid-menu-bar-extra) - Dynamic menu bar window
* [NavigationStack](https://github.com/indieSoftware/NavigationStack) - Flexible view navigation

## License

Distributed under the MIT License. See `LICENSE` for more information.

## Contributing

Contributions are welcome! Feel free to:
* Fork the repository
* Create a pull request
* Open an issue with suggestions or bug reports

---

<p align="center">
    <i>Built with ❤️ for the Muslim community</i>
</p>
