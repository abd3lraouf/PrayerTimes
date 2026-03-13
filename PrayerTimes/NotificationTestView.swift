#if DEBUG
import SwiftUI

struct NotificationTestView: View {
    @State private var selectedPrayer = "Fajr"

    private let prayers = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha",
                           "Tahajud", "Dhuha", "RamadanSuhoor", "RamadanIftar"]

    private var displayName: String {
        switch selectedPrayer {
        case "RamadanSuhoor": return NSLocalizedString("Suhoor", comment: "")
        case "RamadanIftar":  return NSLocalizedString("Iftar", comment: "")
        default:              return NSLocalizedString(selectedPrayer, comment: "")
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("Prayer", selection: $selectedPrayer) {
                ForEach(prayers, id: \.self) { key in
                    Text(label(for: key)).tag(key)
                }
            }
            .pickerStyle(.menu)

            HStack(spacing: 8) {
                Button("At Time") {
                    show(isPreNotification: false)
                }
                Button("Pre (10 min)") {
                    show(isPreNotification: true, minutesBefore: 10)
                }
                Button("Pre (5 min)") {
                    show(isPreNotification: true, minutesBefore: 5)
                }
            }
        }
        .padding(16)
        .frame(width: 320)
    }

    private func label(for key: String) -> String {
        switch key {
        case "RamadanSuhoor": return "🌙 Suhoor (Ramadan)"
        case "RamadanIftar":  return "🌅 Iftar (Ramadan)"
        default:              return key
        }
    }

    private func show(isPreNotification: Bool, minutesBefore: Int? = nil) {
        let prayerTime = Date().addingTimeInterval(TimeInterval((minutesBefore ?? 10) * 60))
        FullScreenNotificationManager.shared.showFullScreenNotification(
            prayerName: displayName,
            prayerKey: selectedPrayer,
            prayerTime: prayerTime,
            isPreNotification: isPreNotification,
            minutesBefore: minutesBefore
        )
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
        let fittingSize = hostingView.fittingSize

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: max(fittingSize.width, 280), height: fittingSize.height),
            styleMask: [.titled, .closable],
            backing: .buffered, defer: false)
        window.title = "Full Screen Tester"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        self.window = window
    }
}
#endif
