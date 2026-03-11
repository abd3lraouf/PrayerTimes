import SwiftUI
import AppKit

// MARK: - Data

struct FullScreenNotificationData {
    let prayerName: String
    let prayerKey: String
    let prayerTime: Date
    let isPreNotification: Bool
    let minutesBefore: Int?
}

// MARK: - Prayer Theme

enum PrayerTheme {
    case night      // Fajr, Isha, Tahajud
    case dawn       // Sunrise
    case day        // Dhuhr, Dhuha
    case afternoon  // Asr
    case sunset     // Maghrib

    init(prayerKey: String) {
        switch prayerKey {
        case "Fajr", "Isha", "Tahajud": self = .night
        case "Sunrise":                  self = .dawn
        case "Dhuhr", "Dhuha":           self = .day
        case "Asr":                      self = .afternoon
        case "Maghrib":                  self = .sunset
        default:                         self = .night
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .night:
            return [Color(red: 0.03, green: 0.04, blue: 0.14),
                    Color(red: 0.07, green: 0.05, blue: 0.22),
                    Color(red: 0.04, green: 0.03, blue: 0.10)]
        case .dawn:
            return [Color(red: 0.12, green: 0.08, blue: 0.22),
                    Color(red: 0.35, green: 0.15, blue: 0.25),
                    Color(red: 0.55, green: 0.25, blue: 0.18)]
        case .day:
            return [Color(red: 0.20, green: 0.45, blue: 0.70),
                    Color(red: 0.40, green: 0.60, blue: 0.80),
                    Color(red: 0.25, green: 0.50, blue: 0.72)]
        case .afternoon:
            return [Color(red: 0.45, green: 0.50, blue: 0.65),
                    Color(red: 0.60, green: 0.50, blue: 0.40),
                    Color(red: 0.40, green: 0.40, blue: 0.50)]
        case .sunset:
            return [Color(red: 0.15, green: 0.08, blue: 0.20),
                    Color(red: 0.55, green: 0.20, blue: 0.15),
                    Color(red: 0.70, green: 0.35, blue: 0.12)]
        }
    }

    var glowColor: Color {
        switch self {
        case .night:     return Color(red: 0.3, green: 0.3, blue: 0.8)
        case .dawn:      return Color(red: 0.8, green: 0.4, blue: 0.5)
        case .day:       return Color(red: 0.9, green: 0.85, blue: 0.5)
        case .afternoon: return Color(red: 0.9, green: 0.7, blue: 0.4)
        case .sunset:    return Color(red: 0.9, green: 0.4, blue: 0.2)
        }
    }

    var iconName: String {
        switch self {
        case .night:     return "moon.stars.fill"
        case .dawn:      return "sunrise.fill"
        case .day:       return "sun.max.fill"
        case .afternoon: return "sun.haze.fill"
        case .sunset:    return "sunset.fill"
        }
    }

    var cardFill: Color {
        switch self {
        case .night:     return Color(red: 0.06, green: 0.06, blue: 0.16)
        case .dawn:      return Color(red: 0.12, green: 0.08, blue: 0.16)
        case .day:       return Color(red: 0.12, green: 0.20, blue: 0.30)
        case .afternoon: return Color(red: 0.18, green: 0.18, blue: 0.22)
        case .sunset:    return Color(red: 0.14, green: 0.08, blue: 0.12)
        }
    }
}

// MARK: - Manager

class FullScreenNotificationManager: NSObject, ObservableObject {
    static let shared = FullScreenNotificationManager()

    @Published var isShowing = false
    @Published var notificationData: FullScreenNotificationData?

    private var window: NSWindow?
    private var pendingNotification: FullScreenNotificationData?
    private var isScreenLocked = false
    private var observersSetup = false

    private override init() { super.init() }

    private func ensureObserversSetup() {
        guard !observersSetup else { return }
        observersSetup = true
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(screenLocked(_:)),
                        name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        dnc.addObserver(self, selector: #selector(screenUnlocked(_:)),
                        name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)
    }

