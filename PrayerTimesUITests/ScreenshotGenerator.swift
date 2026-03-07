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
