#!/usr/bin/env swift

import AppKit
import Foundation

// MARK: - Configuration

struct Config {
    static let languages = ["en", "ar", "id", "fa", "ur"]
    static let views = ["main", "settings", "notifications", "about"]
    static let rtlLanguages: Set<String> = ["ar", "fa", "ur"]

    // Card dimensions
    static let cardWidth: CGFloat = 560
    static let cardHeight: CGFloat = 1100
    static let cardCornerRadius: CGFloat = 24
    static let cardSpacing: CGFloat = 20
    static let verticalOffset: CGFloat = 60

    // Screenshot inside card
    static let screenshotInset: CGFloat = 24
    static let screenshotTopPadding: CGFloat = 200
    static let screenshotCornerRadius: CGFloat = 16

    // Tagline text on cards
    static let textTopPadding: CGFloat = 40
    static let textHorizontalPadding: CGFloat = 30

    // Language-specific tagline fonts
    static let taglineFonts: [String: String] = [
        "en": "AvenirNext-Bold",
        "id": "AvenirNext-Bold",
        "ar": "DecoTypeNaskh",
        "fa": "GeezaPro-Bold",
        "ur": "NotoNastaliqUrdu-Bold",
    ]
    static let taglineFontSizes: [String: CGFloat] = [
        "en": 30, "id": 30, "ar": 36, "fa": 30, "ur": 30,
    ]

    // Language-specific logo/header fonts
    static let logoFonts: [String: String] = [
        "en": "AvenirNext-Bold",
        "id": "AvenirNext-Bold",
        "ar": "DecoTypeNaskh",
        "fa": "GeezaPro-Bold",
        "ur": "NotoNastaliqUrdu-Bold",
    ]
    static let logoFontSizes: [String: CGFloat] = [
        "en": 48, "id": 48, "ar": 56, "fa": 48, "ur": 48,
    ]

    // Footer fonts
    static let footerFonts: [String: String] = [
        "en": "AvenirNext-DemiBold",
        "id": "AvenirNext-DemiBold",
        "ar": "GeezaPro",
        "fa": "GeezaPro",
        "ur": "NotoNastaliqUrdu",
    ]
    static let footerFontSizes: [String: CGFloat] = [
        "en": 22, "id": 22, "ar": 26, "fa": 22, "ur": 22,
    ]

    // Layout
    static let canvasPadding: CGFloat = 40
    static let headerHeight: CGFloat = 180
    static let footerHeight: CGFloat = 100
    static let headerIconSize: CGFloat = 80
    static let headerIconCornerRadius: CGFloat = 18
    static let headerSpacing: CGFloat = 20

    // Shadow
    static let shadowRadius: CGFloat = 20
    static let shadowOffset = CGSize(width: 0, height: 10)
    static let shadowColor = NSColor.black.withAlphaComponent(0.5)
}

// MARK: - Content

let taglines: [String: [String: String]] = [
    "en": [
        "main": "Every prayer,\nright on time.",
        "settings": "Your prayers,\nyour way.",
        "notifications": "A gentle reminder\nbefore every prayer.",
        "about": "Made with love\nfor the Ummah.",
    ],
    "ar": [
        "main": "كل صلاة،\nفي وقتها.",
        "settings": "صلاتك،\nبطريقتك.",
        "notifications": "تذكير لطيف\nقبل كل صلاة.",
        "about": "صُنع بحب\nللأمة.",
    ],
    "id": [
        "main": "Setiap shalat,\ntepat waktu.",
        "settings": "Shalat Anda,\ncara Anda.",
        "notifications": "Pengingat lembut\nsebelum setiap shalat.",
        "about": "Dibuat dengan cinta\nuntuk Ummah.",
    ],
    "fa": [
        "main": "هر نماز،\nدرست به موقع.",
        "settings": "نمازهای شما،\nبه روش شما.",
        "notifications": "یادآوری آرام\nپیش از هر نماز.",
        "about": "ساخته شده با عشق\nبرای امت.",
    ],
    "ur": [
        "main": "ہر نماز،\nبالکل وقت پر.",
        "settings": "آپ کی نماز،\nآپ کے انداز میں.",
        "notifications": "ہر نماز سے پہلے\nایک نرم یاد دہانی.",
        "about": "امت کے لیے\nمحبت سے بنایا گیا.",
    ],
]