    @objc private func screenLocked(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isScreenLocked = true
            if self.isShowing {
                self.pendingNotification = self.notificationData
                self.dismissFullScreenNotification()
            }
        }
    }

    @objc private func screenUnlocked(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let wasLocked = self.isScreenLocked
            self.isScreenLocked = false
            if wasLocked, let p = self.pendingNotification {
                self.showFullScreenNotification(
                    prayerName: p.prayerName, prayerKey: p.prayerKey,
                    prayerTime: p.prayerTime, isPreNotification: p.isPreNotification,
                    minutesBefore: p.minutesBefore)
                self.pendingNotification = nil
            }
        }
    }

    func showFullScreenNotification(
        prayerName: String, prayerKey: String = "",
        prayerTime: Date, isPreNotification: Bool = false,
        minutesBefore: Int? = nil
    ) {
        ensureObserversSetup()
        let key = prayerKey.isEmpty ? prayerName : prayerKey
        let data = FullScreenNotificationData(
            prayerName: prayerName, prayerKey: key,
            prayerTime: prayerTime, isPreNotification: isPreNotification,
            minutesBefore: minutesBefore)

        if isScreenLocked {
            pendingNotification = data
            return
        }

        DispatchQueue.main.async {
            #if DEBUG
            print("[FullScreen] Showing notification for \(key) — existing window: \(String(describing: self.window))")
            #endif
            // Dismiss any existing notification first
            if let oldWindow = self.window {
                #if DEBUG
                print("[FullScreen] Cleaning up existing window before showing new one")
                #endif
                self.window = nil
                oldWindow.orderOut(nil)
                oldWindow.contentView = nil
            }
            self.notificationData = data
            self.isShowing = true
            self.createWindow()
            NSSound(named: NSSound.Name("Glass"))?.play()
        }
    }

    func snooze(minutes: Int) {
        guard let d = notificationData else { return }
        dismissFullScreenNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(minutes * 60)) { [weak self] in
            self?.showFullScreenNotification(
                prayerName: d.prayerName, prayerKey: d.prayerKey,
                prayerTime: d.prayerTime, isPreNotification: d.isPreNotification,
                minutesBefore: d.minutesBefore)
        }
    }

    func dismissFullScreenNotification() {
        let doClose = {
            #if DEBUG
            print("[FullScreen] dismissFullScreenNotification — isShowing=\(self.isShowing), window=\(String(describing: self.window))")
            #endif
            guard self.isShowing || self.window != nil else {
                #if DEBUG
                print("[FullScreen] Already dismissed, nothing to do")
                #endif
                return
            }
            self.isShowing = false
            self.notificationData = nil
            if let w = self.window {
                self.window = nil
                w.orderOut(nil)
                w.contentView = nil
                #if DEBUG
                print("[FullScreen] Window ordered out and released")
                #endif
            } else {
                #if DEBUG
                print("[FullScreen] WARNING: window was nil but isShowing was true")
                #endif
            }
        }
        if Thread.isMainThread {
            doClose()
        } else {
            DispatchQueue.main.async(execute: doClose)
        }
    }

    private func createWindow() {
        guard let screen = NSScreen.main else { return }
        let w = FullScreenNotificationWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered, defer: false, screen: screen)
        w.level = .screenSaver
        w.backgroundColor = NSColor.black
        w.isOpaque = true
        w.hasShadow = false
        w.ignoresMouseEvents = false
        w.hidesOnDeactivate = false
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let hostingView = NSHostingView(rootView: FullScreenNotificationView())
        hostingView.frame = screen.frame
        w.contentView = hostingView

        self.window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Custom Window (handles ESC)

class FullScreenNotificationWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // ESC
            #if DEBUG
            print("[FullScreen] ESC key pressed — dismissing")
            #endif
            FullScreenNotificationManager.shared.dismissFullScreenNotification()
        } else {
            super.keyDown(with: event)
        }
    }
}

// MARK: - Full Screen View

struct FullScreenNotificationView: View {
    @ObservedObject var manager = FullScreenNotificationManager.shared
    @State private var appear = false
    @State private var iconPulse = false
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let snoozeOptions = [5, 10, 15]

    private var theme: PrayerTheme {
        PrayerTheme(prayerKey: manager.notificationData?.prayerKey ?? "")
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background — tappable to dismiss
                backgroundView(geo: geo)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        #if DEBUG
                        print("[FullScreen] Background tapped — dismissing")
                        #endif
                        dismiss()
                    }

