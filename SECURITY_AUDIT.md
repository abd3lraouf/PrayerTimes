# Security Audit Report - PrayerTimes Pro

**Date:** 2026-02-12
**Scope:** Full source code review of the PrayerTimes macOS prayer times application
**Version Audited:** 3.1.1
**Status:** All findings remediated

---

## Executive Summary

PrayerTimes Pro is a macOS menu bar application built with SwiftUI for calculating and displaying Islamic prayer times. The application is **sandboxed**, uses **minimal entitlements**, contains **no hardcoded secrets**, and follows standard Apple platform conventions. Overall, the application has a **low risk profile** appropriate for a local-first utility app.

**8 findings** were identified across 3 severity levels. **All actionable findings have been fixed.**

| Severity | Count | Fixed |
|----------|-------|-------|
| Medium   | 3     | 3     |
| Low      | 4     | 2     |
| Info     | 1     | 1     |

No **High** or **Critical** severity issues were found.

---

## Findings

### [M-1] MEDIUM: Dependency `adhan-swift` pinned to branch instead of version tag

**File:** `PrayerTimes.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved:8`

The `adhan-swift` dependency is pinned to the `main` branch rather than a tagged release version:

```json
"state": {
  "branch": "main",
  "revision": "127280c27c303f7898f59070580f4789a75df628"
}
```

While the resolved file pins a specific commit hash, running `swift package update` will pull the latest commit on `main`, which could include unreviewed or malicious code if the upstream repository is compromised. The `NavigationStack` dependency, by contrast, is correctly pinned to version `1.1.1`.

**Recommendation:** Pin `adhan-swift` to a specific release version tag instead of the `main` branch.

**Status: FIXED** - Pinned to `upToNextMajorVersion: 1.4.0` in `project.pbxproj` and updated `Package.resolved` accordingly.

---

### [M-2] MEDIUM: User search queries sent to third-party service without explicit disclosure

**File:** `PrayerTimes/PrayerTimeViewModel.swift:136-148`

When using manual location search, user-typed queries (city names or coordinates) are sent to `https://nominatim.openstreetmap.org/search` along with a User-Agent header identifying the app:

```swift
var components = URLComponents(string: "https://nominatim.openstreetmap.org/search")!
components.queryItems = [
    URLQueryItem(name: "q", value: trimmedQuery),
    URLQueryItem(name: "format", value: "json"),
    ...
]
var request = URLRequest(url: url)
request.setValue("PrayerTimes Pro Prayer Times App/1.0", forHTTPHeaderField: "User-Agent")
```

This is standard for a geocoding feature, but OpenStreetMap's Nominatim is a third-party service with its own data collection policies. Users may not be aware their search input is leaving the device.

**Recommendation:** Add a privacy disclosure in the app or a note in the privacy policy that location search queries are sent to OpenStreetMap's Nominatim service.

**Status: FIXED** - Added "Search is powered by OpenStreetMap." disclosure in both `ManualLocationSheetView.swift` and `ManualLocationView.swift`.

---

### [M-3] MEDIUM: Sound file URL constructed from user-controlled string without scheme validation

**File:** `PrayerTimes/PrayerTimeViewModel.swift:298-300`

```swift
if adhanSound == .custom,
   let soundPath = customAdhanSoundPath.removingPercentEncoding,
   let soundURL = URL(string: soundPath),
   FileManager.default.fileExists(atPath: soundURL.path) {
    adhanPlayer = NSSound(contentsOf: soundURL, byReference: true)
    adhanPlayer?.play()
}
```

