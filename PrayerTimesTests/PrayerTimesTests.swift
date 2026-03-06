import XCTest
import UserNotifications
@testable import PrayerTimes

final class PrayerTimesTests: XCTestCase {
    
    var notificationSettings: NotificationSettings!
    
    override func setUpWithError() throws {
        notificationSettings = NotificationSettings()
    }
    
    override func tearDownWithError() throws {
        notificationSettings = nil
    }
    
    // MARK: - NotificationTiming Tests
    
    func testNotificationTimingRawValues() {
        XCTAssertEqual(NotificationTiming.minutes_1.rawValue, 1)
        XCTAssertEqual(NotificationTiming.minutes_5.rawValue, 5)
        XCTAssertEqual(NotificationTiming.minutes_10.rawValue, 10)
        XCTAssertEqual(NotificationTiming.minutes_20.rawValue, 20)
        XCTAssertEqual(NotificationTiming.minutes_25.rawValue, 25)
        XCTAssertEqual(NotificationTiming.minutes_30.rawValue, 30)
    }
    
    func testNotificationTimingOrder() {
        let timings = NotificationTiming.allCases
        XCTAssertEqual(timings.count, 6)
        XCTAssertEqual(timings[0], .minutes_1)
        XCTAssertEqual(timings[5], .minutes_30)
    }
    
    // MARK: - NotificationStyle Tests
    
    func testNotificationStyleRawValues() {
        XCTAssertEqual(NotificationStyle.system.rawValue, "system")
        XCTAssertEqual(NotificationStyle.fullScreen.rawValue, "full_screen")
        XCTAssertEqual(NotificationStyle.both.rawValue, "both")
    }
    
    func testNotificationStyleCount() {
        XCTAssertEqual(NotificationStyle.allCases.count, 3)
    }
    
    // MARK: - NotificationType Tests
    
    func testNotificationTypeRawValues() {
        XCTAssertEqual(NotificationType.atPrayerTime.rawValue, "at_prayer_time")
        XCTAssertEqual(NotificationType.beforePrayer.rawValue, "before_prayer")
        XCTAssertEqual(NotificationType.both.rawValue, "both")
    }
    
    func testNotificationTypeCount() {
        XCTAssertEqual(NotificationType.allCases.count, 3)
    }
    
    // MARK: - PrayerNotificationSettings Tests
    
    func testPrayerNotificationSettingsDefaultValues() {
        let settings = PrayerNotificationSettings.default
        XCTAssertTrue(settings.isEnabled)
        XCTAssertEqual(settings.notificationType, .both)
        XCTAssertEqual(settings.notificationStyle, .system)
        XCTAssertEqual(settings.prePrayerMinutes, .minutes_10)
    }
    
    func testPrayerNotificationSettingsDisabledValues() {
        let settings = PrayerNotificationSettings.disabled
        XCTAssertFalse(settings.isEnabled)
        XCTAssertEqual(settings.notificationType, .atPrayerTime)
        XCTAssertEqual(settings.notificationStyle, .system)
        XCTAssertEqual(settings.prePrayerMinutes, .minutes_10)
    }
    
    func testPrayerNotificationSettingsEquality() {
        let settings1 = PrayerNotificationSettings(isEnabled: true, notificationType: .both, notificationStyle: .system, prePrayerMinutes: .minutes_10)
        let settings2 = PrayerNotificationSettings(isEnabled: true, notificationType: .both, notificationStyle: .system, prePrayerMinutes: .minutes_10)
        XCTAssertEqual(settings1, settings2)
    }
    
    func testPrayerNotificationSettingsInequality() {
        let settings1 = PrayerNotificationSettings(isEnabled: true, notificationType: .both, notificationStyle: .system, prePrayerMinutes: .minutes_10)
        let settings2 = PrayerNotificationSettings(isEnabled: false, notificationType: .both, notificationStyle: .system, prePrayerMinutes: .minutes_10)
        XCTAssertNotEqual(settings1, settings2)
    }
    
