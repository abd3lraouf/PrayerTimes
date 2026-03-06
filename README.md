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

### Step 1: Download

Download the latest DMG from the [Releases page](https://github.com/abd3lraouf/PrayerTimes/releases).

### Step 2: Install the App

1. **Open the DMG file** by double-clicking it
2. **Drag PrayerTimes** to the Applications folder shortcut
3. **Eject the DMG** (right-click on desktop icon → Eject)

### Step 3: Bypass macOS Security (Important!)

Since PrayerTimes is distributed outside the App Store, macOS will flag it as "unverified" or "from an unidentified developer." This is **normal and safe** for open-source apps. Here's how to bypass it:

#### Method 1: Right-Click Open (Easiest - Recommended)

This is the simplest method that works for most users:

1. Go to your **Applications** folder
2. **Right-click** (or Control-click) on PrayerTimes
3. Select **Open** from the context menu
4. A dialog will appear saying "macOS cannot verify the developer"
5. Click **Open** in the dialog
6. Click **Open** again to confirm

✅ **Done!** macOS will remember this choice and the app will open normally from now on.

---

<details>
<summary><strong>📖 Why do I see this warning?</strong></summary>

macOS requires apps to be **notarized** by Apple (a paid service) to avoid security warnings. Since PrayerTimes is:
- ✅ Open-source and free
- ✅ Code is auditable on GitHub
- ✅ Built by the community, not a company

We distribute it without notarization to keep it free. The app is **completely safe** - you can verify this by:
1. Reviewing the [source code](https://github.com/abd3lraouf/PrayerTimes)
2. Reading the [security audit report](SECURITY_AUDIT.md)
3. Building it yourself from source

</details>

---

<details>
<summary><strong>🔧 Method 2: System Settings (If Method 1 doesn't work)</strong></summary>

If you accidentally clicked **Cancel** or the right-click method didn't work:

1. Try to **double-click** PrayerTimes in Applications (a warning will appear, click **OK**)
2. Open **System Settings** (or System Preferences on older macOS)
3. Go to **Privacy & Security**
4. Scroll down to find: *"PrayerTimes was blocked from use because it is not from an identified developer"*
5. Click **Open Anyway**
6. Enter your password if prompted
7. Click **Open** to confirm

✅ **Done!** The app is now trusted.

</details>

---

<details>
<summary><strong>⚙️ Method 3: Terminal Command (Guaranteed Fix)</strong></summary>

If the other methods don't work, use this terminal command to remove the quarantine flag:

1. Open **Terminal** (Applications → Utilities → Terminal)
2. Copy and paste this command:

```bash
xattr -r -d com.apple.quarantine /Applications/PrayerTimes.app
```

3. Press **Enter**
4. Enter your password if prompted (password won't show as you type)

✅ **Done!** The app will now open without any warnings.

**What this does:**
- Removes the `com.apple.quarantine` attribute that macOS puts on downloaded files
- This is completely safe and doesn't affect your system
- It's the same as approving the app through the GUI methods

</details>

---

<details>
<summary><strong>🛡️ Verify the App is Safe</strong></summary>

You can verify the app's safety by checking its signature and entitlements:

**Check if the app is sandboxed:**
```bash
codesign -d --entitlements :- /Applications/PrayerTimes.app
```

You should see `com.apple.security.app-sandbox` which confirms the app is properly sandboxed and can't access your system.

**Check the DMG checksum:**
```bash
# Download the checksum file from the release
# Then verify:
shasum -a 256 -c PrayerTimes-1.0.0.dmg.sha256
```

</details>

---

<details>
<summary><strong>🔨 Build from Source (Most Secure)</strong></summary>

For maximum security, build the app yourself:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/abd3lraouf/PrayerTimes.git
   cd PrayerTimes
   ```

2. **Open in Xcode:**
   ```bash
   open PrayerTimes.xcodeproj
   ```

3. **Build and run:**
   - Select your Mac as the destination
   - Press `Cmd + R` to build and run
   - The app will be in your derived data folder

**Benefits:**
- ✅ No security warnings (you built it yourself)
- ✅ You can review all code before building
- ✅ You can modify the app to your needs

</details>

---

## Verifying the Download

Each release includes a SHA256 checksum file. To verify your download:

```bash
# After downloading both the .dmg and .dmg.sha256 files
cd ~/Downloads
shasum -a 256 -c PrayerTimes-1.0.0.dmg.sha256
```

Expected output: `PrayerTimes-1.0.0.dmg: OK`

## Security & Privacy

PrayerTimes is built with security and privacy in mind:

- ✅ **Fully open-source** - All code is auditable on GitHub
- ✅ **Properly sandboxed** - Limited system access per Apple's guidelines
- ✅ **No data collection** - Zero tracking, analytics, or telemetry
- ✅ **No network calls** - Except for optional location search (OpenStreetMap)
- ✅ **Local storage only** - All preferences stored locally in UserDefaults
- ✅ **Security audited** - Comprehensive security audit available

Read the full [Security Audit Report](SECURITY_AUDIT.md) for details.

## Acknowledgments

This project is a renamed version of **[Sajda](https://github.com/ikoshura/Sajda)**, originally created by **[ikoshura](https://github.com/ikoshura)**.

All credit for the original work goes to the original author. This repository maintains full attribution and respects the open-source nature of the original project.

### Third-party libraries
* [Adhan](https://github.com/batoulapps/Adhan) - Prayer time calculation library
* [FluidMenuBarExtra](https://github.com/lfroms/fluid-menu-bar-extra) - Dynamic menu bar window
* [NavigationStack](https://github.com/indieSoftware/NavigationStack) - Flexible view navigation

## Troubleshooting

### App won't open?
Make sure you've followed **Step 3** above to bypass macOS security. Try Method 3 (Terminal command) for a guaranteed fix.

### Location not working?
1. Go to System Settings → Privacy & Security → Location Services
2. Ensure PrayerTimes is enabled
3. Restart the app

### Notifications not working?
1. Go to System Settings → Notifications
2. Find PrayerTimes and enable notifications
3. Check the app's notification settings

## Contributing

Contributions are welcome! Feel free to:
* Fork the repository
* Create a pull request
* Open an issue with suggestions or bug reports

## License

Distributed under the MIT License. See `LICENSE` for more information.

---

<p align="center">
    <i>Built with ❤️ for the Muslim community</i>
</p>
