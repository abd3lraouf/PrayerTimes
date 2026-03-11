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
        return String(format: format, LanguageManager.formatNumberStatic(rawValue))
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

struct PrayerNotificationSettings: Equatable {
    var useGlobalSettings: Bool = true
    var isEnabled: Bool = true
    var notificationType: NotificationType = .both
    var systemNotificationEnabled: Bool = true
    var fullScreenNotificationEnabled: Bool = false
    var prePrayerMinutes: NotificationTiming = .minutes_10

    static let `default` = PrayerNotificationSettings()
    static let disabled = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: false, notificationType: .atPrayerTime, systemNotificationEnabled: true, fullScreenNotificationEnabled: false, prePrayerMinutes: .minutes_10)
}

extension PrayerNotificationSettings: Codable {
    enum CodingKeys: String, CodingKey {
        case useGlobalSettings, isEnabled, notificationType
        case systemNotificationEnabled, fullScreenNotificationEnabled
        case prePrayerMinutes
        // Legacy key for migration
        case notificationStyle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        useGlobalSettings = try container.decodeIfPresent(Bool.self, forKey: .useGlobalSettings) ?? true
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        notificationType = try container.decodeIfPresent(NotificationType.self, forKey: .notificationType) ?? .both
        prePrayerMinutes = try container.decodeIfPresent(NotificationTiming.self, forKey: .prePrayerMinutes) ?? .minutes_10

        // Try new fields first, fall back to legacy notificationStyle
        if let system = try container.decodeIfPresent(Bool.self, forKey: .systemNotificationEnabled),
           let fullScreen = try container.decodeIfPresent(Bool.self, forKey: .fullScreenNotificationEnabled) {
            systemNotificationEnabled = system
            fullScreenNotificationEnabled = fullScreen
        } else if let legacyStyle = try container.decodeIfPresent(String.self, forKey: .notificationStyle) {
            switch legacyStyle {
            case "system":
                systemNotificationEnabled = true
                fullScreenNotificationEnabled = false
            case "full_screen":
                systemNotificationEnabled = false
                fullScreenNotificationEnabled = true
            case "both":
                systemNotificationEnabled = true
                fullScreenNotificationEnabled = true
            default:
                systemNotificationEnabled = true
                fullScreenNotificationEnabled = false
            }
        } else {
            systemNotificationEnabled = true
            fullScreenNotificationEnabled = false
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(useGlobalSettings, forKey: .useGlobalSettings)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(notificationType, forKey: .notificationType)
        try container.encode(systemNotificationEnabled, forKey: .systemNotificationEnabled)
        try container.encode(fullScreenNotificationEnabled, forKey: .fullScreenNotificationEnabled)
        try container.encode(prePrayerMinutes, forKey: .prePrayerMinutes)
    }
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
                systemNotificationEnabled: globalSettings.systemNotificationEnabled,
                fullScreenNotificationEnabled: globalSettings.fullScreenNotificationEnabled,
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
        let g = globalSettings
        fajrNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: g.notificationType, systemNotificationEnabled: g.systemNotificationEnabled, fullScreenNotificationEnabled: g.fullScreenNotificationEnabled, prePrayerMinutes: g.prePrayerMinutes)
        dhuhrNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: g.notificationType, systemNotificationEnabled: g.systemNotificationEnabled, fullScreenNotificationEnabled: g.fullScreenNotificationEnabled, prePrayerMinutes: g.prePrayerMinutes)
        asrNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: g.notificationType, systemNotificationEnabled: g.systemNotificationEnabled, fullScreenNotificationEnabled: g.fullScreenNotificationEnabled, prePrayerMinutes: g.prePrayerMinutes)
        maghribNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: g.notificationType, systemNotificationEnabled: g.systemNotificationEnabled, fullScreenNotificationEnabled: g.fullScreenNotificationEnabled, prePrayerMinutes: g.prePrayerMinutes)
        ishaNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: true, notificationType: g.notificationType, systemNotificationEnabled: g.systemNotificationEnabled, fullScreenNotificationEnabled: g.fullScreenNotificationEnabled, prePrayerMinutes: g.prePrayerMinutes)
        sunriseNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: false, notificationType: g.notificationType, systemNotificationEnabled: g.systemNotificationEnabled, fullScreenNotificationEnabled: g.fullScreenNotificationEnabled, prePrayerMinutes: g.prePrayerMinutes)
        tahajudNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: false, notificationType: g.notificationType, systemNotificationEnabled: g.systemNotificationEnabled, fullScreenNotificationEnabled: g.fullScreenNotificationEnabled, prePrayerMinutes: g.prePrayerMinutes)
        dhuhaNotification = PrayerNotificationSettings(useGlobalSettings: true, isEnabled: false, notificationType: g.notificationType, systemNotificationEnabled: g.systemNotificationEnabled, fullScreenNotificationEnabled: g.fullScreenNotificationEnabled, prePrayerMinutes: g.prePrayerMinutes)
        save()
    }
}