let appNames: [String: String] = [
    "en": "PrayerTimes Pro",
    "ar": "أوقات الصلاة برو",
    "id": "PrayerTimes Pro",
    "fa": "اوقات نماز پرو",
    "ur": "نماز کے اوقات پرو",
]

let footerTexts: [String: String] = [
    "en": "Your daily prayer companion for macOS",
    "ar": "رفيقك اليومي للصلاة على ماك",
    "id": "Teman shalat harian Anda untuk macOS",
    "fa": "همراه نماز روزانه شما برای مک",
    "ur": "macOS کے لیے آپ کا روزانہ نماز ساتھی",
]

// MARK: - Helpers

func projectRoot() -> URL {
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
}

func loadImage(lang: String, view: String) -> NSImage? {
    let path = projectRoot()
        .appendingPathComponent("screenshots/raw/\(lang)/\(view).png")
    return NSImage(contentsOf: path)
}

func isRTL(_ lang: String) -> Bool {
    Config.rtlLanguages.contains(lang)
}

func taglineFont(lang: String) -> NSFont {
    let name = Config.taglineFonts[lang] ?? "AvenirNext-Bold"
    let size = Config.taglineFontSizes[lang] ?? 30
    return NSFont(name: name, size: size) ?? NSFont.boldSystemFont(ofSize: size)
}

func logoFont(lang: String) -> NSFont {
    let name = Config.logoFonts[lang] ?? "AvenirNext-Bold"
    let size = Config.logoFontSizes[lang] ?? 48
    return NSFont(name: name, size: size) ?? NSFont.boldSystemFont(ofSize: size)
}

func footerFont(lang: String) -> NSFont {
    let name = Config.footerFonts[lang] ?? "AvenirNext-DemiBold"
    let size = Config.footerFontSizes[lang] ?? 22
    return NSFont(name: name, size: size) ?? NSFont.systemFont(ofSize: size)
}

func savePNG(cgImage: CGImage, to url: URL) {
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("  ERROR: Could not create PNG data"); return
    }
    do {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try pngData.write(to: url)
        print("  Saved: \(url.path)")
    } catch {
        print("  ERROR: Could not write file: \(error)")
    }
}

// MARK: - Draw Card

func drawCard(
    context: CGContext, x: CGFloat, y: CGFloat,
    screenshot: NSImage, tagline: String, lang: String
) {
    let cardRect = CGRect(x: x, y: y, width: Config.cardWidth, height: Config.cardHeight)

    // Card background gradient
    context.saveGState()
    let cardPath = CGPath(roundedRect: cardRect, cornerWidth: Config.cardCornerRadius, cornerHeight: Config.cardCornerRadius, transform: nil)
    context.addPath(cardPath)
    context.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        NSColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1.0).cgColor,
        NSColor(red: 0.04, green: 0.12, blue: 0.18, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.10, blue: 0.15, alpha: 1.0).cgColor,
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: [0.0, 0.5, 1.0]) {
        context.drawLinearGradient(gradient, start: CGPoint(x: cardRect.midX, y: cardRect.maxY), end: CGPoint(x: cardRect.midX, y: cardRect.minY), options: [])
    }
    context.restoreGState()

    // Tagline text
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = isRTL(lang) ? .right : .left
    paragraphStyle.lineSpacing = 6

    let font = taglineFont(lang: lang)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraphStyle,
    ]

    let textRect = CGRect(
        x: x + Config.textHorizontalPadding,
        y: y + Config.cardHeight - Config.textTopPadding - 120,
        width: Config.cardWidth - Config.textHorizontalPadding * 2,
        height: 120
    )
    NSAttributedString(string: tagline, attributes: attributes).draw(in: textRect)

    // Screenshot with rounded corners and shadow
    let screenshotWidth = Config.cardWidth - Config.screenshotInset * 2
    let screenshotAspect = screenshot.size.height / screenshot.size.width
    let screenshotHeight = screenshotWidth * screenshotAspect
    let screenshotRect = CGRect(
        x: x + Config.screenshotInset,
        y: y + Config.cardHeight - Config.screenshotTopPadding - screenshotHeight,
        width: screenshotWidth, height: screenshotHeight
    )

    let screenshotPath = CGPath(roundedRect: screenshotRect, cornerWidth: Config.screenshotCornerRadius, cornerHeight: Config.screenshotCornerRadius, transform: nil)

    // Shadow
    context.saveGState()
    context.setShadow(offset: Config.shadowOffset, blur: Config.shadowRadius, color: Config.shadowColor.cgColor)
    context.addPath(screenshotPath)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    // Screenshot image
    context.saveGState()
    context.addPath(screenshotPath)
    context.clip()
    if let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        context.draw(cgImage, in: screenshotRect)
    }
    context.restoreGState()
}

