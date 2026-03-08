import Foundation

struct IslamicEvent: Identifiable {
    let month: Int
    let day: Int
    let nameKey: String

    var id: String { "\(month)-\(day)-\(nameKey)" }

    var localizedName: String {
        NSLocalizedString(nameKey, comment: "")
    }
}

struct IslamicEvents {
    static let allEvents: [IslamicEvent] = [
        IslamicEvent(month: 1, day: 1, nameKey: "event_islamic_new_year"),
        IslamicEvent(month: 1, day: 10, nameKey: "event_ashura"),
        IslamicEvent(month: 3, day: 12, nameKey: "event_mawlid"),
        IslamicEvent(month: 7, day: 27, nameKey: "event_isra_miraj"),
        IslamicEvent(month: 8, day: 15, nameKey: "event_mid_shaban"),
        IslamicEvent(month: 9, day: 1, nameKey: "event_ramadan_start"),
        IslamicEvent(month: 10, day: 1, nameKey: "event_eid_fitr"),
        IslamicEvent(month: 12, day: 9, nameKey: "event_arafah"),
        IslamicEvent(month: 12, day: 10, nameKey: "event_eid_adha"),
        IslamicEvent(month: 12, day: 11, nameKey: "event_tashreeq"),
        IslamicEvent(month: 12, day: 12, nameKey: "event_tashreeq"),
        IslamicEvent(month: 12, day: 13, nameKey: "event_tashreeq"),
    ]

    static func events(forMonth month: Int) -> [IslamicEvent] {
        allEvents.filter { $0.month == month }
    }

    static func events(forMonth month: Int, day: Int) -> [IslamicEvent] {
        allEvents.filter { $0.month == month && $0.day == day }
    }
}
