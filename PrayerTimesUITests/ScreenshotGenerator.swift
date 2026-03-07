import XCTest

final class ScreenshotGenerator: XCTestCase {

    let languages = ["en", "ar", "id", "fa", "ur"]
    let views = ["main", "settings", "notifications", "about"]

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
            sleep(2)

            // 1. Main view
            captureScreenshot(app: app, lang: lang, view: "main")

            // 2. Settings
            let settingsButton = app.buttons["MainView.settingsButton"]
            XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button not found for \(lang)")
            settingsButton.tap()
            sleep(1)
            captureScreenshot(app: app, lang: lang, view: "settings")

            // 3. Notifications
            let notifButton = app.buttons["SettingsView.notificationsButton"]
            XCTAssertTrue(notifButton.waitForExistence(timeout: 5), "Notifications button not found for \(lang)")
            notifButton.tap()
            sleep(1)
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
            sleep(1)
            captureScreenshot(app: app, lang: lang, view: "about")

            app.terminate()
        }
    }

    private func captureScreenshot(app: XCUIApplication, lang: String, view: String) {
        let window = app.windows.firstMatch
        let screenshot = window.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(lang)_\(view)"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Write to temp directory (test runner is sandboxed)
        let tempDir = NSTemporaryDirectory() + "screenshots/\(lang)"
        try? FileManager.default.createDirectory(
            atPath: tempDir,
            withIntermediateDirectories: true
        )

        let outputPath = "\(tempDir)/\(view).png"
        let pngData = screenshot.pngRepresentation
        do {
            try pngData.write(to: URL(fileURLWithPath: outputPath))
            NSLog("Screenshot saved: \(outputPath)")
        } catch {
            NSLog("Failed to write screenshot: \(error)")
        }
    }
}
