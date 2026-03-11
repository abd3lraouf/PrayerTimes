import Foundation
import CoreLocation
@testable import PrayerTimes

/// Helpers for setting up test state without requiring location services or onboarding.
enum TestHelpers {

    // MARK: - Well-known test locations

    struct TestLocation {
        let name: String
        let latitude: Double
        let longitude: Double
        let timeZoneIdentifier: String

        var coordinates: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        var timeZone: TimeZone {
            TimeZone(identifier: timeZoneIdentifier) ?? .current
        }
    }

    static let mecca = TestLocation(
        name: "Mecca",
        latitude: 21.4225,
        longitude: 39.8262,
        timeZoneIdentifier: "Asia/Riyadh"
    )

    static let cairo = TestLocation(
        name: "Cairo",
        latitude: 30.0444,
        longitude: 31.2357,
        timeZoneIdentifier: "Africa/Cairo"
    )

    static let london = TestLocation(
        name: "London",
        latitude: 51.5074,
        longitude: -0.1278,
        timeZoneIdentifier: "Europe/London"
    )

    static let newYork = TestLocation(
        name: "New York",
        latitude: 40.7128,
        longitude: -74.0060,
        timeZoneIdentifier: "America/New_York"
    )

    static let kualaLumpur = TestLocation(
        name: "Kuala Lumpur",
        latitude: 3.1390,
        longitude: 101.6869,
        timeZoneIdentifier: "Asia/Kuala_Lumpur"
    )

    // MARK: - Location injection

    /// Writes a manual location into UserDefaults so that `PrayerTimeViewModel.startLocationProcess()`
    /// picks it up without needing CLLocationManager or network access.
    static func injectLocation(_ location: TestLocation) {
        let manualData: [String: Any] = [
            "name": location.name,
            "latitude": location.latitude,
            "longitude": location.longitude
        ]
        UserDefaults.standard.set(manualData, forKey: StorageKeys.manualLocationData)
        UserDefaults.standard.set(true, forKey: StorageKeys.isUsingManualLocation)
    }

    /// Writes arbitrary coordinates into UserDefaults as a manual location.
    static func injectLocation(name: String = "Test Location", latitude: Double, longitude: Double) {
        let manualData: [String: Any] = [
            "name": name,
            "latitude": latitude,
            "longitude": longitude
        ]
        UserDefaults.standard.set(manualData, forKey: StorageKeys.manualLocationData)
        UserDefaults.standard.set(true, forKey: StorageKeys.isUsingManualLocation)
    }

    // MARK: - Onboarding

    /// Disables the onboarding flag so it won't appear on next launch.
    static func skipOnboarding() {
        UserDefaults.standard.set(false, forKey: StorageKeys.showOnboardingAtLaunch)
    }

    // MARK: - Cleanup

    /// Removes all test-injected state from UserDefaults.
    static func cleanUp() {
        UserDefaults.standard.removeObject(forKey: StorageKeys.manualLocationData)
        UserDefaults.standard.removeObject(forKey: StorageKeys.isUsingManualLocation)
        UserDefaults.standard.removeObject(forKey: StorageKeys.showOnboardingAtLaunch)
        UserDefaults.standard.removeObject(forKey: StorageKeys.notificationSettings)
    }

    // MARK: - Future prayer times

    /// Creates a dictionary of prayer times set in the future, useful for notification scheduling tests.
    /// All times are offset from `now` by `startOffset` and spaced `spacing` apart.
    static func futurePrayerTimes(
        prayers: [String] = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"],
        startOffset: TimeInterval = 3600,
        spacing: TimeInterval = 3600
    ) -> [String: Date] {
        let now = Date()
        var result: [String: Date] = [:]
        for (index, prayer) in prayers.enumerated() {
            result[prayer] = now.addingTimeInterval(startOffset + Double(index) * spacing)
        }
        return result
    }
}
