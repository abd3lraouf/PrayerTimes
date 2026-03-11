import Foundation
import UserNotifications

struct ScheduledFullScreenNotification {
    let prayerName: String
    let fireDate: Date
    let isPreNotification: Bool
    let minutesBefore: Int?
    var hasFired: Bool = false
}

struct NotificationManager {

    private(set) static var scheduledFullScreenNotifications: [ScheduledFullScreenNotification] = []
    private static var hasPermission: Bool = false

    static let notificationSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")!

    static func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            #if DEBUG
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            print("Notification permission granted: \(granted)")
            #endif
            hasPermission = granted
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    static func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    static func scheduleNotifications(
        for prayerTimes: [String: Date],
        prayerOrder: [String],
        settings: NotificationSettings
    ) {
        cancelPrayerNotifications()


        // Schedule full-screen notifications (no permission needed, uses polling)
        scheduleFullScreenTimers(for: prayerTimes, prayerOrder: prayerOrder, settings: settings)

        // Schedule system notifications directly.
        // Permission is requested early at app launch (AppDelegate).
        // If not granted, UNUserNotificationCenter.add() silently fails.
        scheduleSystemNotifications(for: prayerTimes, prayerOrder: prayerOrder, settings: settings)
    }

    private static func scheduleSystemNotifications(
        for prayerTimes: [String: Date],
        prayerOrder: [String],
        settings: NotificationSettings
    ) {
        for prayerName in prayerOrder {
            guard let prayerTime = prayerTimes[prayerName] else { continue }
            guard prayerTime > Date() else { continue }

            let prayerSettings = settings.effectiveSettings(for: prayerName)

            guard prayerSettings.isEnabled else { continue }

            let localizedPrayerName = NSLocalizedString(prayerName, comment: "")
            guard prayerSettings.systemNotificationEnabled else { continue }

            switch prayerSettings.notificationType {
            case .atPrayerTime:
                scheduleSystemNotification(
                    prayerName: prayerName,
                    localizedPrayerName: localizedPrayerName,
                    prayerTime: prayerTime,
                    isPreNotification: false
                )

            case .beforePrayer:
                schedulePreSystemNotification(
                    prayerName: prayerName,
                    localizedPrayerName: localizedPrayerName,
                    prayerTime: prayerTime,
                    minutesBefore: prayerSettings.prePrayerMinutes.rawValue
                )

            case .both:
                scheduleSystemNotification(
                    prayerName: prayerName,
                    localizedPrayerName: localizedPrayerName,
                    prayerTime: prayerTime,
                    isPreNotification: false
                )
                schedulePreSystemNotification(
                    prayerName: prayerName,
                    localizedPrayerName: localizedPrayerName,
                    prayerTime: prayerTime,
                    minutesBefore: prayerSettings.prePrayerMinutes.rawValue
                )
            }
        }
    }

    private static func scheduleFullScreenTimers(
        for prayerTimes: [String: Date],
        prayerOrder: [String],
        settings: NotificationSettings
    ) {
        for prayerName in prayerOrder {
            guard let prayerTime = prayerTimes[prayerName] else { continue }
            guard prayerTime > Date() else { continue }

            let prayerSettings = settings.effectiveSettings(for: prayerName)

            guard prayerSettings.isEnabled else { continue }

            guard prayerSettings.fullScreenNotificationEnabled else { continue }

            switch prayerSettings.notificationType {
            case .atPrayerTime:
                scheduleFullScreenTimer(
                    prayerName: prayerName,
                    fireDate: prayerTime,
                    isPreNotification: false,
                    minutesBefore: nil
                )

            case .beforePrayer:
                if let preTime = Calendar.current.date(byAdding: .minute, value: -prayerSettings.prePrayerMinutes.rawValue, to: prayerTime),
                   preTime > Date() {
                    scheduleFullScreenTimer(
                        prayerName: prayerName,
                        fireDate: preTime,
                        isPreNotification: true,
                        minutesBefore: prayerSettings.prePrayerMinutes.rawValue
                    )
                }

            case .both:
                scheduleFullScreenTimer(
                    prayerName: prayerName,
                    fireDate: prayerTime,
                    isPreNotification: false,
                    minutesBefore: nil
                )
                if let preTime = Calendar.current.date(byAdding: .minute, value: -prayerSettings.prePrayerMinutes.rawValue, to: prayerTime),
                   preTime > Date() {
                    scheduleFullScreenTimer(
                        prayerName: prayerName,
                        fireDate: preTime,
                        isPreNotification: true,
                        minutesBefore: prayerSettings.prePrayerMinutes.rawValue
                    )
                }
            }
        }
    }

