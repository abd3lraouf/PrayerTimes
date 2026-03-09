import XCTest
import AppKit
@testable import PrayerTimes

/// Tests that all custom text colors meet WCAG 2.1 contrast requirements.
/// Covers every named color asset used as foreground text across the app:
/// - MainView: SuhoorColor, IftarColor, ImminentColor, FastingBannerColor, SecondaryTextColor
/// - SettingsView, AboutView, NotificationsSettingsView: SecondaryTextColor
/// - PrayerTimeViewModel (menu bar): ImminentColor
/// - PrayerRow highlights: ImminentFillColor (solid bg with white text)
final class ColorContrastTests: XCTestCase {

    // WCAG 2.1 contrast thresholds
    private let aaaThreshold: CGFloat = 7.0   // enhanced (normal text)
    private let aaThreshold: CGFloat = 4.5    // minimum (normal text)

    // macOS dark mode popover background (~rgb(41,41,41))
    private let darkBackground = NSColor(srgbRed: 0.16, green: 0.16, blue: 0.16, alpha: 1.0)
    private let lightBackground = NSColor.white

    // MARK: - Text-on-background colors (AAA required)

    /// All named colors used as foreground text on the default view background.
    /// Each must pass AAA (7:1) in both light and dark mode.
    private var textColorNames: [String] {
        ["SuhoorColor", "IftarColor", "ImminentColor", "FastingBannerColor"]
    }

    func testAllTextColorsMeetAAAInLightMode() {
        for name in textColorNames {
            let color = loadColor(name, appearance: .aqua)
            let ratio = contrastRatio(color, against: lightBackground)
            XCTAssertGreaterThanOrEqual(ratio, aaaThreshold,
                "\(name) light: \(format(ratio)) below AAA (\(aaaThreshold):1)")
        }
    }

    func testAllTextColorsMeetAAAInDarkMode() {
        for name in textColorNames {
            let color = loadColor(name, appearance: .darkAqua)
            let ratio = contrastRatio(color, against: darkBackground)
            XCTAssertGreaterThanOrEqual(ratio, aaaThreshold,
                "\(name) dark: \(format(ratio)) below AAA (\(aaaThreshold):1)")
        }
    }

    // MARK: - SecondaryTextColor (used across all settings views)

    func testSecondaryTextColorLightContrast() {
        let color = loadColor("SecondaryTextColor", appearance: .aqua)
        let ratio = contrastRatio(color, against: lightBackground)
        XCTAssertGreaterThanOrEqual(ratio, aaThreshold,
            "SecondaryTextColor light: \(format(ratio)) below AA (\(aaThreshold):1)")
    }

    func testSecondaryTextColorDarkContrast() {
        let color = loadColor("SecondaryTextColor", appearance: .darkAqua)
        let ratio = contrastRatio(color, against: darkBackground)
        XCTAssertGreaterThanOrEqual(ratio, aaThreshold,
            "SecondaryTextColor dark: \(format(ratio)) below AA (\(aaThreshold):1)")
    }

    // MARK: - ImminentFillColor (solid background, white text on top)

    func testImminentFillWhiteTextLightContrast() {
        let bg = loadColor("ImminentFillColor", appearance: .aqua)
        let ratio = contrastRatio(NSColor.white, against: bg)
        XCTAssertGreaterThanOrEqual(ratio, aaThreshold,
            "White on ImminentFillColor light: \(format(ratio)) below AA (\(aaThreshold):1)")
    }

    func testImminentFillWhiteTextDarkContrast() {
        let bg = loadColor("ImminentFillColor", appearance: .darkAqua)
        let ratio = contrastRatio(NSColor.white, against: bg)
        XCTAssertGreaterThanOrEqual(ratio, aaThreshold,
            "White on ImminentFillColor dark: \(format(ratio)) below AA (\(aaThreshold):1)")
    }

    // MARK: - Background tint colors (same hue as text, low alpha)

