import Foundation
import Combine

class FastingModeManager: ObservableObject {
    @Published var isFastingModeEnabled: Bool {
        didSet { UserDefaults.standard.set(isFastingModeEnabled, forKey: StorageKeys.fastingModeEnabled) }
    }

    var currentFastingDay: Int? {
        guard isFastingModeEnabled else { return nil }
        return HijriCalendarManager.currentRamadanDay()
    }

    var totalFastingDays: Int {
        HijriCalendarManager.daysInCurrentRamadan()
    }

    var isLastTenNights: Bool {
        guard let day = currentFastingDay else { return false }
        return day >= 21
    }

    init() {
        self.isFastingModeEnabled = UserDefaults.standard.bool(forKey: StorageKeys.fastingModeEnabled)
    }

    func checkAndAutoEnable() {
        let isRamadan = HijriCalendarManager.isRamadan()
        if isRamadan && !isFastingModeEnabled {
            isFastingModeEnabled = true
        } else if !isRamadan && isFastingModeEnabled {
            isFastingModeEnabled = false
        }
    }

    func suhoorTime(from prayerTimes: [String: Date]) -> Date? {
        prayerTimes["Fajr"]
    }

    func iftarTime(from prayerTimes: [String: Date]) -> Date? {
        prayerTimes["Maghrib"]
    }

    func taraweehTime(from prayerTimes: [String: Date], minutesAfterIsha: Int = 30) -> Date? {
        guard let isha = prayerTimes["Isha"] else { return nil }
        return isha.addingTimeInterval(Double(minutesAfterIsha) * 60)
    }
}