    private static func scheduleSystemNotification(
        prayerName: String,
        localizedPrayerName: String,
        prayerTime: Date,
        isPreNotification: Bool
    ) {
        let content = UNMutableNotificationContent()
        content.title = localizedPrayerName
        content.body = String(format: NSLocalizedString("It's time for the %@ prayer.", comment: ""), localizedPrayerName)
        content.sound = .default
        content.userInfo = ["prayerName": prayerName, "isPreNotification": isPreNotification]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: prayerTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "\(prayerName)_at", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("Failed to schedule \(prayerName)_at: \(error.localizedDescription)")
            } else {
                print("Scheduled system notification: \(prayerName)_at at \(prayerTime)")
            }
            #endif
        }
    }

    private static func schedulePreSystemNotification(
        prayerName: String,
        localizedPrayerName: String,
        prayerTime: Date,
        minutesBefore: Int
    ) {
        guard let preTime = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: prayerTime) else { return }
        guard preTime > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = localizedPrayerName
        content.body = String(format: NSLocalizedString("prayer_in_minutes_notification", comment: ""), LanguageManager.formatNumberStatic(minutesBefore))
        content.sound = .default
        content.userInfo = ["prayerName": prayerName, "isPreNotification": true, "minutesBefore": minutesBefore]

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: preTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "\(prayerName)_pre_\(minutesBefore)", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("Failed to schedule \(prayerName)_pre: \(error.localizedDescription)")
            } else {
                print("Scheduled system notification: \(prayerName)_pre at \(preTime)")
            }
            #endif
        }
    }

    private static func scheduleFullScreenTimer(
        prayerName: String,
        fireDate: Date,
        isPreNotification: Bool,
        minutesBefore: Int?
    ) {
        guard fireDate.timeIntervalSinceNow > 0 else { return }

        let notification = ScheduledFullScreenNotification(
            prayerName: prayerName,
            fireDate: fireDate,
            isPreNotification: isPreNotification,
            minutesBefore: minutesBefore
        )
        scheduledFullScreenNotifications.append(notification)

        #if DEBUG
        let interval = fireDate.timeIntervalSinceNow
        print("Scheduled full-screen notification: \(prayerName) \(isPreNotification ? "pre" : "at") firing in \(String(format: "%.1f", interval / 60)) minutes")
        #endif
    }

    /// Called from the per-second countdown timer to reliably fire full-screen notifications.
    static func checkPendingFullScreenNotifications() {
        let now = Date()
        for i in scheduledFullScreenNotifications.indices {
            guard !scheduledFullScreenNotifications[i].hasFired else { continue }
            if now >= scheduledFullScreenNotifications[i].fireDate {
                scheduledFullScreenNotifications[i].hasFired = true
                let n = scheduledFullScreenNotifications[i]
                // Map Ramadan keys to localized display names
                let displayName: String
                switch n.prayerName {
                case "RamadanSuhoor": displayName = NSLocalizedString("Suhoor", comment: "")
                case "RamadanIftar":  displayName = NSLocalizedString("Iftar", comment: "")
                default:              displayName = NSLocalizedString(n.prayerName, comment: "")
                }
                FullScreenNotificationManager.shared.showFullScreenNotification(
                    prayerName: displayName,
                    prayerKey: n.prayerName,
                    prayerTime: n.fireDate,
                    isPreNotification: n.isPreNotification,
                    minutesBefore: n.minutesBefore
                )
            }
        }
    }

    static func cancelPrayerNotifications() {
        let prayerNames = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha", "Tahajud", "Dhuha", "Sunrise"]
        var identifiers: [String] = []
        for name in prayerNames {
            identifiers.append("\(name)_at")
            for minutes in [1, 5, 10, 20, 25, 30] {
                identifiers.append("\(name)_pre_\(minutes)")
            }
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        scheduledFullScreenNotifications.removeAll()
    }

    // MARK: - Fasting Mode Notifications

    static func scheduleFastingNotifications(
        prayerTimes: [String: Date],
        fastingManager: FastingModeManager,
        settings: NotificationSettings? = nil
    ) {
        guard fastingManager.isFastingModeEnabled else { return }

        let suhoorMinutes = UserDefaults.standard.object(forKey: StorageKeys.suhoorPreAlertMinutes) as? Int ?? 30
        let iftarEnabled = UserDefaults.standard.object(forKey: StorageKeys.iftarNotificationEnabled) as? Bool ?? true
        // Respect full-screen preference: use Fajr settings for Suhoor, Maghrib for Iftar
        let suhoorFullScreen = settings?.effectiveSettings(for: "Fajr").fullScreenNotificationEnabled ?? false
        let iftarFullScreen = settings?.effectiveSettings(for: "Maghrib").fullScreenNotificationEnabled ?? false
        let duaEnabled = UserDefaults.standard.bool(forKey: StorageKeys.duaRemindersEnabled)
        let taraweehEnabled = UserDefaults.standard.bool(forKey: StorageKeys.taraweehReminderEnabled)
        let taraweehMinutes = UserDefaults.standard.object(forKey: StorageKeys.taraweehMinutesAfterIsha) as? Int ?? 30

        // Suhoor pre-alert (X minutes before Imsak/Suhoor time)
        if let suhoor = fastingManager.suhoorTime(from: prayerTimes) {
            if let preTime = Calendar.current.date(byAdding: .minute, value: -suhoorMinutes, to: suhoor),
               preTime > Date() {
                scheduleSimpleNotification(
                    id: "fasting_suhoor_pre",
                    title: NSLocalizedString("Suhoor", comment: ""),
                    body: String(format: NSLocalizedString("suhoor_ends_in_minutes", comment: ""), suhoorMinutes),
                    at: preTime
                )
                // Full-screen Ramadan cannon notification for Suhoor
                if suhoorFullScreen {
                    scheduleFullScreenTimer(
                        prayerName: "RamadanSuhoor",
                        fireDate: preTime,
                        isPreNotification: true,
                        minutesBefore: suhoorMinutes
                    )
                }
            }
        }

        // Dua at actual Fajr time (not Imsak)
        if duaEnabled, let fajr = prayerTimes["Fajr"], fajr > Date() {
            scheduleSimpleNotification(
                id: "fasting_dua_suhoor",
                title: NSLocalizedString("Fajr", comment: ""),
                body: NSLocalizedString("dua_beginning_fast", comment: ""),
                at: fajr
            )
        }

        // Iftar alert (at Maghrib)
        if iftarEnabled,
           let maghrib = fastingManager.iftarTime(from: prayerTimes),
           maghrib > Date() {
            scheduleSimpleNotification(
                id: "fasting_iftar",
                title: NSLocalizedString("Iftar", comment: ""),
                body: NSLocalizedString("iftar_time_body", comment: ""),
                at: maghrib
            )
            // Full-screen Ramadan cannon notification for Iftar
            if iftarFullScreen {
                scheduleFullScreenTimer(
                    prayerName: "RamadanIftar",
                    fireDate: maghrib,
                    isPreNotification: false,
                    minutesBefore: nil
                )
            }

            if duaEnabled {
                scheduleSimpleNotification(
                    id: "fasting_dua_iftar",
                    title: NSLocalizedString("Iftar", comment: ""),
                    body: NSLocalizedString("dua_breaking_fast", comment: ""),
                    at: maghrib
                )
            }
        }

        // Taraweeh reminder
        if taraweehEnabled,
           let taraweeh = fastingManager.taraweehTime(from: prayerTimes, minutesAfterIsha: taraweehMinutes),
           taraweeh > Date() {
            scheduleSimpleNotification(
                id: "fasting_taraweeh",
                title: NSLocalizedString("Taraweeh", comment: ""),
                body: NSLocalizedString("taraweeh_reminder_body", comment: ""),
                at: taraweeh
            )
        }
    }

    private static func scheduleSimpleNotification(id: String, title: String, body: String, at date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("Failed to schedule \(id): \(error.localizedDescription)")
            } else {
                print("Scheduled fasting notification: \(id) at \(date)")
            }
            #endif
        }
    }

    static func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduledFullScreenNotifications.removeAll()
    }

    static func getScheduledNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }

    // MARK: - Islamic Event Notifications

    static func scheduleIslamicEventNotifications(hijriManager: HijriCalendarManager) {
        guard UserDefaults.standard.bool(forKey: StorageKeys.islamicEventNotifications) else { return }

        cancelIslamicEventNotifications()

        let today = Date()
        let todayComponents = hijriManager.hijriDate(from: today)
        guard let currentMonth = todayComponents.month, let currentYear = todayComponents.year else { return }

        // Schedule for remaining events this month and all of next month
        let monthsToCheck: [(Int, Int)] = {
            var result = [(currentMonth, currentYear)]
            let nextMonth = currentMonth == 12 ? 1 : currentMonth + 1
            let nextYear = currentMonth == 12 ? currentYear + 1 : currentYear
            result.append((nextMonth, nextYear))
            return result
        }()

        for (month, year) in monthsToCheck {
            let events = IslamicEvents.events(forMonth: month)
            for event in events {
                var eventComponents = DateComponents()
                eventComponents.month = month
                eventComponents.day = event.day
                eventComponents.year = year
                let eventGregorianDate = hijriManager.gregorianDate(fromHijri: eventComponents)

                // Schedule notification for the day before at 8 PM
                guard let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: eventGregorianDate) else { continue }
                guard dayBefore > today else { continue }

                var triggerComponents = Calendar.current.dateComponents([.year, .month, .day], from: dayBefore)
                triggerComponents.hour = 20
                triggerComponents.minute = 0

                let content = UNMutableNotificationContent()
                content.title = event.localizedName
                content.body = String(format: NSLocalizedString("event_tomorrow_notification", comment: ""), event.localizedName)
                content.sound = .default
                content.userInfo = ["isIslamicEvent": true, "eventKey": event.nameKey]

                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
                let identifier = "islamic_event_\(event.nameKey)_\(month)_\(event.day)_\(year)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

                UNUserNotificationCenter.current().add(request) { error in
                    #if DEBUG
                    if let error = error {
                        print("Failed to schedule Islamic event notification: \(error.localizedDescription)")
                    } else {
                        print("Scheduled Islamic event notification: \(event.nameKey) for \(dayBefore)")
                    }
                    #endif
                }
            }
        }
    }

    static func cancelIslamicEventNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eventIds = requests.filter { $0.identifier.hasPrefix("islamic_event_") }.map { $0.identifier }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: eventIds)
        }
    }
    
}
