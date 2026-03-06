import Foundation
import Combine

enum NotificationTiming: Int, CaseIterable, Identifiable, Codable {
    case minutes_1 = 1
    case minutes_5 = 5
    case minutes_10 = 10
    case minutes_20 = 20
    case minutes_25 = 25
    case minutes_30 = 30
    
    var id: Int { rawValue }
    
    var localized: String {
        let format = NSLocalizedString("minutes_before", comment: "")
        return String(format: format, rawValue)
    }
}

enum NotificationStyle: String, CaseIterable, Identifiable, Codable {
    case system = "system"
    case fullScreen = "full_screen"
    case both = "both"
    
    var id: String { rawValue }
    
    var localized: String {
        switch self {
        case .system:
            return NSLocalizedString("System Notification", comment: "")
        case .fullScreen:
            return NSLocalizedString("Full Screen Alert", comment: "")
        case .both:
            return NSLocalizedString("Both", comment: "")
        }
    }
}

enum NotificationType: String, CaseIterable, Identifiable, Codable {
    case atPrayerTime = "at_prayer_time"
    case beforePrayer = "before_prayer"
    case both = "both"
    
    var id: String { rawValue }
    
    var localized: String {
        switch self {
        case .atPrayerTime:
            return NSLocalizedString("At Prayer Time", comment: "")
        case .beforePrayer:
            return NSLocalizedString("Before Prayer", comment: "")
        case .both:
            return NSLocalizedString("At Prayer Time & Before", comment: "")
        }
    }
}

struct PrayerNotificationSettings: Codable, Equatable {
    var isEnabled: Bool = true
    var notificationType: NotificationType = .both
    var notificationStyle: NotificationStyle = .system
    var prePrayerMinutes: NotificationTiming = .minutes_10
    
    static let `default` = PrayerNotificationSettings()
    static let disabled = PrayerNotificationSettings(isEnabled: false, notificationType: .atPrayerTime, notificationStyle: .system, prePrayerMinutes: .minutes_10)
}

class NotificationSettings: ObservableObject, Codable {
    @Published var prayerNotificationsEnabled: Bool = true
    @Published var fajrNotification: PrayerNotificationSettings = .default
    @Published var dhuhrNotification: PrayerNotificationSettings = .default
    @Published var asrNotification: PrayerNotificationSettings = .default
    @Published var maghribNotification: PrayerNotificationSettings = .default
    @Published var ishaNotification: PrayerNotificationSettings = .default
    @Published var sunriseNotification: PrayerNotificationSettings = .disabled
    
    enum CodingKeys: String, CodingKey {
        case prayerNotificationsEnabled
        case fajrNotification
        case dhuhrNotification
        case asrNotification
        case maghribNotification
        case ishaNotification
        case sunriseNotification
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: "notificationSettings"),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.prayerNotificationsEnabled = decoded.prayerNotificationsEnabled
            self.fajrNotification = decoded.fajrNotification
            self.dhuhrNotification = decoded.dhuhrNotification
            self.asrNotification = decoded.asrNotification
            self.maghribNotification = decoded.maghribNotification
            self.ishaNotification = decoded.ishaNotification
            self.sunriseNotification = decoded.sunriseNotification
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        prayerNotificationsEnabled = try container.decode(Bool.self, forKey: .prayerNotificationsEnabled)
        fajrNotification = try container.decode(PrayerNotificationSettings.self, forKey: .fajrNotification)
        dhuhrNotification = try container.decode(PrayerNotificationSettings.self, forKey: .dhuhrNotification)
        asrNotification = try container.decode(PrayerNotificationSettings.self, forKey: .asrNotification)
        maghribNotification = try container.decode(PrayerNotificationSettings.self, forKey: .maghribNotification)
        ishaNotification = try container.decode(PrayerNotificationSettings.self, forKey: .ishaNotification)
        sunriseNotification = try container.decode(PrayerNotificationSettings.self, forKey: .sunriseNotification)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(prayerNotificationsEnabled, forKey: .prayerNotificationsEnabled)
        try container.encode(fajrNotification, forKey: .fajrNotification)
        try container.encode(dhuhrNotification, forKey: .dhuhrNotification)
        try container.encode(asrNotification, forKey: .asrNotification)
        try container.encode(maghribNotification, forKey: .maghribNotification)
        try container.encode(ishaNotification, forKey: .ishaNotification)
        try container.encode(sunriseNotification, forKey: .sunriseNotification)
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: "notificationSettings")
    }
    
    func settings(for prayer: String) -> PrayerNotificationSettings {
        switch prayer {
        case "Fajr": return fajrNotification
        case "Dhuhr": return dhuhrNotification
        case "Asr": return asrNotification
        case "Maghrib": return maghribNotification
        case "Isha": return ishaNotification
        case "Sunrise": return sunriseNotification
        default: return .default
        }
    }
    
    func updateSettings(for prayer: String, settings: PrayerNotificationSettings) {
        switch prayer {
        case "Fajr": fajrNotification = settings
        case "Dhuhr": dhuhrNotification = settings
        case "Asr": asrNotification = settings
        case "Maghrib": maghribNotification = settings
        case "Isha": ishaNotification = settings
        case "Sunrise": sunriseNotification = settings
        default: break
        }
        save()
    }
}
