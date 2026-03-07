// MARK: - PrayerTimes/PrayerTimesCalculationMethod.swift

import Foundation
import Adhan

struct PrayerTimesCalculationMethod: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let params: CalculationParameters

    var localizedName: String {
        NSLocalizedString("calc_method_\(name)", comment: "Calculation method: \(name)")
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }

    static func == (lhs: PrayerTimesCalculationMethod, rhs: PrayerTimesCalculationMethod) -> Bool {
        lhs.name == rhs.name
    }

    static var allCases: [PrayerTimesCalculationMethod] {
        // --- Custom Parameters ---

        // Algerian Ministry of Religious Affairs: Fajr 18°, Isha 17°
        var algeria = CalculationMethod.other.params
        algeria.fajrAngle = 18.0
        algeria.ishaAngle = 17.0
        algeria.adjustments = PrayerAdjustments(dhuhr: 1)

        // UOIF (Union des Organisations Islamiques de France): 12° angles
        var france12 = CalculationMethod.other.params
        france12.fajrAngle = 12.0
        france12.ishaAngle = 12.0

        // Grand Mosque of Paris: 18° angles
        var france18 = CalculationMethod.other.params
        france18.fajrAngle = 18.0
        france18.ishaAngle = 18.0
        france18.adjustments = PrayerAdjustments(dhuhr: 1)

        // IGMG / German Islamic organizations: Fajr 18°, Isha 16.5°
        var germany = CalculationMethod.other.params
        germany.fajrAngle = 18.0
        germany.ishaAngle = 16.5
        germany.adjustments = PrayerAdjustments(dhuhr: 1)

        // JAKIM (Jabatan Kemajuan Islam Malaysia): Fajr 20°, Isha 18°
        var malaysia = CalculationMethod.other.params
        malaysia.fajrAngle = 20.0
        malaysia.ishaAngle = 18.0
        malaysia.adjustments = PrayerAdjustments(dhuhr: 1)
        malaysia.rounding = .up

        // Kemenag (Kementerian Agama Indonesia): Fajr 20°, Isha 18°
        var indonesia = CalculationMethod.other.params
        indonesia.fajrAngle = 20.0
        indonesia.ishaAngle = 18.0
        indonesia.adjustments = PrayerAdjustments(dhuhr: 1)
        indonesia.rounding = .up

        // Spiritual Administration of Muslims of Russia: Fajr 16°, Isha 15°
        var russia = CalculationMethod.other.params
        russia.fajrAngle = 16.0
        russia.ishaAngle = 15.0

        // Tunisian Ministry of Religious Affairs: Fajr 18°, Isha 18°
        var tunisia = CalculationMethod.other.params
        tunisia.fajrAngle = 18.0
        tunisia.ishaAngle = 18.0
        tunisia.adjustments = PrayerAdjustments(dhuhr: 1)

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
            PrayerTimesCalculationMethod(name: "Diyanet (Turkey)", params: CalculationMethod.turkey.params),

            // --- Custom Methods ---
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

    static func recommendedMethod(forCountryCode code: String) -> PrayerTimesCalculationMethod {
        let name: String
        switch code.uppercased() {
        case "SA", "YE", "BH", "OM":
            name = "Umm al-Qura University, Makkah"
        case "EG", "LY", "SD", "SS":
            name = "Egyptian General Authority"
        case "TR":
            name = "Diyanet (Turkey)"
        case "AE":
            name = "Dubai"
        case "QA":
            name = "Qatar"
        case "KW":
            name = "Kuwait"
        case "JO", "PS", "IQ", "SY", "LB":
            name = "Muslim World League"
        case "SG":
            name = "Singapore"
        case "MY", "BN":
            name = "Malaysia (JAKIM)"
        case "ID":
            name = "Indonesia (Kemenag)"
        case "IR":
            name = "Tehran"
        case "PK", "BD", "AF", "IN", "LK":
            name = "University of Islamic Sciences, Karachi"
        case "DZ":
            name = "Algeria"
        case "TN":
            name = "Tunisia"
        case "MA", "MR":
            name = "Muslim World League"
        case "RU":
            name = "Russia"
        case "DE", "AT", "CH":
            name = "Germany"
        case "FR":
            name = "France (18°)"
        case "GB", "IE":
            name = "Moonsighting Committee"
        case "US", "CA":
            name = "ISNA (North America)"
        default:
            name = "Muslim World League"
        }
        return allCases.first { $0.name == name } ?? allCases.first { $0.name == "Muslim World League" }!
    }
}
