import XCTest

final class PrayerTimesUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Skip onboarding and inject a fake location (Mecca) for all UI tests
        app.launchEnvironment["TESTING"] = "1"
        app.launchEnvironment["TESTING_LOCATION"] = "21.4225,39.8262,Mecca"
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testAppLaunchesWithoutOnboarding() throws {
        app.launch()

        // The main view should appear (menu bar panel), not the onboarding window
        let settingsButton = app.buttons["MainView.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10),
            "Main view should be visible after launch with onboarding skipped")
    }

    func testNavigateToSettings() throws {
        app.launch()

        let settingsButton = app.buttons["MainView.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()

        let notifButton = app.buttons["SettingsView.notificationsButton"]
        XCTAssertTrue(notifButton.waitForExistence(timeout: 5),
            "Settings view should be visible after tapping settings button")
    }

    func testNavigateToNotificationSettings() throws {
        app.launch()

        let settingsButton = app.buttons["MainView.settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10))
        settingsButton.tap()

        let notifButton = app.buttons["SettingsView.notificationsButton"]
        XCTAssertTrue(notifButton.waitForExistence(timeout: 5))
        notifButton.tap()

        let backButton = app.buttons["NotificationsSettingsView.backButton"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5),
            "Notification settings view should be visible")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                let perfApp = XCUIApplication()
                perfApp.launchEnvironment["TESTING"] = "1"
                perfApp.launchEnvironment["TESTING_LOCATION"] = "21.4225,39.8262,Mecca"
                perfApp.launch()
            }
        }
    }
}
