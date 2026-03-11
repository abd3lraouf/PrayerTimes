#if DEBUG
import SwiftUI
import UserNotifications

struct NotificationTestView: View {
    @State private var selectedPrayer: String = "Fajr"
    @State private var selectedMinutes: Int = 10
    @State private var testResult: (message: String, isError: Bool)?

    private let prayers = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha", "Tahajud", "Dhuha", "RamadanSuhoor", "RamadanIftar"]
    private let minuteOptions = [5, 10, 15, 20, 30]

    var body: some View {
        VStack(spacing: 10) {
            // Config row: Prayer picker + Countdown picker
            HStack(spacing: 8) {
                Picker(NSLocalizedString("Prayer", comment: ""), selection: $selectedPrayer) {
                    ForEach(prayers, id: \.self) { prayer in
                        Text(Self.pickerLabel(for: prayer)).tag(prayer)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)

                Picker(NSLocalizedString("Countdown", comment: ""), selection: $selectedMinutes) {
                    ForEach(minuteOptions, id: \.self) { min in
                        Text(String(format: NSLocalizedString("%@ min", comment: ""), String(min))).tag(min)
                    }
                }
                .pickerStyle(.menu)
                .fixedSize()
            }

            // Full Screen row
            HStack(spacing: 6) {
                Image(systemName: "rectangle.inset.filled")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)
                testButton(NSLocalizedString("Test At Time", comment: ""), action: testFullScreenAtTime)
                testButton(NSLocalizedString("Pre-notify", comment: ""), action: testFullScreenPre)
            }

            // System row
            HStack(spacing: 6) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .frame(width: 14)
                testButton(NSLocalizedString("Test At Time", comment: ""), action: testSystemNow)
                testButton(NSLocalizedString("Pre-notify", comment: ""), action: testSystemPre)
            }

            // Result
            if let result = testResult {
                HStack(spacing: 4) {
                    Image(systemName: result.isError ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(result.isError ? .red : .green)
                    Text(result.message)
                        .foregroundStyle(.secondary)
                }
                .font(.system(size: 10))
                .transition(.opacity)
            }
        }
        .padding(12)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Helpers

    private static func pickerLabel(for prayer: String) -> String {
        switch prayer {
        case "RamadanSuhoor": return "🌙 " + NSLocalizedString("Suhoor", comment: "") + " (Ramadan)"
        case "RamadanIftar":  return "🌅 " + NSLocalizedString("Iftar", comment: "") + " (Ramadan)"
        default:              return NSLocalizedString(prayer, comment: "")
        }
    }

    // MARK: - Components

    private func testButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .lineLimit(1)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .background(.tint.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .strokeBorder(.tint.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private var futureTime: Date {
        Date().addingTimeInterval(TimeInterval(selectedMinutes * 60))
    }

    /// Maps Ramadan keys to their display name; standard prayers use NSLocalizedString directly.
    private var displayName: String {
        switch selectedPrayer {
        case "RamadanSuhoor": return NSLocalizedString("Suhoor", comment: "")
        case "RamadanIftar":  return NSLocalizedString("Iftar", comment: "")
        default:              return NSLocalizedString(selectedPrayer, comment: "")
        }
    }

    private func showResult(_ message: String, isError: Bool = false) {
        withAnimation(.easeOut(duration: 0.2)) {
            testResult = (message, isError)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation(.easeIn(duration: 0.3)) {
                testResult = nil
            }
        }
    }

    private func testFullScreenAtTime() {
        FullScreenNotificationManager.shared.showFullScreenNotification(
            prayerName: displayName,
            prayerKey: selectedPrayer,
            prayerTime: futureTime
        )
        showResult(NSLocalizedString("Full screen notification triggered", comment: ""))
    }

    private func testFullScreenPre() {
        FullScreenNotificationManager.shared.showFullScreenNotification(
            prayerName: displayName,
            prayerKey: selectedPrayer,
            prayerTime: futureTime,
            isPreNotification: true,
            minutesBefore: selectedMinutes
        )
        showResult(NSLocalizedString("Full screen pre-notification triggered", comment: ""))
    }

    private func testSystemNow() {
        let content = UNMutableNotificationContent()
        content.title = displayName
        content.body = NSLocalizedString("prayer_time_now", comment: "")
        content.sound = .default
        content.categoryIdentifier = "PRAYER_TIME"
        content.userInfo = [
            "prayerName": selectedPrayer,
            "prayerTime": Date(),
            "isPreNotification": false
        ]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "test_\(selectedPrayer)_now", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    showResult(String(format: NSLocalizedString("Error: %@", comment: ""), error.localizedDescription), isError: true)
                } else {
                    showResult(NSLocalizedString("System notification sent", comment: ""))
                }
            }
        }
    }

    private func testSystemPre() {
        let content = UNMutableNotificationContent()
        content.title = displayName
        content.body = String(format: NSLocalizedString("prayer_coming_in_minutes", comment: ""), locale: Locale.current, selectedMinutes)
        content.sound = .default
        content.categoryIdentifier = "PRAYER_PRE"
        content.userInfo = [
            "prayerName": selectedPrayer,
            "prayerTime": futureTime,
            "isPreNotification": true,
            "minutesBefore": selectedMinutes
        ]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "test_\(selectedPrayer)_pre", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            DispatchQueue.main.async {
                if let error = error {
                    showResult(String(format: NSLocalizedString("Error: %@", comment: ""), error.localizedDescription), isError: true)
                } else {
                    showResult(NSLocalizedString("System pre-notification sent", comment: ""))
                }
            }
        }
    }
}

class NotificationTestWindowController {
    static let shared = NotificationTestWindowController()
    private var window: NSWindow?

    func show(languageManager: LanguageManager) {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = LanguageManagerView(manager: languageManager) {
            NotificationTestView()
        }

        let hostingView = NSHostingView(rootView: rootView)
        hostingView.setContentHuggingPriority(.required, for: .vertical)
        hostingView.setContentCompressionResistancePriority(.required, for: .vertical)
        let fittingSize = hostingView.fittingSize

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: max(fittingSize.width, 280), height: fittingSize.height),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.title = NSLocalizedString("Notification Testing", comment: "")
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
#endif
