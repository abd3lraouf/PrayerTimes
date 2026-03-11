import SwiftUI
import Combine
import NavigationStack
import UserNotifications

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject, NSWindowDelegate, UNUserNotificationCenterDelegate {
    let vm = PrayerTimeViewModel()
    let languageManager = LanguageManager()
    let hijriManager = HijriCalendarManager()
    let fastingManager = FastingModeManager()
    
    var menuBarExtra: FluidMenuBarExtra?
    private var cancellables = Set<AnyCancellable>()
    private var wakeObserver: NSObjectProtocol?
    @AppStorage(StorageKeys.showOnboardingAtLaunch) private var showOnboardingAtLaunch = true
    
    private var onboardingWindow: NSWindow?

    private var isTestingMode: Bool {
        ProcessInfo.processInfo.environment["TESTING"] != nil
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Bundle.setLanguage(languageManager.language)
        UNUserNotificationCenter.current().delegate = self

        // Apply test overrides before any other logic
        if isTestingMode {
            applyTestEnvironment()
        }

        // Only auto-request permission if onboarding is disabled.
        // If onboarding is shown, it handles the permission request with proper context.
        if !showOnboardingAtLaunch {
            NotificationManager.getAuthorizationStatus { status in
                if status == .notDetermined {
                    NotificationManager.requestPermission()
                }
            }
        }

        UserDefaults.standard.register(defaults: [StorageKeys.islamicEventNotifications: true])
        StartupManager.syncLoginItemState()

        setupMenuBar()
        vm.fastingManager = fastingManager
        vm.startLocationProcess()
        fastingManager.checkAndAutoEnable()

        // Schedule Islamic event notifications after a short delay to allow setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            NotificationManager.scheduleIslamicEventNotifications(hijriManager: self.hijriManager)
        }

        vm.$menuTitle.debounce(for: .milliseconds(100), scheduler: RunLoop.main).sink { [weak self] newTitle in self?.menuBarExtra?.updateTitle(to: newTitle) }.store(in: &cancellables)
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .debounce(for: .milliseconds(50), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.updateIconForMode(self.vm.menuBarTextMode)
            }
            .store(in: &cancellables)

        let isScreenshotMode = ProcessInfo.processInfo.environment["SCREENSHOT_LANGUAGE"] != nil
        if self.showOnboardingAtLaunch && !isScreenshotMode && !isTestingMode {
            self.showOnboardingWindow()
        }

        // Auto-open the menu bar panel for screenshot automation
        if isScreenshotMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.menuBarExtra?.showWindow()
            }
        }

        // Show demo full-screen notification for screenshot automation
        if ProcessInfo.processInfo.environment["SCREENSHOT_FULLSCREEN"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let prayerName = NSLocalizedString("Fajr", comment: "")
                FullScreenNotificationManager.shared.showFullScreenNotification(
                    prayerName: prayerName,
                    prayerKey: "Fajr",
                    prayerTime: Date()
                )
            }
        }

        wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.systemDidWake()
        }
        
        // Register notification categories
        registerNotificationCategories()
    }
    
    // MARK: - Test Environment

    private func applyTestEnvironment() {
        let env = ProcessInfo.processInfo.environment

        // Skip onboarding
        showOnboardingAtLaunch = false

        // Inject a fake location: "TESTING_LOCATION=lat,lon" or "TESTING_LOCATION=lat,lon,CityName"
        if let locationStr = env["TESTING_LOCATION"] {
            let parts = locationStr.split(separator: ",", maxSplits: 2)
            if parts.count >= 2,
               let lat = Double(parts[0].trimmingCharacters(in: .whitespaces)),
               let lon = Double(parts[1].trimmingCharacters(in: .whitespaces)) {
                let name = parts.count >= 3 ? String(parts[2]).trimmingCharacters(in: .whitespaces) : "Test Location"
                let manualData: [String: Any] = ["name": name, "latitude": lat, "longitude": lon]
                UserDefaults.standard.set(manualData, forKey: StorageKeys.manualLocationData)
                UserDefaults.standard.set(true, forKey: StorageKeys.isUsingManualLocation)
            }
        }
    }

    // MARK: - Notification Categories
    
    private func registerNotificationCategories() {
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: NSLocalizedString("Dismiss", comment: ""),
            options: []
        )
        
        let snooze5Action = UNNotificationAction(
            identifier: "SNOOZE_5",
            title: String(format: NSLocalizedString("Snooze %@ min", comment: ""), "5"),
            options: .foreground
        )
        
        let snooze10Action = UNNotificationAction(
            identifier: "SNOOZE_10",
            title: String(format: NSLocalizedString("Snooze %@ min", comment: ""), "10"),
            options: .foreground
        )
        
        let snooze15Action = UNNotificationAction(
            identifier: "SNOOZE_15",
            title: String(format: NSLocalizedString("Snooze %@ min", comment: ""), "15"),
            options: .foreground
        )
        
        let snooze30Action = UNNotificationAction(
            identifier: "SNOOZE_30",
            title: String(format: NSLocalizedString("Snooze %@ min", comment: ""), "30"),
            options: .foreground
        )
        
        let prayerCategory = UNNotificationCategory(
            identifier: "PRAYER_TIME",
            actions: [dismissAction, snooze5Action, snooze10Action, snooze15Action, snooze30Action],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: [.customDismissAction, .hiddenPreviewsShowTitle]
        )
        
        let prayerPreCategory = UNNotificationCategory(
            identifier: "PRAYER_PRE",
            actions: [dismissAction, snooze5Action, snooze10Action, snooze15Action, snooze30Action],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: [.customDismissAction, .hiddenPreviewsShowTitle]
        )
        
        let fastingCategory = UNNotificationCategory(
            identifier: "FASTING_SUHOOR",
            actions: [dismissAction, snooze5Action, snooze10Action],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: [.customDismissAction]
        )
        
        let iftarCategory = UNNotificationCategory(
            identifier: "FASTING_IFTAR",
            actions: [dismissAction],
            intentIdentifiers: [],
            hiddenPreviewsBodyPlaceholder: "",
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([
            prayerCategory,
            prayerPreCategory,
            fastingCategory,
            iftarCategory
        ])
    }
    
    private func systemDidWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.vm.updatePrayerTimes()
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        handleNotificationResponse(response, completionHandler: completionHandler)
    }
    
    private func handleNotificationResponse(_ response: UNNotificationResponse, completionHandler: @escaping () -> Void) {
        defer { completionHandler() }
        
        let userInfo = response.notification.request.content.userInfo
        let actionIdentifier = response.actionIdentifier
        
        guard let prayerName = userInfo["prayerName"] as? String else {
            return
        }
        
        switch actionIdentifier {
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification - show fullscreen
            if let prayerTime = userInfo["prayerTime"] as? Date {
                DispatchQueue.main.async {
                    FullScreenNotificationManager.shared.showFullScreenNotification(
                        prayerName: NSLocalizedString(prayerName, comment: ""),
                        prayerKey: prayerName,
                        prayerTime: prayerTime,
                        isPreNotification: userInfo["isPreNotification"] as? Bool ?? false,
                        minutesBefore: userInfo["minutesBefore"] as? Int
                    )
                }
            }
            
        case "SNOOZE_5":
            snoozeNotification(prayerName: prayerName, minutes: 5, userInfo: userInfo)
            
        case "SNOOZE_10":
            snoozeNotification(prayerName: prayerName, minutes: 10, userInfo: userInfo)
            
        case "SNOOZE_15":
            snoozeNotification(prayerName: prayerName, minutes: 15, userInfo: userInfo)
            
        case "SNOOZE_30":
            snoozeNotification(prayerName: prayerName, minutes: 30, userInfo: userInfo)
            
        case "DISMISS_ACTION":
            break
            
        default:
            break
        }
    }
    
    private func snoozeNotification(prayerName: String, minutes: Int, userInfo: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString(prayerName, comment: "")
        content.body = NSLocalizedString("Snoozed reminder", comment: "")
        content.sound = .default
        content.userInfo = userInfo
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(prayerName)_snooze_\(minutes)_\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let observer = wakeObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }
    
    private func setupMenuBar() {
        let showInDock = UserDefaults.standard.bool(forKey: StorageKeys.showInDock)
        NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
        
        self.menuBarExtra = FluidMenuBarExtra(title: vm.menuTitle.string, image: "MenuBarIcon") {
            LanguageManagerView(manager: self.languageManager) {
                ContentView()
                    .environmentObject(self.vm)
                    .environmentObject(self.vm.notificationSettings)
                    .environmentObject(self.hijriManager)
                    .environmentObject(self.fastingManager)
                    .environmentObject(NavigationModel())
            }
        }
        updateIconForMode(vm.menuBarTextMode)
        setupContextMenu()
    }
    
    private func setupContextMenu() {
        guard let button = menuBarExtra?.statusItem.button else { return }
        let menu = NSMenu()
        
        // Quick action: Show next prayer notification
        let showNotificationItem = NSMenuItem(title: NSLocalizedString("Show next prayer", comment: ""), action: #selector(showNextPrayerNotification), keyEquivalent: "")
        showNotificationItem.target = self
        menu.addItem(showNotificationItem)
        
        // Refresh prayer times
        let refreshItem = NSMenuItem(title: NSLocalizedString("Refresh prayer times", comment: ""), action: #selector(refreshPrayerTimes), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let welcomeItem = NSMenuItem(title: NSLocalizedString("Show Welcome Window", comment: ""), action: #selector(showOnboardingWindow), keyEquivalent: "")
        welcomeItem.target = self
        menu.addItem(welcomeItem)
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: NSLocalizedString("Quit PrayerTimes Pro", comment: ""), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)
        button.menu = menu
    }
    
    @objc func showNextPrayerNotification() {
        guard let prayerTime = vm.todayTimes[vm.nextPrayerName] else { return }
        let prayerName = NSLocalizedString(vm.nextPrayerName, comment: "")
        FullScreenNotificationManager.shared.showFullScreenNotification(
            prayerName: prayerName,
            prayerKey: vm.nextPrayerName,
            prayerTime: prayerTime
        )
    }
    
    @objc func refreshPrayerTimes() {
        vm.updatePrayerTimes()
    }

    @objc func showOnboardingWindow() {
        if let existingWindow = onboardingWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let onboardingView = LanguageManagerView(manager: languageManager) {
            OnboardingView()
                .environmentObject(self.vm)
                .environmentObject(self.vm.notificationSettings)
                .environmentObject(self.hijriManager)
                .environmentObject(self.fastingManager)
                .environmentObject(NavigationModel())
        }

        let hostingController = NSHostingController(rootView: onboardingView)
        let window = NSWindow(contentViewController: hostingController)
        
        window.setContentSize(NSSize(width: 420, height: 580))
        window.styleMask.remove(.resizable)
        window.center()
        
        window.title = "PrayerTimes Pro Welcome"
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.styleMask.insert(.fullSizeContentView)
        
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        self.onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.close()
        return false
    }
    
    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) == self.onboardingWindow {
            self.onboardingWindow = nil
        }
    }
    
    private func updateIconForMode(_ mode: MenuBarTextMode) {
        let isIconOnly = (mode == .hidden)
        let shouldShowIcon = vm.alwaysShowMenuBarIcon || isIconOnly
        guard let button = menuBarExtra?.statusItem.button else { return }
        if shouldShowIcon {
            if let image = NSImage(systemSymbolName: "moon.stars.fill", accessibilityDescription: "PrayerTimes") {
                let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                let configured = image.withSymbolConfiguration(config)
                configured?.isTemplate = true
                button.image = configured
                button.imagePosition = .imageLeading
            }
        } else {
            button.image = nil
        }
    }
}