    private var bgColorPairs: [(text: String, bg: String)] {
        [
            ("SuhoorColor", "SuhoorBgColor"),
            ("IftarColor", "IftarBgColor"),
            ("ImminentColor", "ImminentBgColor"),
            ("FastingBannerColor", "FastingBannerBgColor"),
        ]
    }

    func testBackgroundColorsHaveMatchingHue() {
        for pair in bgColorPairs {
            for appearance in [NSAppearance.Name.aqua, .darkAqua] {
                let text = loadColor(pair.text, appearance: appearance)
                let bg = loadColor(pair.bg, appearance: appearance)
                let hueDiff = abs(text.hueComponent - bg.hueComponent)
                let normalized = min(hueDiff, 1.0 - hueDiff)
                let mode = appearance == .aqua ? "light" : "dark"
                XCTAssertLessThanOrEqual(normalized, 0.02,
                    "\(pair.text)/\(pair.bg) hue mismatch in \(mode)")
            }
        }
    }

    func testBackgroundColorsHaveLowAlpha() {
        let bgNames = bgColorPairs.map(\.bg)
        for name in bgNames {
            for appearance in [NSAppearance.Name.aqua, .darkAqua] {
                let color = loadColor(name, appearance: appearance)
                let mode = appearance == .aqua ? "light" : "dark"
                XCTAssertLessThanOrEqual(color.alphaComponent, 0.15,
                    "\(name) \(mode) alpha \(color.alphaComponent) too high for tinted background")
            }
        }
    }

    // MARK: - Light mode must be darker than dark mode variant

    func testLightVariantIsDarkerThanDarkVariant() {
        for name in textColorNames {
            let lightColor = loadColor(name, appearance: .aqua)
            let darkColor = loadColor(name, appearance: .darkAqua)
            let lightLum = relativeLuminance(lightColor)
            let darkLum = relativeLuminance(darkColor)
            XCTAssertLessThan(lightLum, darkLum,
                "\(name): light variant (L=\(String(format: "%.3f", lightLum))) should be darker than dark variant (L=\(String(format: "%.3f", darkLum)))")
        }
    }

    // MARK: - All color assets exist

    func testAllColorAssetsExist() {
        let allNames = [
            "SuhoorColor", "SuhoorBgColor",
            "IftarColor", "IftarBgColor",
            "ImminentColor", "ImminentBgColor", "ImminentFillColor",
            "FastingBannerColor", "FastingBannerBgColor",
            "SecondaryTextColor", "HoverColor", "DividerColor", "BorderColor",
        ]
        for name in allNames {
            XCTAssertNotNil(NSColor(named: name), "Color asset '\(name)' missing from asset catalog")
        }
    }

    // MARK: - Helpers

    private func loadColor(_ name: String, appearance: NSAppearance.Name) -> NSColor {
        let app = NSAppearance(named: appearance)!
        var resolved: NSColor!
        app.performAsCurrentDrawingAppearance {
            guard let named = NSColor(named: name) else {
                XCTFail("Color asset '\(name)' not found")
                resolved = NSColor.black
                return
            }
            resolved = named.usingColorSpace(.sRGB) ?? named
        }
        return resolved
    }

    private func sRGBLinearize(_ c: CGFloat) -> CGFloat {
        c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
    }

    private func relativeLuminance(_ color: NSColor) -> CGFloat {
        let c = color.usingColorSpace(.sRGB) ?? color
        return 0.2126 * sRGBLinearize(c.redComponent)
             + 0.7152 * sRGBLinearize(c.greenComponent)
             + 0.0722 * sRGBLinearize(c.blueComponent)
    }

    private func contrastRatio(_ c1: NSColor, against c2: NSColor) -> CGFloat {
        let l1 = relativeLuminance(c1)
        let l2 = relativeLuminance(c2)
        return (max(l1, l2) + 0.05) / (min(l1, l2) + 0.05)
    }

    private func format(_ ratio: CGFloat) -> String {
        "\(String(format: "%.1f", ratio)):1"
    }
}
