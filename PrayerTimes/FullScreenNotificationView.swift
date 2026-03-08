import SwiftUI

struct FullScreenNotificationData {
    let prayerName: String
    let prayerTime: Date
    let isPreNotification: Bool
    let minutesBefore: Int?
}

class FullScreenNotificationManager: ObservableObject {
    static let shared = FullScreenNotificationManager()
    
    @Published var isShowing = false
    @Published var notificationData: FullScreenNotificationData?
    
    private var window: NSWindow?
    
    private init() {}
    
    func showFullScreenNotification(prayerName: String, prayerTime: Date, isPreNotification: Bool = false, minutesBefore: Int? = nil) {
        DispatchQueue.main.async {
            self.notificationData = FullScreenNotificationData(
                prayerName: prayerName,
                prayerTime: prayerTime,
                isPreNotification: isPreNotification,
                minutesBefore: minutesBefore
            )
            self.isShowing = true
            self.createWindow()
        }
    }
    
    func dismissFullScreenNotification() {
        DispatchQueue.main.async {
            self.isShowing = false
            self.notificationData = nil
            self.window?.close()
            self.window = nil
        }
    }
    
    private func createWindow() {
        guard let screen = NSScreen.main else { return }
        
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.hidesOnDeactivate = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        let hostingView = NSHostingView(rootView: FullScreenNotificationView())
        window.contentView = hostingView
        
        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct FullScreenNotificationView: View {
    @ObservedObject var manager = FullScreenNotificationManager.shared
    @State private var opacity: Double = 0
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85 * opacity)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        manager.dismissFullScreenNotification()
                    }
                }
            
            if let data = manager.notificationData {
                VStack(spacing: 24) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.white)
                    
                    Text(data.prayerName)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    if data.isPreNotification, let minutes = data.minutesBefore {
                        Text(String(format: NSLocalizedString("prayer_coming_in_minutes", comment: ""), LanguageManager.formatNumberStatic(minutes)))
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                    } else {
                        Text(NSLocalizedString("prayer_time_now", comment: ""))
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text(data.prayerTime, style: .time)
                        .font(LanguageManager.numberFontStatic(size: 24))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            opacity = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            manager.dismissFullScreenNotification()
                        }
                    }) {
                        Text(NSLocalizedString("Dismiss", comment: ""))
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                }
                .padding(60)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(colorScheme == .dark ? Color.black.opacity(0.9) : Color.white.opacity(0.1))
                        .shadow(radius: 40)
                )
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
        }
    }
}