                // Close button (top-right)
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            #if DEBUG
                            print("[FullScreen] Close button tapped — dismissing")
                            #endif
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(.white.opacity(0.5))
                                .contentShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(24)
                    }
                    Spacer()
                }

                // Dismiss hint at bottom
                VStack {
                    Spacer()
                    Text(NSLocalizedString("Tap anywhere or press Dismiss to close", comment: ""))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(appear ? 0.35 : 0))
                        .padding(.bottom, 40)
                        .allowsHitTesting(false)
                }

                // Card
                if let data = manager.notificationData {
                    cardContent(data: data)
                        .scaleEffect(appear ? 1.0 : 0.88)
                        .opacity(appear ? 1 : 0)
                }
            }
        }
        .colorScheme(.dark)
        .onAppear {
            #if DEBUG
            print("[FullScreen] View appeared — isShowing=\(manager.isShowing), data=\(String(describing: manager.notificationData?.prayerKey))")
            #endif
            withAnimation(.easeOut(duration: 0.6)) { appear = true }
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                iconPulse = true
            }
        }
        .onReceive(timer) { tick in
            self.now = tick
            if let data = manager.notificationData,
               data.isPreNotification, data.prayerTime <= tick {
                #if DEBUG
                print("[FullScreen] Pre-notification countdown expired — auto-dismissing")
                #endif
                dismiss()
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private func backgroundView(geo: GeometryProxy) -> some View {
        switch theme {
        case .night:     NightSceneView(size: geo.size, appear: appear)
        case .dawn:      DawnSceneView(size: geo.size, appear: appear)
        case .day:       DaySceneView(size: geo.size, appear: appear)
        case .afternoon: AfternoonSceneView(size: geo.size, appear: appear)
        case .sunset:    SunsetSceneView(size: geo.size, appear: appear)
        }
    }

    // MARK: - Card

    @ViewBuilder
    private func cardContent(data: FullScreenNotificationData) -> some View {
        let remaining = max(0, Int(data.prayerTime.timeIntervalSince(now)))

        VStack(spacing: 0) {
            // Pulsing icon
            ZStack {
                Image(systemName: theme.iconName)
                    .font(.system(size: 64))
                    .foregroundStyle(theme.glowColor.opacity(0.15))
                    .scaleEffect(iconPulse ? 1.8 : 1.0)
                    .opacity(iconPulse ? 0 : 0.5)

                Image(systemName: theme.iconName)
                    .font(.system(size: 64))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, theme.glowColor.opacity(0.7)],
                            startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .padding(.bottom, 28)

            // Prayer name
            Text(data.prayerName)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.bottom, 8)

            // Subtitle
            Group {
                if data.isPreNotification, let minutes = data.minutesBefore {
                    Text(String(format: NSLocalizedString("prayer_coming_in_minutes", comment: ""), String(minutes)))
                } else {
                    Text(NSLocalizedString("prayer_time_now", comment: ""))
                }
            }
            .font(.system(size: 24, weight: .medium))
            .foregroundColor(.white.opacity(0.65))
            .padding(.bottom, 4)

            // Prayer time
            Text(data.prayerTime, style: .time)
                .font(.system(size: 22, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
                .padding(.bottom, 32)

            // Pre-notification: countdown + snooze
            if data.isPreNotification && remaining > 0 {
                countdownView(remaining: remaining)
                    .padding(.bottom, 28)

                snoozeRow(secondsUntilPrayer: remaining)
                    .padding(.bottom, 28)
            }

            // At prayer time: warm urgent call to action
            if !data.isPreNotification || remaining <= 0 {
                VStack(spacing: 8) {
                    Text(NSLocalizedString("prayer_time_urgency", comment: ""))
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                    Text(NSLocalizedString("prayer_time_blessing", comment: ""))
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 28)
            }

            // Dismiss
            Button(action: dismiss) {
                Text(NSLocalizedString("Dismiss", comment: ""))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 220, height: 48)
                    .background(.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 64)
        .padding(.vertical, 52)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.cardFill.opacity(0.85))
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial.opacity(0.3))
                    .environment(\.colorScheme, .dark)
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.15), .white.opacity(0.03)],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.5), radius: 60))
    }

    // MARK: - Countdown

    private func countdownView(remaining: Int) -> some View {
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60

        return VStack(spacing: 10) {
            Text(NSLocalizedString("Time remaining", comment: ""))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(3)

            HStack(spacing: 0) {
                if h > 0 {
                    digitBlock(String(format: "%d", h))
                    colon
                }
                digitBlock(String(format: "%02d", m))
                colon
                digitBlock(String(format: "%02d", s))
            }
        }
    }

    private func digitBlock(_ value: String) -> some View {
        Text(value)
            .font(.system(size: 54, weight: .thin, design: .monospaced))
            .foregroundColor(.white)
            .monospacedDigit()
            .frame(minWidth: 64)
    }

    private var colon: some View {
        Text(":")
            .font(.system(size: 42, weight: .thin, design: .monospaced))
            .foregroundColor(.white.opacity(0.3))
            .frame(width: 18)
            .offset(y: -3)
    }

    // MARK: - Snooze

    private func snoozeRow(secondsUntilPrayer: Int) -> some View {
        let minutesLeft = secondsUntilPrayer / 60

        return VStack(spacing: 12) {
            Text(NSLocalizedString("Remind me in", comment: ""))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .textCase(.uppercase)
                .tracking(3)

            HStack(spacing: 10) {
                ForEach(snoozeOptions, id: \.self) { mins in
                    let enabled = minutesLeft > mins
                    Button(action: { manager.snooze(minutes: mins) }) {
                        Text(String(format: NSLocalizedString("%@ min", comment: ""), String(mins)))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(enabled ? .white.opacity(0.85) : .white.opacity(0.2))
                            .frame(width: 100, height: 40)
                            .background(enabled ? .white.opacity(0.1) : .white.opacity(0.03))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(.white.opacity(enabled ? 0.12 : 0.04), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                }
            }
        }
    }

    // MARK: - Dismiss

    private func dismiss() {
        #if DEBUG
        print("[FullScreen] SwiftUI dismiss() called — forwarding to manager")
        #endif
        manager.dismissFullScreenNotification()
    }
}

