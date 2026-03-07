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

    // Text
    static let fontName = "System"
    static let fontSize: CGFloat = 28
    static let textTopPadding: CGFloat = 40
    static let textHorizontalPadding: CGFloat = 30

    // Shadow
    static let shadowRadius: CGFloat = 20
    static let shadowOffset = CGSize(width: 0, height: 10)
    static let shadowColor = NSColor.black.withAlphaComponent(0.5)

    // Output
    static let canvasPadding: CGFloat = 40
}

// MARK: - Taglines

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

// MARK: - Language display names (for optional watermark)

let languageNames: [String: String] = [
    "en": "English",
    "ar": "العربية",
    "id": "Indonesia",
    "fa": "فارسی",
    "ur": "اردو",
]

// MARK: - Helpers

func projectRoot() -> URL {
    // Script is at scripts/generate-screenshots.swift
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

// MARK: - Drawing

func drawCard(
    context: CGContext,
    x: CGFloat,
    y: CGFloat,
    screenshot: NSImage,
    tagline: String,
    lang: String
) {
    let cardRect = CGRect(x: x, y: y, width: Config.cardWidth, height: Config.cardHeight)

    // Card background with gradient
    context.saveGState()
    let cardPath = CGPath(
        roundedRect: cardRect,
        cornerWidth: Config.cardCornerRadius,
        cornerHeight: Config.cardCornerRadius,
        transform: nil
    )
    context.addPath(cardPath)
    context.clip()

    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let gradientColors = [
        NSColor(red: 0.06, green: 0.08, blue: 0.14, alpha: 1.0).cgColor,
        NSColor(red: 0.04, green: 0.12, blue: 0.18, alpha: 1.0).cgColor,
        NSColor(red: 0.02, green: 0.10, blue: 0.15, alpha: 1.0).cgColor,
    ] as CFArray
    let locations: [CGFloat] = [0.0, 0.5, 1.0]
    if let gradient = CGGradient(colorsSpace: colorSpace, colors: gradientColors, locations: locations) {
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: cardRect.midX, y: cardRect.maxY),
            end: CGPoint(x: cardRect.midX, y: cardRect.minY),
            options: []
        )
    }
    context.restoreGState()

    // Draw tagline text
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = isRTL(lang) ? .right : .left
    paragraphStyle.lineSpacing = 4

    let font = NSFont.boldSystemFont(ofSize: Config.fontSize)
    let attributes: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor.white,
        .paragraphStyle: paragraphStyle,
    ]

    let textRect = CGRect(
        x: x + Config.textHorizontalPadding,
        y: y + Config.cardHeight - Config.textTopPadding - 100,
        width: Config.cardWidth - Config.textHorizontalPadding * 2,
        height: 100
    )
    let attrString = NSAttributedString(string: tagline, attributes: attributes)
    attrString.draw(in: textRect)

    // Draw screenshot with rounded corners and shadow
    let screenshotWidth = Config.cardWidth - Config.screenshotInset * 2
    let screenshotAspect = screenshot.size.height / screenshot.size.width
    let screenshotHeight = screenshotWidth * screenshotAspect
    let screenshotRect = CGRect(
        x: x + Config.screenshotInset,
        y: y + Config.cardHeight - Config.screenshotTopPadding - screenshotHeight,
        width: screenshotWidth,
        height: screenshotHeight
    )

    // Shadow
    context.saveGState()
    context.setShadow(
        offset: Config.shadowOffset,
        blur: Config.shadowRadius,
        color: Config.shadowColor.cgColor
    )
    let screenshotPath = CGPath(
        roundedRect: screenshotRect,
        cornerWidth: Config.screenshotCornerRadius,
        cornerHeight: Config.screenshotCornerRadius,
        transform: nil
    )
    context.addPath(screenshotPath)
    context.setFillColor(NSColor.black.cgColor)
    context.fillPath()
    context.restoreGState()

    // Clip and draw screenshot
    context.saveGState()
    context.addPath(screenshotPath)
    context.clip()
    if let cgImage = screenshot.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        context.draw(cgImage, in: screenshotRect)
    }
    context.restoreGState()
}

func generateCollage(lang: String) {
    print("Generating collage for \(lang)...")

    // Load all 4 screenshots
    var screenshots: [(String, NSImage)] = []
    for view in Config.views {
        guard let img = loadImage(lang: lang, view: view) else {
            print("  WARNING: Missing screenshot for \(lang)/\(view).png, skipping language")
            return
        }
        screenshots.append((view, img))
    }

    // Calculate canvas size
    let totalCardsWidth = Config.cardWidth * CGFloat(screenshots.count)
        + Config.cardSpacing * CGFloat(screenshots.count - 1)
    let canvasWidth = totalCardsWidth + Config.canvasPadding * 2
    let canvasHeight = Config.cardHeight + Config.verticalOffset + Config.canvasPadding * 2

    // Create bitmap context
    let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue
    guard let context = CGContext(
        data: nil,
        width: Int(canvasWidth),
        height: Int(canvasHeight),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo
    ) else {
        print("  ERROR: Could not create graphics context")
        return
    }

    // Flip coordinate system for text drawing
    let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
    NSGraphicsContext.current = nsContext

    // Fill background with dark color
    context.setFillColor(NSColor(red: 0.03, green: 0.03, blue: 0.05, alpha: 1.0).cgColor)
    context.fill(CGRect(x: 0, y: 0, width: canvasWidth, height: canvasHeight))

    // Draw each card with alternating offset
    for (index, (view, screenshot)) in screenshots.enumerated() {
        let x = Config.canvasPadding + CGFloat(index) * (Config.cardWidth + Config.cardSpacing)
        let yOffset: CGFloat = (index % 2 == 0) ? Config.verticalOffset : 0
        let y = Config.canvasPadding + yOffset

        let tagline = taglines[lang]?[view] ?? ""
        drawCard(context: context, x: x, y: y, screenshot: screenshot, tagline: tagline, lang: lang)
    }

    NSGraphicsContext.current = nil

    // Save output
    guard let cgImage = context.makeImage() else {
        print("  ERROR: Could not create image")
        return
    }

    let outputURL = projectRoot()
        .appendingPathComponent("screenshots/output/\(lang).png")
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("  ERROR: Could not create PNG data")
        return
    }

    do {
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try pngData.write(to: outputURL)
        print("  Saved: \(outputURL.path)")
    } catch {
        print("  ERROR: Could not write file: \(error)")
    }
}

// MARK: - Main

print("Screenshot Collage Generator")
print("============================\n")

let root = projectRoot()
print("Project root: \(root.path)\n")

for lang in Config.languages {
    generateCollage(lang: lang)
}

print("\nDone!")
