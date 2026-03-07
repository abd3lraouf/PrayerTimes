# Screenshot Generation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Generate per-language marketing collage images showcasing the app's 4 main views for all 5 supported languages.

**Architecture:** UI tests capture raw screenshots by launching the app with language overrides and navigating to each view. A standalone Swift script composites the raw PNGs into polished collage images using AppKit/CoreGraphics.

**Tech Stack:** XCTest/XCUIApplication for capture, AppKit/CoreGraphics for composition, Swift script for CLI.

---

### Task 1: Add accessibility identifiers to navigable views

**Files:**
- Modify: `PrayerTimes/MainView.swift`
- Modify: `PrayerTimes/SettingsView.swift`
- Modify: `PrayerTimes/NotificationsSettingsView.swift`
- Modify: `PrayerTimes/AboutView.swift`
- Modify: `PrayerTimes/ContentView.swift`

UI tests need accessibility identifiers to find and tap buttons. Add `.accessibilityIdentifier()` to key elements.

**Step 1: Add identifiers to MainView.swift**

Add to the Settings button (line 48-64):
```swift
.accessibilityIdentifier("MainView.settingsButton")
```

Add to the About button (line 67-83):
```swift
.accessibilityIdentifier("MainView.aboutButton")
```

Add to the root VStack (line 16):
```swift
.accessibilityIdentifier("MainView")
```

**Step 2: Add identifiers to SettingsView.swift**

Add to the Notifications button (line 59):
```swift
.accessibilityIdentifier("SettingsView.notificationsButton")
```

Add to the back button (line 23-34):
```swift
.accessibilityIdentifier("SettingsView.backButton")
```

Add to the root `NavigationStackView` wrapper VStack (line 22):
```swift
.accessibilityIdentifier("SettingsView")
```

**Step 3: Add identifiers to NotificationsSettingsView.swift**

Add to the back button:
```swift
.accessibilityIdentifier("NotificationsSettingsView.backButton")
```

Add to the root VStack:
```swift
.accessibilityIdentifier("NotificationsSettingsView")
```

**Step 4: Add identifiers to AboutView.swift**

Add to the back button:
```swift
.accessibilityIdentifier("AboutView.backButton")
```

Add to the root VStack:
```swift
.accessibilityIdentifier("AboutView")
```

**Step 5: Add identifier to ContentView.swift**

Add to the root `NavigationStackView`:
```swift
.accessibilityIdentifier("ContentView")
```

**Step 6: Build to verify**

Run: `xcodebuild build -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' -quiet CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO`
Expected: BUILD SUCCEEDED

**Step 7: Commit**

```
git add PrayerTimes/MainView.swift PrayerTimes/SettingsView.swift PrayerTimes/NotificationsSettingsView.swift PrayerTimes/AboutView.swift PrayerTimes/ContentView.swift
git commit -m "feat: add accessibility identifiers for screenshot automation"
```

---

### Task 2: Add language override support via launch arguments

**Files:**
- Modify: `PrayerTimes/LanguageManager.swift`

The app needs to accept a launch argument to force a specific language during UI tests, bypassing AppStorage.

**Step 1: Add launch argument check to LanguageManager init**

In `LanguageManager.swift`, add a check at the beginning of `init()` or after the class declaration. The `language` property uses `@AppStorage(StorageKeys.selectedLanguage)`. We need to override it when a launch argument is present.

Add this computed property and modify the existing flow. After the `@AppStorage` declaration for `language`, add an `init()` that checks for launch arguments:

```swift
init() {
    if let langOverride = ProcessInfo.processInfo.environment["SCREENSHOT_LANGUAGE"] {
        language = langOverride
    }
    Bundle.setLanguage(language)
}
```

**Step 2: Build to verify**

Run: `xcodebuild build -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' -quiet CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```
git add PrayerTimes/LanguageManager.swift
git commit -m "feat: support language override via environment variable"
```

---

### Task 3: Create the ScreenshotGenerator UI test

**Files:**
- Create: `PrayerTimesUITests/ScreenshotGenerator.swift`

**Step 1: Create the screenshot directory structure**

```bash
mkdir -p screenshots/raw/{en,ar,id,fa,ur}
mkdir -p screenshots/output
```

**Step 2: Create ScreenshotGenerator.swift**

```swift
import XCTest

final class ScreenshotGenerator: XCTestCase {

    let languages = ["en", "ar", "id", "fa", "ur"]
    let views = ["main", "settings", "notifications", "about"]

    override class var runsForEachTargetApplicationUIConfiguration: Bool { false }

