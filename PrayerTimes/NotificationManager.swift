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

    static func checkPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let granted = settings.authorizationStatus == .authorized
            hasPermission = granted
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    static func scheduleNotifications(
        for prayerTimes: [String: Date],
        prayerOrder: [String],
        settings: NotificationSettings
    ) {
        cancelNotifications()

        guard settings.prayerNotificationsEnabled else { return }

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
            let style = prayerSettings.notificationStyle
            let needsSystemNotification = (style == .system || style == .both)

            guard needsSystemNotification else { continue }

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

            let style = prayerSettings.notificationStyle
            let needsFullScreen = (style == .fullScreen || style == .both)

            guard needsFullScreen else { continue }

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
        content.body = String(format: NSLocalizedString("prayer_in_minutes_notification", comment: ""), minutesBefore)
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
                FullScreenNotificationManager.shared.showFullScreenNotification(
                    prayerName: NSLocalizedString(n.prayerName, comment: ""),
                    prayerTime: n.fireDate,
                    isPreNotification: n.isPreNotification,
                    minutesBefore: n.minutesBefore
                )
            }
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
}
