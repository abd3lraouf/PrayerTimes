import Foundation
import UserNotifications

struct NotificationManager {
    
    static func requestPermission(completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            #if DEBUG
            if let error = error {
                print("Notification authorization error: \(error.localizedDescription)")
            }
            #endif
            DispatchQueue.main.async {
                completion?(granted)
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
        
        for prayerName in prayerOrder {
            guard let prayerTime = prayerTimes[prayerName] else { continue }
            guard prayerTime > Date() else { continue }
            
            let prayerSettings = settings.settings(for: prayerName)
            
            guard prayerSettings.isEnabled else { continue }
            
            let localizedPrayerName = NSLocalizedString(prayerName, comment: "")
            
            switch prayerSettings.notificationType {
            case .atPrayerTime:
                scheduleAtPrayerTime(
                    prayerName: prayerName,
                    localizedPrayerName: localizedPrayerName,
                    prayerTime: prayerTime,
                    style: prayerSettings.notificationStyle
                )
                
            case .beforePrayer:
                scheduleBeforePrayer(
                    prayerName: prayerName,
                    localizedPrayerName: localizedPrayerName,
                    prayerTime: prayerTime,
                    minutesBefore: prayerSettings.prePrayerMinutes.rawValue,
                    style: prayerSettings.notificationStyle
                )
                
            case .both:
                scheduleAtPrayerTime(
                    prayerName: prayerName,
                    localizedPrayerName: localizedPrayerName,
                    prayerTime: prayerTime,
                    style: prayerSettings.notificationStyle
                )
                scheduleBeforePrayer(
                    prayerName: prayerName,
                    localizedPrayerName: localizedPrayerName,
                    prayerTime: prayerTime,
                    minutesBefore: prayerSettings.prePrayerMinutes.rawValue,
                    style: prayerSettings.notificationStyle
                )
            }
        }
    }
    
    private static func scheduleAtPrayerTime(
        prayerName: String,
        localizedPrayerName: String,
        prayerTime: Date,
        style: NotificationStyle
    ) {
        if style == .system || style == .both {
            let content = UNMutableNotificationContent()
            content.title = localizedPrayerName
            content.body = String(format: NSLocalizedString("It's time for the %@ prayer.", comment: ""), localizedPrayerName)
            content.sound = .default
            content.userInfo = ["prayerName": prayerName, "isPreNotification": false]
            
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: prayerTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: "\(prayerName)_at", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
        
        if style == .fullScreen || style == .both {
            scheduleFullScreenNotification(
                prayerName: prayerName,
                prayerTime: prayerTime,
                isPreNotification: false,
                minutesBefore: nil
            )
        }
    }
    
    private static func scheduleBeforePrayer(
        prayerName: String,
        localizedPrayerName: String,
        prayerTime: Date,
        minutesBefore: Int,
        style: NotificationStyle
    ) {
        guard let preTime = Calendar.current.date(byAdding: .minute, value: -minutesBefore, to: prayerTime) else { return }
        guard preTime > Date() else { return }
        
        if style == .system || style == .both {
            let content = UNMutableNotificationContent()
            content.title = localizedPrayerName
            content.body = String(format: NSLocalizedString("prayer_in_minutes_notification", comment: ""), minutesBefore)
            content.sound = .default
            content.userInfo = ["prayerName": prayerName, "isPreNotification": true, "minutesBefore": minutesBefore]
            
            let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: preTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
            let request = UNNotificationRequest(identifier: "\(prayerName)_pre_\(minutesBefore)", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
        
        if style == .fullScreen || style == .both {
            scheduleFullScreenNotification(
                prayerName: prayerName,
                prayerTime: preTime,
                isPreNotification: true,
                minutesBefore: minutesBefore
            )
        }
    }
    
    private static func scheduleFullScreenNotification(
        prayerName: String,
        prayerTime: Date,
        isPreNotification: Bool,
        minutesBefore: Int?
    ) {
        let userInfo: [String: Any] = [
            "prayerName": prayerName,
            "prayerTime": prayerTime,
            "isPreNotification": isPreNotification,
            "minutesBefore": minutesBefore ?? 0,
            "isFullScreen": true
        ]
        
        let content = UNMutableNotificationContent()
        content.title = "FullScreenAlert"
        content.body = prayerName
        content.sound = .none
        content.userInfo = userInfo
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: prayerTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: "\(prayerName)_fullscreen_\(isPreNotification ? "pre" : "at")", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    static func handleFullScreenNotification(userInfo: [AnyHashable: Any]) {
        guard let isFullScreen = userInfo["isFullScreen"] as? Bool, isFullScreen else { return }
        guard let prayerName = userInfo["prayerName"] as? String else { return }
        guard let prayerTime = userInfo["prayerTime"] as? Date else { return }
        let isPreNotification = userInfo["isPreNotification"] as? Bool ?? false
        let minutesBefore = userInfo["minutesBefore"] as? Int
        
        FullScreenNotificationManager.shared.showFullScreenNotification(
            prayerName: NSLocalizedString(prayerName, comment: ""),
            prayerTime: prayerTime,
            isPreNotification: isPreNotification,
            minutesBefore: minutesBefore
        )
    }
    
    static func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    static func getScheduledNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}
