import Foundation

struct HijriCalendarManager {
    private static let hijriCalendar: Calendar = {
        var cal = Calendar(identifier: .islamicUmmAlQura)
        cal.locale = Locale(identifier: "en")
        return cal
    }()

    static func hijriDate(from date: Date = Date()) -> DateComponents {
        hijriCalendar.dateComponents([.year, .month, .day], from: date)
    }

    static func isRamadan(on date: Date = Date()) -> Bool {
        hijriDate(from: date).month == 9
    }

    static func currentRamadanDay(on date: Date = Date()) -> Int? {
        let components = hijriDate(from: date)
        guard components.month == 9 else { return nil }
        return components.day
    }

    static func daysInCurrentRamadan(on date: Date = Date()) -> Int {
        let components = hijriDate(from: date)
        guard components.month == 9,
              let range = hijriCalendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }
}
