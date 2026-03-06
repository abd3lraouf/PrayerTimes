// MARK: - PrayerTimes/PrayerTimesCalculationMethod.swift

import Foundation
import Adhan

struct PrayerTimesCalculationMethod: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let params: CalculationParameters

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: PrayerTimesCalculationMethod, rhs: PrayerTimesCalculationMethod) -> Bool {
        lhs.name == rhs.name
    }

    static var allCases: [PrayerTimesCalculationMethod] {
        // --- Custom Parameters ---
        var diyanet = CalculationMethod.other.params
        diyanet.fajrAngle = 18.0
        diyanet.ishaAngle = 17.0

        var algeria = CalculationMethod.other.params
        algeria.fajrAngle = 18.0
        algeria.ishaAngle = 17.0

        var france12 = CalculationMethod.other.params
        france12.fajrAngle = 12.0
        france12.ishaAngle = 12.0

        var france18 = CalculationMethod.other.params
        france18.fajrAngle = 18.0
        france18.ishaAngle = 18.0

        var germany = CalculationMethod.other.params
        germany.fajrAngle = 18.0
        germany.ishaAngle = 16.5

        var malaysia = CalculationMethod.other.params
        malaysia.fajrAngle = 20.0
        malaysia.ishaAngle = 18.0

        var indonesia = CalculationMethod.other.params
        indonesia.fajrAngle = 20.0
        indonesia.ishaAngle = 18.0

        var russia = CalculationMethod.other.params
        russia.fajrAngle = 16.0
        russia.ishaAngle = 15.0

        var tunisia = CalculationMethod.other.params
        tunisia.fajrAngle = 18.0
        tunisia.ishaAngle = 18.0

        // --- Built-in + Custom ---
        let methods: [PrayerTimesCalculationMethod] = [
            PrayerTimesCalculationMethod(name: "Muslim World League", params: CalculationMethod.muslimWorldLeague.params),
            PrayerTimesCalculationMethod(name: "Egyptian General Authority", params: CalculationMethod.egyptian.params),
            PrayerTimesCalculationMethod(name: "University of Islamic Sciences, Karachi", params: CalculationMethod.karachi.params),
            PrayerTimesCalculationMethod(name: "Umm al-Qura University, Makkah", params: CalculationMethod.ummAlQura.params),
            PrayerTimesCalculationMethod(name: "Dubai", params: CalculationMethod.dubai.params),
            PrayerTimesCalculationMethod(name: "Moonsighting Committee", params: CalculationMethod.moonsightingCommittee.params),
            PrayerTimesCalculationMethod(name: "ISNA (North America)", params: CalculationMethod.northAmerica.params),
            PrayerTimesCalculationMethod(name: "Kuwait", params: CalculationMethod.kuwait.params),
            PrayerTimesCalculationMethod(name: "Qatar", params: CalculationMethod.qatar.params),
            PrayerTimesCalculationMethod(name: "Singapore", params: CalculationMethod.singapore.params),
            PrayerTimesCalculationMethod(name: "Tehran", params: CalculationMethod.tehran.params),

            // --- Custom Methods ---
            PrayerTimesCalculationMethod(name: "Diyanet (Turkey)", params: diyanet),
            PrayerTimesCalculationMethod(name: "Algeria", params: algeria),
            PrayerTimesCalculationMethod(name: "France (12°)", params: france12),
            PrayerTimesCalculationMethod(name: "France (18°)", params: france18),
            PrayerTimesCalculationMethod(name: "Germany", params: germany),
            PrayerTimesCalculationMethod(name: "Malaysia (JAKIM)", params: malaysia),
            PrayerTimesCalculationMethod(name: "Indonesia (Kemenag)", params: indonesia),
            PrayerTimesCalculationMethod(name: "Russia", params: russia),
            PrayerTimesCalculationMethod(name: "Tunisia", params: tunisia),
        ]
        return methods.sorted { $0.name < $1.name }
    }
}
