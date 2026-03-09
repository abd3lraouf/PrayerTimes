# Notification Permission Fix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix notification permissions so they are properly requested during onboarding, checked at startup when onboarding is disabled, and surfaced in the notification settings UI when denied.

**Architecture:** Add a notification permission step to OnboardingView (between location and calculation method). Move the eager `requestPermission()` out of AppDelegate into a smarter flow: if onboarding is shown, let onboarding handle it; if onboarding is disabled, request permission at startup only if status is `.notDetermined`. Add a permission denied banner to NotificationsSettingsView with an "Open System Settings" button.

**Tech Stack:** SwiftUI, UserNotifications (UNUserNotificationCenter), macOS System Settings deep link

---

### Task 1: Add notification permission state to NotificationManager

**Files:**
- Modify: `PrayerTimes/NotificationManager.swift:15-40`

**Step 1: Add a published permission status check method that returns the raw authorization status**

Replace `checkPermission` with a method that returns `UNAuthorizationStatus` so callers can distinguish between `.notDetermined`, `.denied`, and `.authorized`:

```swift
static func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        DispatchQueue.main.async {
            completion(settings.authorizationStatus)
        }
    }
}
```

Keep the existing `checkPermission` and `requestPermission` methods as they are - they're still used.

**Step 2: Commit**

```bash
git add PrayerTimes/NotificationManager.swift
git commit -m "feat: add getAuthorizationStatus to NotificationManager"
```

---

### Task 2: Add notification permission step to OnboardingView

**Files:**
- Modify: `PrayerTimes/OnboardingView.swift`

**Step 1: Add notification permission state variables**

After the existing `@State` properties (around line 15), add:

```swift
@State private var notificationStatus: UNAuthorizationStatus = .notDetermined
@State private var isHoveringOpenSettings = false
```

Add import at top:

```swift
import UserNotifications
```

**Step 2: Add notification section between location and calculation method**

After the location section's closing `}` (around line 99-101) and before `if vm.isPrayerDataAvailable {` (line 105), add a notification permission section:

```swift
if vm.isPrayerDataAvailable {
    VStack(spacing: 8) {
        Rectangle()
            .fill(Color("DividerColor"))
            .frame(height: 0.5)
            .padding(.horizontal, 20)

        VStack(spacing: 8) {
            if notificationStatus == .authorized {
                InfoStatusView(
                    text: "Notifications are enabled.",
                    icon: "bell.badge.fill",
                    color: .green
                )
            } else if notificationStatus == .denied {
                InfoStatusView(
                    text: "Notifications are disabled. Please enable in System Settings.",
                    icon: "bell.slash.fill",
                    color: .red
                )
                Button("Open System Settings") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                .underline(isHoveringOpenSettings)
                .onHover { isHoveringOpenSettings = $0 }
            } else {
                Text("Enable notifications to get prayer time alerts.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                Button("Enable Notifications") {
                    NotificationManager.requestPermission { granted in
                        notificationStatus = granted ? .authorized : .denied
                    }
                }
                .controlSize(.large)
                .tint(.accentColor)
            }
        }
        .padding(.horizontal, 40)
    }
    .transition(.opacity.combined(with: .move(edge: .bottom)))
}
```

**Step 3: Add onAppear to check current status**

Add `.onAppear` to the outermost `ZStack`:

```swift
.onAppear {
    NotificationManager.getAuthorizationStatus { status in
        notificationStatus = status
    }
}
```

**Step 4: Increase window height to accommodate new section**

Change `.frame(width: 420, height: 520)` to `.frame(width: 420, height: 580)`.

Also update `AppDelegate.swift` line 155: `window.setContentSize(NSSize(width: 420, height: 580))`.

**Step 5: Commit**

```bash
git add PrayerTimes/OnboardingView.swift PrayerTimes/AppDelegate.swift
git commit -m "feat: add notification permission step to onboarding"
```

---

### Task 3: Smart permission request in AppDelegate (handle onboarding-disabled case)

**Files:**
- Modify: `PrayerTimes/AppDelegate.swift:21-25`

**Step 1: Replace eager requestPermission with conditional logic**

Replace:
```swift
UNUserNotificationCenter.current().delegate = self
NotificationManager.requestPermission()
```

With:
```swift
UNUserNotificationCenter.current().delegate = self

// Only auto-request permission if onboarding is disabled.
// If onboarding is shown, it handles the permission request with proper context.
if !showOnboardingAtLaunch {
    NotificationManager.getAuthorizationStatus { status in
        if status == .notDetermined {
            NotificationManager.requestPermission()
        }
    }
}
```

**Step 2: Commit**

```bash
git add PrayerTimes/AppDelegate.swift
git commit -m "fix: only auto-request notification permission when onboarding is disabled"
```

---

### Task 4: Add permission denied banner to NotificationsSettingsView

**Files:**
- Modify: `PrayerTimes/NotificationsSettingsView.swift`

**Step 1: Add state for notification permission**

Add at the top of the struct, after existing `@State` properties:

```swift
@State private var notificationPermissionDenied = false
```

**Step 2: Add warning banner after the "Enable Prayer Notifications" toggle**

After the `StyledToggle` for enabling prayer notifications (line 41-45), add:

```swift
if notificationPermissionDenied {
    HStack(spacing: 6) {
        Image(systemName: "exclamationmark.triangle.fill")
            .foregroundColor(.orange)
            .font(.caption)
        Text("System notifications are disabled.")
            .font(.caption)
            .foregroundColor(.secondary)
        Spacer()
        Button("Open Settings") {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                NSWorkspace.shared.open(url)
            }
        }
        .font(.caption)
        .buttonStyle(.link)
    }
    .padding(8)
    .background(Color.orange.opacity(0.1))
    .cornerRadius(6)
}
```

**Step 3: Add onAppear to check permission**

Add `.onAppear` to the outer `VStack`:

```swift
.onAppear {
    NotificationManager.getAuthorizationStatus { status in
        notificationPermissionDenied = (status == .denied)
    }
}
```

Add import at top:

```swift
import UserNotifications
```

**Step 4: Commit**

```bash
git add PrayerTimes/NotificationsSettingsView.swift
git commit -m "feat: show notification permission warning banner in settings"
```

---

### Task 5: Add localization strings for all languages

**Files:**
- Modify: `PrayerTimes/en.lproj/Localizable.strings`
- Modify: `PrayerTimes/ar.lproj/Localizable.strings`
- Modify: `PrayerTimes/fa.lproj/Localizable.strings`
- Modify: `PrayerTimes/id.lproj/Localizable.strings`
- Modify: `PrayerTimes/ur.lproj/Localizable.strings`

**Step 1: Add English strings**

Add to the `/* Notifications Settings */` section:

```
/* Notification Permission */
"Notifications are enabled." = "Notifications are enabled.";
"Notifications are disabled. Please enable in System Settings." = "Notifications are disabled. Please enable in System Settings.";
"Enable notifications to get prayer time alerts." = "Enable notifications to get prayer time alerts.";
"Enable Notifications" = "Enable Notifications";
"System notifications are disabled." = "System notifications are disabled.";
"Open Settings" = "Open Settings";
```

**Step 2: Add Arabic strings**

```
/* Notification Permission */
"Notifications are enabled." = "الإشعارات مفعّلة.";
"Notifications are disabled. Please enable in System Settings." = "الإشعارات معطّلة. يرجى تفعيلها من إعدادات النظام.";
"Enable notifications to get prayer time alerts." = "فعّل الإشعارات لتلقي تنبيهات أوقات الصلاة.";
"Enable Notifications" = "تفعيل الإشعارات";
"System notifications are disabled." = "إشعارات النظام معطّلة.";
"Open Settings" = "فتح الإعدادات";
```

**Step 3: Add Farsi strings**

```
/* Notification Permission */
"Notifications are enabled." = "اعلان‌ها فعال هستند.";
"Notifications are disabled. Please enable in System Settings." = "اعلان‌ها غیرفعال هستند. لطفاً از تنظیمات سیستم فعال کنید.";
"Enable notifications to get prayer time alerts." = "اعلان‌ها را فعال کنید تا هشدارهای اوقات نماز دریافت کنید.";
"Enable Notifications" = "فعال‌سازی اعلان‌ها";
"System notifications are disabled." = "اعلان‌های سیستم غیرفعال هستند.";
"Open Settings" = "باز کردن تنظیمات";
```

**Step 4: Add Indonesian strings**

```
/* Notification Permission */
"Notifications are enabled." = "Notifikasi telah diaktifkan.";
"Notifications are disabled. Please enable in System Settings." = "Notifikasi dinonaktifkan. Silakan aktifkan di Pengaturan Sistem.";
"Enable notifications to get prayer time alerts." = "Aktifkan notifikasi untuk mendapatkan pengingat waktu shalat.";
"Enable Notifications" = "Aktifkan Notifikasi";
"System notifications are disabled." = "Notifikasi sistem dinonaktifkan.";
"Open Settings" = "Buka Pengaturan";
```

**Step 5: Add Urdu strings**

```
/* Notification Permission */
"Notifications are enabled." = "اطلاعات فعال ہیں۔";
"Notifications are disabled. Please enable in System Settings." = "اطلاعات غیر فعال ہیں۔ براہ کرم سسٹم سیٹنگز میں فعال کریں۔";
"Enable notifications to get prayer time alerts." = "نماز کے وقت کی اطلاعات حاصل کرنے کے لیے اطلاعات فعال کریں۔";
"Enable Notifications" = "اطلاعات فعال کریں";
"System notifications are disabled." = "سسٹم اطلاعات غیر فعال ہیں۔";
"Open Settings" = "سیٹنگز کھولیں";
```

**Step 6: Commit**

```bash
git add PrayerTimes/en.lproj/Localizable.strings PrayerTimes/ar.lproj/Localizable.strings PrayerTimes/fa.lproj/Localizable.strings PrayerTimes/id.lproj/Localizable.strings PrayerTimes/ur.lproj/Localizable.strings
git commit -m "feat: add notification permission localization strings for all languages"
```

---

### Task 6: Build and verify

**Step 1: Build the project**

```bash
cd /Users/abd3lraouf/Developer/PrayerTimes && xcodebuild -scheme PrayerTimes -configuration Debug build 2>&1 | tail -20
```

**Step 2: Fix any build errors**

**Step 3: Final commit if fixes were needed**

```bash
git add -A
git commit -m "fix: resolve build issues from notification permission changes"
```
