import Foundation

enum AdhanSound: String, CaseIterable, Identifiable {
    case none = "None"
    case defaultBeep = "Default Beep"
    case custom = "Custom Sound"
    var id: Self { self }
    
    var localized: String {
        switch self {
        case .none:
            return NSLocalizedString("No Sound", comment: "")
        case .defaultBeep:
            return NSLocalizedString("Default Beep", comment: "")
        case .custom:
            return NSLocalizedString("Custom Sound", comment: "")
        }
    }
}
