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
            return NSLocalizedString("System", comment: "")
        case .fullScreen:
            return NSLocalizedString("Full Screen", comment: "")
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
            return NSLocalizedString("At Time", comment: "")
        case .beforePrayer:
            return NSLocalizedString("Before", comment: "")
        case .both:
            return NSLocalizedString("At & Before", comment: "")
        }
    }
}

struct PrayerNotificationSettings: Codable, Equatable {
    var useGlobalSettings: Bool = true
    var isEnabled: Bool = true
    var notificationType: NotificationType = .both
    var notificationStyle: NotificationStyle = .system
    var prePrayerMinutes: NotificationTiming = .minutes_10
    
    static let `default` = PrayerNotificationSettings()
    static let disabled = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: false, notificationType: .atPrayerTime, notificationStyle: .system, prePrayerMinutes: .minutes_10)
}

class NotificationSettings: ObservableObject, Codable {
    @Published var prayerNotificationsEnabled: Bool = true
    
    // Global settings that apply to all prayers (when useGlobalSettings is true)
    @Published var globalSettings: PrayerNotificationSettings = .default
    
    @Published var fajrNotification: PrayerNotificationSettings = .default
    @Published var dhuhrNotification: PrayerNotificationSettings = .default
    @Published var asrNotification: PrayerNotificationSettings = .default
    @Published var maghribNotification: PrayerNotificationSettings = .default
    @Published var ishaNotification: PrayerNotificationSettings = .default
    @Published var sunriseNotification: PrayerNotificationSettings = .disabled
    @Published var tahajudNotification: PrayerNotificationSettings = .disabled
    @Published var dhuhaNotification: PrayerNotificationSettings = .disabled

    enum CodingKeys: String, CodingKey {
        case prayerNotificationsEnabled
        case globalSettings
        case fajrNotification
        case dhuhrNotification
        case asrNotification
        case maghribNotification
        case ishaNotification
        case sunriseNotification
        case tahajudNotification
        case dhuhaNotification
    }
    
    init() {
        if let data = UserDefaults.standard.data(forKey: StorageKeys.notificationSettings),
           let decoded = try? JSONDecoder().decode(NotificationSettings.self, from: data) {
            self.prayerNotificationsEnabled = decoded.prayerNotificationsEnabled
            self.globalSettings = decoded.globalSettings
            self.fajrNotification = decoded.fajrNotification
            self.dhuhrNotification = decoded.dhuhrNotification
            self.asrNotification = decoded.asrNotification
            self.maghribNotification = decoded.maghribNotification
            self.ishaNotification = decoded.ishaNotification
            self.sunriseNotification = decoded.sunriseNotification
            self.tahajudNotification = decoded.tahajudNotification
            self.dhuhaNotification = decoded.dhuhaNotification
        }
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        prayerNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .prayerNotificationsEnabled) ?? true
        globalSettings = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .globalSettings) ?? .default
        fajrNotification = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .fajrNotification) ?? .default
        dhuhrNotification = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .dhuhrNotification) ?? .default
        asrNotification = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .asrNotification) ?? .default
        maghribNotification = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .maghribNotification) ?? .default
        ishaNotification = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .ishaNotification) ?? .default
        sunriseNotification = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .sunriseNotification) ?? .disabled
        tahajudNotification = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .tahajudNotification) ?? .disabled
        dhuhaNotification = try container.decodeIfPresent(PrayerNotificationSettings.self, forKey: .dhuhaNotification) ?? .disabled
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(prayerNotificationsEnabled, forKey: .prayerNotificationsEnabled)
        try container.encode(globalSettings, forKey: .globalSettings)
        try container.encode(fajrNotification, forKey: .fajrNotification)
        try container.encode(dhuhrNotification, forKey: .dhuhrNotification)
        try container.encode(asrNotification, forKey: .asrNotification)
        try container.encode(maghribNotification, forKey: .maghribNotification)
        try container.encode(ishaNotification, forKey: .ishaNotification)
        try container.encode(sunriseNotification, forKey: .sunriseNotification)
        try container.encode(tahajudNotification, forKey: .tahajudNotification)
        try container.encode(dhuhaNotification, forKey: .dhuhaNotification)
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: StorageKeys.notificationSettings)
    }
    
    func settings(for prayer: String) -> PrayerNotificationSettings {
        switch prayer {
        case "Fajr": return fajrNotification
        case "Dhuhr": return dhuhrNotification
        case "Asr": return asrNotification
        case "Maghrib": return maghribNotification
        case "Isha": return ishaNotification
        case "Sunrise": return sunriseNotification
        case "Tahajud": return tahajudNotification
        case "Dhuha": return dhuhaNotification
        default: return .default
        }
    }
    
    func effectiveSettings(for prayer: String) -> PrayerNotificationSettings {
        let prayerSettings = settings(for: prayer)
        
        if prayerSettings.useGlobalSettings {
            return PrayerNotificationSettings(
                useGlobalSettings: true,
                isEnabled: prayerSettings.isEnabled,
                notificationType: globalSettings.notificationType,
                notificationStyle: globalSettings.notificationStyle,
                prePrayerMinutes: globalSettings.prePrayerMinutes
            )
        } else {
            return prayerSettings
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
        case "Tahajud": tahajudNotification = settings
        case "Dhuha": dhuhaNotification = settings
        default: break
        }
        save()
    }
    
    func applyGlobalToAll() {
        fajrNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: globalSettings.notificationType, notificationStyle: globalSettings.notificationStyle, prePrayerMinutes: globalSettings.prePrayerMinutes)
        dhuhrNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: globalSettings.notificationType, notificationStyle: globalSettings.notificationStyle, prePrayerMinutes: globalSettings.prePrayerMinutes)
        asrNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: globalSettings.notificationType, notificationStyle: globalSettings.notificationStyle, prePrayerMinutes: globalSettings.prePrayerMinutes)
        maghribNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: globalSettings.notificationType, notificationStyle: globalSettings.notificationStyle, prePrayerMinutes: globalSettings.prePrayerMinutes)
        ishaNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: globalSettings.notificationType, notificationStyle: globalSettings.notificationStyle, prePrayerMinutes: globalSettings.prePrayerMinutes)
        sunriseNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: false, notificationType: globalSettings.notificationType, notificationStyle: globalSettings.notificationStyle, prePrayerMinutes: globalSettings.prePrayerMinutes)
        tahajudNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: false, notificationType: globalSettings.notificationType, notificationStyle: globalSettings.notificationStyle, prePrayerMinutes: globalSettings.prePrayerMinutes)
        dhuhaNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: false, notificationType: globalSettings.notificationType, notificationStyle: globalSettings.notificationStyle, prePrayerMinutes: globalSettings.prePrayerMinutes)
        save()
    }
}