// MARK: - Draw Header (Logo + App Name)

func drawHeader(context: CGContext, canvasWidth: CGFloat, canvasHeight: CGFloat, lang: String, icon: NSImage) {
    let appName = appNames[lang] ?? "PrayerTimes Pro"
    let font = logoFont(lang: lang)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
    ]
    let textSize = (appName as NSString).size(withAttributes: attributes)

    let iconSize = Config.headerIconSize
    let spacing = Config.headerSpacing
    let totalWidth = iconSize + spacing + textSize.width

    let centerX = (canvasWidth - totalWidth) / 2
    let headerCenterY = canvasHeight - Config.canvasPadding - Config.headerHeight / 2

    let iconX: CGFloat
    let textX: CGFloat

    if isRTL(lang) {
        textX = centerX
        iconX = centerX + textSize.width + spacing
    } else {
        iconX = centerX
        textX = centerX + iconSize + spacing
    }

    let iconY = headerCenterY - iconSize / 2
    let iconRect = CGRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
    let iconPath = CGPath(roundedRect: iconRect, cornerWidth: Config.headerIconCornerRadius, cornerHeight: Config.headerIconCornerRadius, transform: nil)

    // Icon shadow
    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 4), blur: 12, color: NSColor.black.withAlphaComponent(0.4).cgColor)
    context.addPath(iconPath)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    // Icon image
    context.saveGState()
    context.addPath(iconPath)
    context.clip()
    if let cgIcon = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        context.draw(cgIcon, in: iconRect)
    }
    context.restoreGState()

    // App name text
    let textY = headerCenterY - textSize.height / 2
    let textRect = CGRect(x: textX, y: textY, width: textSize.width + 10, height: textSize.height + 10)
    (appName as NSString).draw(in: textRect, withAttributes: attributes)
}

// MARK: - Draw Footer

func drawFooter(context: CGContext, canvasWidth: CGFloat, lang: String) {
    let text = footerTexts[lang] ?? ""
    let font = footerFont(lang: lang)

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center

    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(red: 0.5, green: 0.6, blue: 0.7, alpha: 1.0),
        .paragraphStyle: paragraphStyle,
    ]

    let textSize = (text as NSString).size(withAttributes: attributes)
    let textRect = CGRect(
        x: Config.canvasPadding,
        y: Config.canvasPadding + (Config.footerHeight - textSize.height) / 2,
        width: canvasWidth - Config.canvasPadding * 2,
        height: textSize.height + 10
    )
    (text as NSString).draw(in: textRect, withAttributes: attributes)
}

// MARK: - Generate Collage

func generateCollage(lang: String) {
    print("Generating collage for \(lang)...")

    let iconPath = projectRoot()
        .appendingPathComponent("PrayerTimes/Assets.xcassets/AppIcon.appiconset/512.png")
    guard let icon = NSImage(contentsOf: iconPath) else {
        print("  WARNING: App icon not found"); return
    }

    var screenshots: [(String, NSImage)] = []
    for view in Config.views {
        guard let img = loadImage(lang: lang, view: view) else {
            print("  WARNING: Missing screenshot for \(lang)/\(view).png, skipping language"); return
        }
        screenshots.append((view, img))
    }

    // Canvas: header + cards area + footer
    let totalCardsWidth = Config.cardWidth * CGFloat(screenshots.count)
        + Config.cardSpacing * CGFloat(screenshots.count - 1)
    let canvasWidth = totalCardsWidth + Config.canvasPadding * 2
    let cardsAreaHeight = Config.cardHeight + Config.verticalOffset
    let canvasHeight = Config.canvasPadding * 2 + Config.headerHeight + cardsAreaHeight + Config.footerHeight

    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
    guard let context = CGContext(
        data: nil, width: Int(canvasWidth), height: Int(canvasHeight),
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo
    ) else {
        print("  ERROR: Could not create graphics context"); return
    }

    let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.current = nsContext

    // Background
    context.setFillColor(NSColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))

    // Draw header (top of canvas)
    drawHeader(context: context, canvasWidth: canvasWidth, canvasHeight: canvasHeight, lang: lang, icon: icon)

    // Draw cards (middle area, below header)
    let cardsBaseY = Config.canvasPadding + Config.footerHeight
    for (index, (view, screenshot)) in screenshots.enumerated() {
        let x = Config.canvasPadding + CGFloat(index) * (Config.cardWidth + Config.cardSpacing)
        let yOffset: CGFloat = (index % 2 == 0) ? Config.verticalOffset : 0
        let y = cardsBaseY + yOffset

        let tagline = taglines[lang]?[view] ?? ""
        drawCard(context: context, x: x, y: y, screenshot: screenshot, tagline: tagline, lang: lang)
    }

    // Draw footer (bottom of canvas)
    drawFooter(context: context, canvasWidth: canvasWidth, lang: lang)

    NSGraphicsContext.current = nil

    guard let cgImage = context.makeImage() else {
        print("  ERROR: Could not create image"); return
    }
    savePNG(cgImage: cgImage, to: projectRoot().appendingPathComponent("screenshots/output/\(lang).png"))
}

