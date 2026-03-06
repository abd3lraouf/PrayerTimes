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
    
    static func scheduleNotifications(for prayerTimes: [String: Date], prayerOrder: [String], adhanSound: AdhanSound, customSoundPath: String) {
        cancelNotifications()
        
        for prayerName in prayerOrder {
            guard let prayerTime = prayerTimes[prayerName] else { continue }
            
            if prayerTime > Date() {
                let content = UNMutableNotificationContent()
                let localizedPrayerName = NSLocalizedString(prayerName, comment: "")
                content.title = localizedPrayerName
                content.body = String(format: NSLocalizedString("It's time for the %@ prayer.", comment: ""), localizedPrayerName)
                
                switch adhanSound {
                case .none:
                    content.sound = nil
                case .defaultBeep:
                    content.sound = UNNotificationSound.default
                case .custom:
                    content.sound = nil
                }

                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: prayerTime)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                let request = UNNotificationRequest(identifier: prayerName, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    static func cancelNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
