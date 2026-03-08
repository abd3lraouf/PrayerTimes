import Foundation

enum HijriCalendarType: String, CaseIterable, Identifiable {
    case islamicUmmAlQura = "islamicUmmAlQura"
    case islamic = "islamic"
    case islamicCivil = "islamicCivil"

    var id: String { rawValue }

    var calendarIdentifier: Calendar.Identifier {
        switch self {
        case .islamicUmmAlQura: return .islamicUmmAlQura
        case .islamic: return .islamic
        case .islamicCivil: return .islamicCivil
        }
    }

    var localized: String {
        NSLocalizedString("hijri_type_\(rawValue)", comment: "")
    }
}

class HijriCalendarManager: ObservableObject {
    private var isInitializing = true

    @Published var selectedCalendarType: HijriCalendarType {
        didSet {
            UserDefaults.standard.set(selectedCalendarType.rawValue, forKey: StorageKeys.hijriCalendarType)
            guard !isInitializing else { return }
            NotificationManager.scheduleIslamicEventNotifications(hijriManager: self)
        }
    }

    @Published var manualDayCorrection: Int {
        didSet {
            UserDefaults.standard.set(manualDayCorrection, forKey: StorageKeys.hijriDayCorrection)
            guard !isInitializing else { return }
            NotificationManager.scheduleIslamicEventNotifications(hijriManager: self)
        }
    }

    var hijriCalendar: Calendar {
        Calendar(identifier: selectedCalendarType.calendarIdentifier)
    }

    init() {
        let typeRaw = UserDefaults.standard.string(forKey: StorageKeys.hijriCalendarType) ?? HijriCalendarType.islamicUmmAlQura.rawValue
        self.selectedCalendarType = HijriCalendarType(rawValue: typeRaw) ?? .islamicUmmAlQura
        self.manualDayCorrection = UserDefaults.standard.integer(forKey: StorageKeys.hijriDayCorrection)
        isInitializing = false
    }

    func hijriDate(from date: Date) -> DateComponents {
        let correctedDate = Calendar.current.date(byAdding: .day, value: manualDayCorrection, to: date) ?? date
        return hijriCalendar.dateComponents([.day, .month, .year], from: correctedDate)
    }

    func hijriDateString(from date: Date) -> String {
        let components = hijriDate(from: date)
        guard let day = components.day, let month = components.month, let year = components.year else { return "" }
        return "\(day) \(monthName(month: month)) \(year)"
    }

    func daysInMonth(month: Int, year: Int) -> Int {
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        guard let date = hijriCalendar.date(from: components),
              let range = hijriCalendar.range(of: .day, in: .month, for: date) else { return 30 }
        return range.count
    }

    func gregorianDate(fromHijri components: DateComponents) -> Date {
        guard let date = hijriCalendar.date(from: components) else { return Date() }
        return Calendar.current.date(byAdding: .day, value: -manualDayCorrection, to: date) ?? date
    }

    func monthName(month: Int) -> String {
        let key = "hijri_month_\(month)"
        return NSLocalizedString(key, comment: "")
    }

    func firstWeekday(month: Int, year: Int) -> Int {
        var components = DateComponents()
        components.month = month
        components.year = year
        components.day = 1
        let gregorianDate = self.gregorianDate(fromHijri: components)
        return Calendar.current.component(.weekday, from: gregorianDate)
    }
}