    // MARK: - NotificationSettings Tests
    
    func testNotificationSettingsDefaultValues() {
        let settings = NotificationSettings()
        XCTAssertTrue(settings.prayerNotificationsEnabled)
        XCTAssertTrue(settings.fajrNotification.isEnabled)
        XCTAssertTrue(settings.dhuhrNotification.isEnabled)
        XCTAssertTrue(settings.asrNotification.isEnabled)
        XCTAssertTrue(settings.maghribNotification.isEnabled)
        XCTAssertTrue(settings.ishaNotification.isEnabled)
        XCTAssertFalse(settings.sunriseNotification.isEnabled)
    }
    
    func testNotificationSettingsSettingsForPrayer() {
        let settings = NotificationSettings()
        XCTAssertNotNil(settings.settings(for: "Fajr"))
        XCTAssertNotNil(settings.settings(for: "Dhuhr"))
        XCTAssertNotNil(settings.settings(for: "Asr"))
        XCTAssertNotNil(settings.settings(for: "Maghrib"))
        XCTAssertNotNil(settings.settings(for: "Isha"))
        XCTAssertNotNil(settings.settings(for: "Sunrise"))
    }
    
    func testNotificationSettingsUpdateForPrayer() {
        let settings = NotificationSettings()
        let newFajrSettings = PrayerNotificationSettings(isEnabled: false, notificationType: .atPrayerTime, notificationStyle: .fullScreen, prePrayerMinutes: .minutes_20)
        
        settings.updateSettings(for: "Fajr", settings: newFajrSettings)
        
        XCTAssertEqual(settings.settings(for: "Fajr").isEnabled, false)
        XCTAssertEqual(settings.settings(for: "Fajr").notificationStyle, .fullScreen)
        XCTAssertEqual(settings.settings(for: "Fajr").prePrayerMinutes, .minutes_20)
    }
    
    func testNotificationSettingsCodable() {
        let settings = NotificationSettings()
        settings.fajrNotification = PrayerNotificationSettings(isEnabled: false, notificationType: .beforePrayer, notificationStyle: .fullScreen, prePrayerMinutes: .minutes_20)
        settings.prayerNotificationsEnabled = false
        
        do {
            let encoded = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(NotificationSettings.self, from: encoded)
            
            XCTAssertEqual(decoded.prayerNotificationsEnabled, false)
            XCTAssertEqual(decoded.fajrNotification.isEnabled, false)
            XCTAssertEqual(decoded.fajrNotification.notificationType, .beforePrayer)
            XCTAssertEqual(decoded.fajrNotification.notificationStyle, .fullScreen)
            XCTAssertEqual(decoded.fajrNotification.prePrayerMinutes, .minutes_20)
        } catch {
            XCTFail("Codable failed: \(error)")
        }
    }
    
    // MARK: - PrayerNotificationSettings Codable Tests
    
    func testPrayerNotificationSettingsCodable() {
        let settings = PrayerNotificationSettings(
            isEnabled: false,
            notificationType: .beforePrayer,
            notificationStyle: .fullScreen,
            prePrayerMinutes: .minutes_25
        )
        
        do {
            let encoded = try JSONEncoder().encode(settings)
            let decoded = try JSONDecoder().decode(PrayerNotificationSettings.self, from: encoded)
            
            XCTAssertEqual(decoded.isEnabled, false)
            XCTAssertEqual(decoded.notificationType, .beforePrayer)
            XCTAssertEqual(decoded.notificationStyle, .fullScreen)
            XCTAssertEqual(decoded.prePrayerMinutes, .minutes_25)
        } catch {
            XCTFail("Codable failed: \(error)")
        }
    }
    
    // MARK: - NotificationTiming Codable Tests
    
