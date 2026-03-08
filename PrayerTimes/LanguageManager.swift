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

    // MARK: - Centralized Number Formatting (SSOT)

    /// Cached NumberFormatter — invalidated when language or native numerals toggle changes.
    private var _cachedNumberFormatter: NumberFormatter?
    private var _cachedFormatterKey: String?

    /// The single NumberFormatter all integer/decimal display should use.
    var numberFormatter: NumberFormatter {
        let key = "\(language)-\(useNativeNumerals)"
        if let cached = _cachedNumberFormatter, _cachedFormatterKey == key {
            return cached
        }
        let fmt = NumberFormatter()
        fmt.numberStyle = .none
        fmt.locale = numeralLocale
        _cachedNumberFormatter = fmt
        _cachedFormatterKey = key
        return fmt
    }

    /// Format an integer for display (day numbers, years, percentages, counts).
    func formatNumber(_ value: Int) -> String {
        numberFormatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// Format a signed integer for display (time corrections like +5, -2).
    func formatSigned(_ value: Int) -> String {
        let sign = value > 0 ? "+" : (value < 0 ? "-" : "")
        let formatted = numberFormatter.string(from: NSNumber(value: abs(value))) ?? "\(abs(value))"
        return "\(sign)\(formatted)"
    }

    /// Format a decimal for display (coordinates, etc.).
    func formatDecimal(_ value: Double, fractionDigits: Int = 2) -> String {
        let fmt = numberFormatter.copy() as! NumberFormatter
        fmt.numberStyle = .decimal
        fmt.minimumFractionDigits = fractionDigits
        fmt.maximumFractionDigits = fractionDigits
        return fmt.string(from: NSNumber(value: value)) ?? String(format: "%.\(fractionDigits)f", value)
    }

    /// Format a percentage (0-100 integer) for display.
    func formatPercent(_ value: Int) -> String {
        let num = formatNumber(value)
        return "\(num)%"
    }

    /// Static formatter for contexts without a LanguageManager instance (e.g. notifications).
    /// Reads current settings directly from UserDefaults.
    static func formatNumberStatic(_ value: Int) -> String {
        let lang = UserDefaults.standard.string(forKey: StorageKeys.selectedLanguage) ?? "en"
        let useNative = UserDefaults.standard.object(forKey: StorageKeys.useNativeNumerals) as? Bool ?? true
        let locale: Locale
        if nativeNumeralLanguages.contains(lang) && !useNative {
            locale = Locale(identifier: "en")
        } else if let nativeId = nativeNumeralLocaleIds[lang] {
            locale = Locale(identifier: nativeId)
        } else {
            locale = Locale(identifier: lang)
        }
        let fmt = NumberFormatter()
        fmt.numberStyle = .none
        fmt.locale = locale
        return fmt.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    // MARK: - Font Support

    /// Whether the current language uses Arabic script.
    var usesArabicScript: Bool {
        ["ar", "fa", "ur"].contains(language)
    }

    /// Returns a SwiftUI Font for number display at the given size and weight.
    /// Arabic script: system font (SF Arabic) for visual cohesion with text labels.
    /// Latin script: Inter custom font for polished number rendering.
    func numberFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if usesArabicScript {
            return Font.system(size: size, weight: weight).monospacedDigit()
        }
        return Font.custom(interFontName(weight: weight), size: size).monospacedDigit()
    }

    /// Static version for contexts without a LanguageManager instance.
    static func numberFontStatic(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        let lang = UserDefaults.standard.string(forKey: StorageKeys.selectedLanguage) ?? "en"
        let usesArabic = ["ar", "fa", "ur"].contains(lang)
        if usesArabic {
            return Font.system(size: size, weight: weight).monospacedDigit()
        }
        return Font.custom(interFontName(weight: weight), size: size).monospacedDigit()
    }

    /// Returns the Inter font name for a given weight.
    private func interFontName(weight: Font.Weight = .regular) -> String {
        "Inter-\(Self.interSuffix(for: weight))"
    }

    private static func interFontName(weight: Font.Weight = .regular) -> String {
        "Inter-\(interSuffix(for: weight))"
    }

    private static func interSuffix(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black: return "Bold"
        case .semibold: return "SemiBold"
        case .medium: return "Medium"
        default: return "Regular"
        }
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