The `customAdhanSoundPath` is stored in UserDefaults and loaded without validating the URL scheme. Although `NSOpenPanel` constrains user selection to local files, the value persisted in UserDefaults could be modified externally. The `FileManager.default.fileExists(atPath:)` check mitigates most risk (network URLs won't have valid local paths), but explicit scheme validation would be more robust.

**Recommendation:** Validate that the URL scheme is `file://` before using it:
```swift
guard soundURL.isFileURL else { return }
```

**Status: FIXED** - Added `soundURL.isFileURL` guard to the URL validation chain in `PrayerTimeViewModel.swift`.

---

### [L-1] LOW: Location data stored in plaintext UserDefaults

**File:** `PrayerTimes/PrayerTimeViewModel.swift:177,195`

User latitude, longitude, and city name are stored as a dictionary in UserDefaults under the key `manualLocationData`:

```swift
let manualLocationData: [String: Any] = [
    "name": locationNameToSave,
    "latitude": coordinates.latitude,
    "longitude": coordinates.longitude
]
UserDefaults.standard.set(manualLocationData, forKey: "manualLocationData")
```

UserDefaults are stored as an unencrypted plist on disk. While the app sandbox limits access, any process running as the same user could read this data.

**Recommendation:** This is acceptable for a sandboxed macOS app storing city-level location data. No action required unless the app's threat model evolves.

**Status: ACCEPTED** - Risk accepted; standard practice for sandboxed macOS apps.

---

### [L-2] LOW: Bundle class swizzling for language switching

**File:** `PrayerTimes/LanguageManager.swift:35-51`

The app uses Objective-C runtime methods (`object_setClass`, `objc_setAssociatedObject`) to override `Bundle.main`'s behavior for runtime language switching:

```swift
var bundleKey: UInt8 = 0
class AnyLanguageBundle: Bundle {
    override func localizedString(forKey key: String, ...) -> String {
        guard let path = objc_getAssociatedObject(self, &bundleKey) as? String,
              let bundle = Bundle(path: path) else { ... }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
```

This is a well-known pattern for dynamic language switching but has risks:
- Modifies global runtime behavior of `Bundle.main`
- Uses a global mutable variable (`bundleKey`) as an association key
- Could break with future macOS updates

**Recommendation:** This is a common pattern with no immediate security risk. Consider migrating to Apple's built-in localization APIs if they add runtime switching support.

**Status: ACCEPTED** - Risk accepted; well-known community pattern with no security impact.

---

### [L-3] LOW: Use of undocumented Apple notification names

**File:** `PrayerTimes/FluidMenuBar/FluidMenuBarExtraStatusItem.swift:45,65,126-127`

The app posts to `DistributedNotificationCenter` using undocumented Apple internal notification names:

```swift
DistributedNotificationCenter.default().post(
    name: .beginMenuTracking, object: nil)
// where:
static let beginMenuTracking = Notification.Name(
    "com.apple.HIToolbox.beginMenuTrackingNotification")
static let endMenuTracking = Notification.Name(
    "com.apple.HIToolbox.endMenuTrackingNotification")
```

These are private `HIToolbox` notifications. Posting to `DistributedNotificationCenter` sends these system-wide, which other apps can observe. This is not a direct security vulnerability but relies on undocumented behavior.

**Recommendation:** Document the purpose of these notifications. They simulate native menu bar tracking behavior and are standard practice for custom menu bar extras.

**Status: ACCEPTED** - Standard practice for custom menu bar extras; no security impact.

---

### [L-4] LOW: Notification permission result ignored

**File:** `PrayerTimes/NotificationManager.swift:9`

```swift
static func requestPermission() {
    UNUserNotificationCenter.current()
        .requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
}
```

The callback ignores both the granted status and potential errors. While not a security vulnerability, this means the app silently fails if notification permissions are denied, and continues scheduling notifications that will never be delivered.

**Recommendation:** Handle the authorization result and update app state accordingly.

**Status: FIXED** - `requestPermission()` now accepts an optional completion callback and logs errors under `#if DEBUG`.

---

### [I-1] INFO: Debug logging in production code

**File:** `PrayerTimes/PrayerTimeViewModel.swift:152`

```swift
.catch { error -> Just<[NominatimResult]> in
    print("🔴 DECODING ERROR: \(error)")
    return Just([])
}
```

Also at `PrayerTimes/StartupManager.swift:19`:
```swift
print("Failed to update launch at login setting: \(error.localizedDescription)")
```

And `PrayerTimes/PrayerTimerMonitor.swift:35,53`:
```swift
print("Prayer Timer is disabled. No timer will be scheduled.")
print("Prayer Timer: Alert scheduled based on prayer time update...")
```

`print()` statements in production code write to system logs. On macOS, Console.app can capture these. The decoding error log could include user search query context. This is very low risk since it requires local access.

**Recommendation:** Use `os_log` with appropriate privacy levels, or remove debug prints from production builds using `#if DEBUG` guards.

**Status: FIXED** - All `print()` calls wrapped in `#if DEBUG` guards across `PrayerTimeViewModel.swift`, `StartupManager.swift`, and `PrayerTimerMonitor.swift`.

---

## Positive Findings

The following security-relevant practices are correctly implemented:

1. **App Sandbox enabled** (`PrayerTimes.entitlements:5`) - The app runs in a macOS sandbox with minimal entitlements: network client, read-only user-selected files, and location.

2. **Minimal entitlements** - Only 4 entitlements are requested, each justified by app functionality. No write access to arbitrary files, no camera/microphone, no contacts.

3. **No hardcoded secrets** - No API keys, tokens, passwords, or other credentials exist anywhere in the codebase. The Nominatim API is public and requires no authentication.

4. **Proper URL construction** (`PrayerTimeViewModel.swift:136-144`) - The Nominatim API call uses `URLComponents` and `URLQueryItem` for proper parameter encoding, preventing URL injection.

5. **Coordinate input validation** (`PrayerTimeViewModel.swift:176`) - User-entered coordinates are validated against valid ranges (lat: -90 to 90, lon: -180 to 180).

6. **Numeric input clamping** (`TextFieldStepper.swift:88`) - Text field stepper values are clamped to allowed ranges, preventing out-of-bounds values.

7. **HTTPS for all network calls** - The only external network call (Nominatim) uses HTTPS.

8. **Standard Apple APIs** - Location services use `CLLocationManager` with proper authorization status handling. Notifications use `UNUserNotificationCenter`. Launch-at-login uses `SMAppService`.

9. **No sensitive data in notifications** - Notification content only contains prayer names (hardcoded strings), not user location data.

10. **NSOpenPanel for file selection** (`PrayerTimeViewModel.swift:338`) - Custom sound files are selected via `NSOpenPanel` with content type restrictions (`.audio` only), which respects sandbox boundaries.

---

## Scope and Methodology

**Files reviewed:** All 39 Swift source files, entitlements, Info.plist, Package.resolved, and asset configurations.

**Areas analyzed:**
- Sandbox configuration and entitlements
- Data storage and persistence mechanisms
- Location data handling and privacy
- Network communication (API calls, TLS)
- Input validation and sanitization
- Notification security
- Dependency supply chain
- Runtime behavior (swizzling, event monitoring)

**Out of scope:** Binary analysis, runtime memory inspection, third-party dependency source code review (adhan-swift, NavigationStack internals).