    func testNotificationTimingCodable() {
        let timing = NotificationTiming.minutes_20
        
        do {
            let encoded = try JSONEncoder().encode(timing)
            let decoded = try JSONDecoder().decode(NotificationTiming.self, from: encoded)
            
            XCTAssertEqual(decoded, .minutes_20)
            XCTAssertEqual(decoded.rawValue, 20)
        } catch {
            XCTFail("Codable failed: \(error)")
        }
    }
    
    // MARK: - NotificationStyle Codable Tests
    
    func testNotificationStyleCodable() {
        let style = NotificationStyle.fullScreen
        
        do {
            let encoded = try JSONEncoder().encode(style)
            let decoded = try JSONDecoder().decode(NotificationStyle.self, from: encoded)
            
            XCTAssertEqual(decoded, .fullScreen)
            XCTAssertEqual(decoded.rawValue, "full_screen")
        } catch {
            XCTFail("Codable failed: \(error)")
        }
    }
    
    // MARK: - NotificationType Codable Tests
    
    func testNotificationTypeCodable() {
        let type = NotificationType.beforePrayer
        
        do {
            let encoded = try JSONEncoder().encode(type)
            let decoded = try JSONDecoder().decode(NotificationType.self, from: encoded)
            
            XCTAssertEqual(decoded, .beforePrayer)
            XCTAssertEqual(decoded.rawValue, "before_prayer")
        } catch {
            XCTFail("Codable failed: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testFullSettingsWorkflow() {
        let settings = NotificationSettings()
        
        // Initially all prayer notifications should be enabled except Sunrise
        XCTAssertTrue(settings.fajrNotification.isEnabled)
        XCTAssertTrue(settings.dhuhrNotification.isEnabled)
        XCTAssertTrue(settings.asrNotification.isEnabled)
        XCTAssertTrue(settings.maghribNotification.isEnabled)
        XCTAssertTrue(settings.ishaNotification.isEnabled)
        XCTAssertFalse(settings.sunriseNotification.isEnabled)
        
        // Update Fajr to use full-screen alerts with 20-minute pre-warning
        let fajrSettings = PrayerNotificationSettings(
            isEnabled: true,
            notificationType: .both,
            notificationStyle: .fullScreen,
            prePrayerMinutes: .minutes_20
        )
        settings.updateSettings(for: "Fajr", settings: fajrSettings)
        
        XCTAssertEqual(settings.fajrNotification.notificationStyle, .fullScreen)
        XCTAssertEqual(settings.fajrNotification.prePrayerMinutes, .minutes_20)
        XCTAssertEqual(settings.fajrNotification.notificationType, .both)
        
        // Disable Dhuhr notifications
        settings.updateSettings(for: "Dhuhr", settings: PrayerNotificationSettings.disabled)
        XCTAssertFalse(settings.dhuhrNotification.isEnabled)
        
        // Save and verify persistence
        settings.save()
        
        // Create new instance which should load from UserDefaults
        let loadedSettings = NotificationSettings()
        XCTAssertTrue(loadedSettings.fajrNotification.isEnabled)
        XCTAssertEqual(loadedSettings.fajrNotification.notificationStyle, .fullScreen)
        XCTAssertFalse(loadedSettings.dhuhrNotification.isEnabled)
    }
    
    func testPrePrayerMinutesCalculation() {
        let calendar = Calendar.current
        let now = Date()
        guard let prayerTime = calendar.date(byAdding: .hour, value: 1, to: now) else {
            XCTFail("Could not create test date")
            return
        }
        
        for timing in NotificationTiming.allCases {
            guard let preTime = calendar.date(byAdding: .minute, value: -timing.rawValue, to: prayerTime) else {
                XCTFail("Could not calculate pre-time for \(timing)")
                continue
            }
            
            let difference = calendar.dateComponents([.minute], from: preTime, to: prayerTime).minute ?? 0
            XCTAssertEqual(difference, timing.rawValue, "Pre-prayer time should be \(timing.rawValue) minutes before")
        }
    }
}