    func testGenerateAllScreenshots() throws {
        for lang in languages {
            let app = XCUIApplication()
            app.launchEnvironment["SCREENSHOT_LANGUAGE"] = lang

            // Set Apple language/locale for proper system formatting
            app.launchArguments += ["-AppleLanguages", "(\(lang))", "-AppleLocale", lang]

            app.launch()

            // Wait for app to settle
            sleep(2)

            // 1. Main view screenshot
            captureScreenshot(app: app, lang: lang, view: "main")

            // 2. Navigate to Settings
            let settingsButton = app.buttons["MainView.settingsButton"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button not found for \(lang)")
            settingsButton.tap()
            sleep(1)
            captureScreenshot(app: app, lang: lang, view: "settings")

            // 3. Navigate to Notifications (from Settings)
            let notifButton = app.buttons["SettingsView.notificationsButton"]
            XCTAssertTrue(notifButton.waitForExistence(timeout: 5), "Notifications button not found for \(lang)")
            notifButton.tap()
            sleep(1)
            captureScreenshot(app: app, lang: lang, view: "notifications")

            // 4. Go back to Settings, then back to Main
            let notifBackButton = app.buttons["NotificationsSettingsView.backButton"]
            XCTAssertTrue(notifBackButton.waitForExistence(timeout: 5))
            notifBackButton.tap()
            sleep(1)

            let settingsBackButton = app.buttons["SettingsView.backButton"]
            XCTAssertTrue(settingsBackButton.waitForExistence(timeout: 5))
            settingsBackButton.tap()
            sleep(1)

            // 5. Navigate to About
            let aboutButton = app.buttons["MainView.aboutButton"]
            XCTAssertTrue(aboutButton.waitForExistence(timeout: 5), "About button not found for \(lang)")
            aboutButton.tap()
            sleep(1)
            captureScreenshot(app: app, lang: lang, view: "about")

            app.terminate()
        }
    }

    private func captureScreenshot(app: XCUIApplication, lang: String, view: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(lang)_\(view)"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also save to disk
        let projectDir = ProcessInfo.processInfo.environment["PROJECT_DIR"]
            ?? URL(fileURLWithPath: #file)
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .path
        let outputPath = "\(projectDir)/screenshots/raw/\(lang)/\(view).png"
        let pngData = screenshot.pngRepresentation
        try? pngData.write(to: URL(fileURLWithPath: outputPath))
    }
}
```

**Step 3: Add the file to the Xcode project**

The new file must be added to the `PrayerTimesUITests` target in `project.pbxproj`. Use this approach:

```bash
# Find the PrayerTimesUITests group in pbxproj and add the file reference
python3 -c "
import uuid, re

def gen_id():
    return uuid.uuid4().hex[:24].upper()

file_ref_id = gen_id()
build_file_id = gen_id()
filename = 'ScreenshotGenerator.swift'

pbx_path = 'PrayerTimes.xcodeproj/project.pbxproj'
with open(pbx_path, 'r') as f:
    content = f.read()

# Add PBXFileReference
file_ref = f'\t\t{file_ref_id} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};'
content = content.replace(
    '/* End PBXFileReference section */',
    file_ref + '\n/* End PBXFileReference section */'
)

# Add PBXBuildFile for UITests target
build_file = f'\t\t{build_file_id} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_id} /* {filename} */; }};'
content = content.replace(
    '/* End PBXBuildFile section */',
    build_file + '\n/* End PBXBuildFile section */'
)

# Find PrayerTimesUITests group children and add file ref
# Look for PrayerTimesUITests group
ui_test_group_pattern = r'(children = \([^)]*PrayerTimesUITests\.swift[^)]*)\)'
match = re.search(ui_test_group_pattern, content)
if match:
    content = content.replace(match.group(0), match.group(1) + f'\n\t\t\t\t{file_ref_id} /* {filename} */,\n\t\t\t)')

# Find UITests sources build phase and add build file
# Look for the sources phase that contains PrayerTimesUITests
ui_sources_pattern = r'(files = \([^)]*PrayerTimesUITests\.swift[^)]*)\)'
matches = list(re.finditer(ui_sources_pattern, content))
if matches:
    m = matches[0]
    content = content.replace(m.group(0), m.group(1) + f'\n\t\t\t\t{build_file_id} /* {filename} in Sources */,\n\t\t\t)')

with open(pbx_path, 'w') as f:
    f.write(content)
print(f'Added {filename} to PrayerTimesUITests target')
print(f'FileRef: {file_ref_id}')
print(f'BuildFile: {build_file_id}')
"
```

**Step 4: Build UI tests to verify**

Run: `xcodebuild build-for-testing -project PrayerTimes.xcodeproj -scheme PrayerTimes -destination 'platform=macOS' -quiet CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```
git add PrayerTimesUITests/ScreenshotGenerator.swift PrayerTimes.xcodeproj/project.pbxproj
git commit -m "feat: add ScreenshotGenerator UI test for all languages"
```

---

### Task 4: Create the collage composition script

**Files:**
- Create: `scripts/generate-screenshots.swift`

**Step 1: Create the script**

This is the core composition script using AppKit/CoreGraphics. It reads raw screenshots from `screenshots/raw/{lang}/` and produces collage images in `screenshots/output/{lang}.png`.

```swift
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
```

**Step 2: Make the script executable**

```bash
chmod +x scripts/generate-screenshots.swift
```

**Step 3: Commit**

```
git add scripts/generate-screenshots.swift
git commit -m "feat: add collage composition script"
```

---

### Task 5: Add screenshots directory structure and gitkeep files

**Files:**
- Create: `screenshots/raw/en/.gitkeep`
- Create: `screenshots/raw/ar/.gitkeep`
- Create: `screenshots/raw/id/.gitkeep`
- Create: `screenshots/raw/fa/.gitkeep`
- Create: `screenshots/raw/ur/.gitkeep`
- Create: `screenshots/output/.gitkeep`

**Step 1: Create directories with gitkeep**

```bash
for lang in en ar id fa ur; do
    mkdir -p screenshots/raw/$lang
    touch screenshots/raw/$lang/.gitkeep
done
mkdir -p screenshots/output
touch screenshots/output/.gitkeep
```

**Step 2: Add .gitattributes for binary tracking**

Create/update `.gitattributes`:

```
screenshots/**/*.png binary
```

**Step 3: Commit**

```
git add screenshots/ .gitattributes
git commit -m "chore: add screenshots directory structure"
```

---

### Task 6: Update README with per-language screenshots

**Files:**
- Modify: `README.md`

**Step 1: Replace single screenshot with per-language collages**

Replace lines 17-19 (the single screenshot block):

```html
<p align="center">
    <img src="https://github.com/user-attachments/assets/6e8bd922-a446-4b33-a184-e5e89493a4b1" alt="PrayerTimes Screenshot" width="600">
</p>
```

With:

```html
<p align="center">
    <img src="screenshots/output/en.png" alt="English" width="700">
</p>
<p align="center">
    <img src="screenshots/output/ar.png" alt="العربية" width="700">
</p>
<p align="center">
    <img src="screenshots/output/fa.png" alt="فارسی" width="700">
</p>
<p align="center">
    <img src="screenshots/output/ur.png" alt="اردو" width="700">
</p>
<p align="center">
    <img src="screenshots/output/id.png" alt="Indonesia" width="700">
</p>
```

**Step 2: Update supported languages line**

Replace line 28:
```
- Works in English, Arabic, and Indonesian
```
With:
```
- Works in English, Arabic, Indonesian, Persian, and Urdu
```

**Step 3: Commit**

```
git add README.md
git commit -m "docs: update README with per-language screenshot collages"
```

---

### Task 7: Test the full workflow end-to-end

**Step 1: Run the screenshot generator UI test**

```bash
xcodebuild test \
    -project PrayerTimes.xcodeproj \
    -scheme PrayerTimes \
    -destination 'platform=macOS' \
    -only-testing:PrayerTimesUITests/ScreenshotGenerator \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    PROJECT_DIR="$(pwd)"
```

Expected: Test passes, raw PNGs appear in `screenshots/raw/{lang}/`

**Step 2: Verify raw screenshots exist**

```bash
for lang in en ar id fa ur; do
    echo "=== $lang ==="
    ls -la screenshots/raw/$lang/
done
```

Expected: Each language folder contains `main.png`, `settings.png`, `notifications.png`, `about.png`

**Step 3: Run the collage generator**

```bash
swift scripts/generate-screenshots.swift
```

Expected: Output like:
```
Screenshot Collage Generator
============================

Generating collage for en...
  Saved: /path/screenshots/output/en.png
Generating collage for ar...
  Saved: /path/screenshots/output/ar.png
...
Done!
```

**Step 4: Verify output images**

```bash
ls -la screenshots/output/
```

Expected: `en.png`, `ar.png`, `id.png`, `fa.png`, `ur.png` all exist with reasonable file sizes (>100KB each)

**Step 5: Open and visually inspect**

```bash
open screenshots/output/en.png
open screenshots/output/ar.png
```

Verify: Cards are staggered, taglines render correctly, RTL text is right-aligned, screenshots have rounded corners and shadows.

**Step 6: Commit all generated screenshots**

```
git add screenshots/
git commit -m "feat: generate initial screenshot collages for all languages"
```