// MARK: - Generate Standalone Logo Image

func generateLogoImage(lang: String) {
    print("Generating logo image for \(lang)...")

    let iconPath = projectRoot()
        .appendingPathComponent("PrayerTimes/Assets.xcassets/AppIcon.appiconset/512.png")
    guard let icon = NSImage(contentsOf: iconPath) else {
        print("  WARNING: App icon not found"); return
    }

    let appName = appNames[lang] ?? "PrayerTimes Pro"
    let rtl = isRTL(lang)
    let iconSize: CGFloat = 128
    let iconCornerRadius: CGFloat = 28
    let spacing: CGFloat = 24
    let hPad: CGFloat = 60

    let titleFont = logoFont(lang: lang)
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor.white,
    ]
    let titleSize = (appName as NSString).size(withAttributes: titleAttributes)

    let contentWidth = iconSize + spacing + titleSize.width
    let canvasWidth = contentWidth + hPad * 2
    let canvasHeight: CGFloat = 200

    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
    guard let context = CGContext(
        data: nil, width: Int(canvasWidth), height: Int(canvasHeight),
        bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo
    ) else {
        print("  ERROR: Could not create graphics context"); return
    }

    let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.current = nsContext

    // Dark rounded background
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight), cornerWidth: 24, cornerHeight: 24, transform: nil)
    context.saveGState()
    context.addPath(bgPath)
    context.clip()
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bgColors = [
        NSColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1.0).cgColor,
        NSColor(red: 0.04, green: 0.10, blue: 0.16, alpha: 1.0).cgColor,
    ] as CFArray
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: canvasHeight), end: CGPoint(x: canvasWidth, y: 0), options: [])
    }
    context.restoreGState()

    let iconY = (canvasHeight - iconSize) / 2
    let iconX: CGFloat
    let textX: CGFloat

    if rtl {
        textX = hPad
        iconX = hPad + titleSize.width + spacing
    } else {
        iconX = hPad
        textX = hPad + iconSize + spacing
    }

    // Icon shadow + image
    let iconRect = CGRect(x: iconX, y: iconY, width: iconSize, height: iconSize)
    let iconClipPath = CGPath(roundedRect: iconRect, cornerWidth: iconCornerRadius, cornerHeight: iconCornerRadius, transform: nil)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: 4), blur: 12, color: NSColor.black.withAlphaComponent(0.4).cgColor)
    context.addPath(iconClipPath)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(iconClipPath)
    context.clip()
    if let cgIcon = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        context.draw(cgIcon, in: iconRect)
    }
    context.restoreGState()

    // Text
    let textY = (canvasHeight - titleSize.height) / 2
    (appName as NSString).draw(
        in: CGRect(x: textX, y: textY, width: titleSize.width + 10, height: titleSize.height + 10),
        withAttributes: titleAttributes
    )

    NSGraphicsContext.current = nil

    guard let cgImage = context.makeImage() else {
        print("  ERROR: Could not create image"); return
    }
    savePNG(cgImage: cgImage, to: projectRoot().appendingPathComponent("screenshots/output/\(lang)_logo.png"))
}

// MARK: - Main

print("Screenshot Collage Generator")
print("============================\n")
print("Project root: \(projectRoot().path)\n")

for lang in Config.languages {
    generateCollage(lang: lang)
    generateLogoImage(lang: lang)
}

print("\nDone!")
