import XCTest
import AppKit

final class ScreenshotGenerator: XCTestCase {

    let languages = ["en", "ar", "id", "fa", "ur"]

    override class var runsForEachTargetApplicationUIConfiguration: Bool { false }

    override func setUp() {
        super.setUp()
        let app = XCUIApplication()
        app.terminate()
    }

    func testGenerateAllScreenshots() throws {
        for lang in languages {
            let app = XCUIApplication()
            app.launchEnvironment["SCREENSHOT_LANGUAGE"] = lang
            app.launchArguments += ["-AppleLanguages", "(\(lang))", "-AppleLocale", lang]

            app.launch()
            sleep(3)

            // 1. Main view
            captureScreenshot(app: app, lang: lang, view: "main")

            // 2. Settings
            let settingsButton = app.buttons["MainView.settingsButton"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button not found for \(lang)")
            settingsButton.tap()
            sleep(2)
            captureScreenshot(app: app, lang: lang, view: "settings")

            // 3. Notifications
            let notifButton = app.buttons["SettingsView.notificationsButton"]
            XCTAssertTrue(notifButton.waitForExistence(timeout: 5), "Notifications button not found for \(lang)")
            notifButton.tap()
            sleep(2)
            captureScreenshot(app: app, lang: lang, view: "notifications")

            // 4. Back to Settings, back to Main
            let notifBackButton = app.buttons["NotificationsSettingsView.backButton"]
            XCTAssertTrue(notifBackButton.waitForExistence(timeout: 5))
            notifBackButton.tap()
            sleep(1)

            let settingsBackButton = app.buttons["SettingsView.backButton"]
            XCTAssertTrue(settingsBackButton.waitForExistence(timeout: 5))
            settingsBackButton.tap()
            sleep(1)

            // 5. About
            let aboutButton = app.buttons["MainView.aboutButton"]
            XCTAssertTrue(aboutButton.waitForExistence(timeout: 5), "About button not found for \(lang)")
            aboutButton.tap()
            sleep(2)
            captureScreenshot(app: app, lang: lang, view: "about")

            app.terminate()

            // 6. Full-screen notification (separate launch)
            let fsApp = XCUIApplication()
            fsApp.launchEnvironment["SCREENSHOT_LANGUAGE"] = lang
            fsApp.launchEnvironment["SCREENSHOT_FULLSCREEN"] = "1"
            fsApp.launchArguments += ["-AppleLanguages", "(\(lang))", "-AppleLocale", lang]
            fsApp.launch()
            sleep(3)
            captureFullScreenshot(app: fsApp, lang: lang, view: "fullscreen")
            fsApp.terminate()
        }
    }

    private func captureFullScreenshot(app: XCUIApplication, lang: String, view: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(lang)_\(view)"
        attachment.lifetime = .keepAlways
        add(attachment)
        NSLog("SCREENSHOT OK: \(lang)/\(view) full screen")
    }

    private func captureScreenshot(app: XCUIApplication, lang: String, view: String) {
        let window = app.windows.firstMatch
        guard window.waitForExistence(timeout: 5) else {
            NSLog("SCREENSHOT ERROR: No window for \(lang)/\(view)")
            return
        }

        // Wait for the window to have a valid (non-zero) frame
        var windowFrame = window.frame
        for _ in 0..<10 {
            if windowFrame.width > 0 && windowFrame.height > 0 {
                break
            }
            sleep(1)
            windowFrame = window.frame
        }

        guard windowFrame.width > 0 && windowFrame.height > 0 else {
            NSLog("SCREENSHOT ERROR: Zero window frame for \(lang)/\(view): \(windowFrame)")
            return
        }

        NSLog("SCREENSHOT: \(lang)/\(view) windowFrame=\(windowFrame)")

        let fullScreenshot = XCUIScreen.main.screenshot()
        let fullPNG = fullScreenshot.pngRepresentation

        guard let nsImage = NSImage(data: fullPNG),
              let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            NSLog("SCREENSHOT ERROR: Failed to process image for \(lang)/\(view)")
            return
        }

        let scale = CGFloat(cgImage.width) / nsImage.size.width

        let hPad: CGFloat = 20
        let bottomPad: CGFloat = 20

        let cropPointsRect = CGRect(
            x: max(0, windowFrame.minX - hPad),
            y: 0,
            width: windowFrame.width + hPad * 2,
            height: windowFrame.maxY + bottomPad
        )

        let cropPixelRect = CGRect(
            x: cropPointsRect.minX * scale,
            y: cropPointsRect.minY * scale,
            width: cropPointsRect.width * scale,
            height: cropPointsRect.height * scale
        )

        let safeCropRect = cropPixelRect.intersection(
            CGRect(x: 0, y: 0, width: cgImage.width, height: cgImage.height)
        )

        NSLog("SCREENSHOT: \(lang)/\(view) cropPixel=\(cropPixelRect) safe=\(safeCropRect) imgSize=\(cgImage.width)x\(cgImage.height)")

        guard !safeCropRect.isEmpty,
              let croppedCGImage = cgImage.cropping(to: safeCropRect) else {
            NSLog("SCREENSHOT ERROR: Crop failed for \(lang)/\(view)")
            return
        }

        let bitmapRep = NSBitmapImageRep(cgImage: croppedCGImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            NSLog("SCREENSHOT ERROR: PNG encoding failed for \(lang)/\(view)")
            return
        }

        NSLog("SCREENSHOT OK: \(lang)/\(view) \(croppedCGImage.width)x\(croppedCGImage.height)")

        let attachment = XCTAttachment(data: pngData, uniformTypeIdentifier: "public.png")
        attachment.name = "\(lang)_\(view)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
