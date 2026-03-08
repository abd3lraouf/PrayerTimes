// MARK: - GANTI/BUAT FILE: PrayerTimes/LanguageManager.swift

import SwiftUI

// Kelas ini akan menjadi satu-satunya sumber kebenaran untuk bahasa.
class LanguageManager: ObservableObject {
    @AppStorage(StorageKeys.selectedLanguage) var language: String = "en" {
        didSet {
            Bundle.setLanguage(language)
            objectWillChange.send()
        }
    }

    @AppStorage(StorageKeys.useNativeNumerals) var useNativeNumerals: Bool = true {
        didSet {
            objectWillChange.send()
        }
    }

    static let nativeNumeralLanguages = ["ar", "fa", "ur"]

    var supportsNativeNumerals: Bool {
        return Self.nativeNumeralLanguages.contains(language)
    }

    private static let nativeNumeralLocaleIds: [String: String] = [
        "ar": "ar@numbers=arab",
        "fa": "fa",
        "ur": "ur@numbers=arabext"
    ]

    var numeralLocale: Locale {
        if supportsNativeNumerals && !useNativeNumerals {
            return Locale(identifier: "en")
        }
        if let nativeId = Self.nativeNumeralLocaleIds[language] {
            return Locale(identifier: nativeId)
        }
        return Locale(identifier: language)
    }

    init() {
        if let langOverride = ProcessInfo.processInfo.environment["SCREENSHOT_LANGUAGE"] {
            language = langOverride
        }
        Bundle.setLanguage(language)
    }
    
    // RTL language support
    static let rtlLanguages = ["ar", "he", "fa", "ur"]
    
    var isRTLEnabled: Bool {
        return Self.rtlLanguages.contains(language)
    }
}

// View pembungkus ini akan menerapkan environment dan memaksa render ulang.
struct LanguageManagerView<Content: View>: View {
    @StateObject var manager: LanguageManager
    let content: Content

    init(manager: LanguageManager, @ViewBuilder content: () -> Content) {
        _manager = StateObject(wrappedValue: manager)
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(manager)
            .environment(\.locale, Locale(identifier: manager.language))
            .environment(\.layoutDirection, manager.isRTLEnabled ? .rightToLeft : .leftToRight)
            .id(manager.language) // Ini adalah kunci untuk memaksa render ulang!
    }
}

// Ekstensi untuk Bundle (tetap di file yang sama)
var bundleKey: UInt8 = 0
class AnyLanguageBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let path = objc_getAssociatedObject(self, &bundleKey) as? String,
              let bundle = Bundle(path: path) else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}
extension Bundle {
    static func setLanguage(_ language: String) {
        defer { object_setClass(Bundle.main, AnyLanguageBundle.self) }
        let value = language == "en" ? nil : Bundle.main.path(forResource: language, ofType: "lproj")
        objc_setAssociatedObject(Bundle.main, &bundleKey, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
