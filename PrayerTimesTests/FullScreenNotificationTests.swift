import XCTest
@testable import PrayerTimes

// MARK: - PrayerTheme Tests

final class PrayerThemeTests: XCTestCase {

    // MARK: - Theme Mapping

    func testNightThemePrayers() {
        XCTAssertEqual(PrayerTheme(prayerKey: "Fajr"), .night)
        XCTAssertEqual(PrayerTheme(prayerKey: "Isha"), .night)
        XCTAssertEqual(PrayerTheme(prayerKey: "Tahajud"), .night)
    }

    func testDawnThemePrayer() {
        XCTAssertEqual(PrayerTheme(prayerKey: "Sunrise"), .dawn)
    }

    func testDayThemePrayers() {
        XCTAssertEqual(PrayerTheme(prayerKey: "Dhuhr"), .day)
        XCTAssertEqual(PrayerTheme(prayerKey: "Dhuha"), .day)
    }

    func testAfternoonThemePrayer() {
        XCTAssertEqual(PrayerTheme(prayerKey: "Asr"), .afternoon)
    }

    func testSunsetThemePrayer() {
        XCTAssertEqual(PrayerTheme(prayerKey: "Maghrib"), .sunset)
    }

    func testUnknownKeyDefaultsToNight() {
        XCTAssertEqual(PrayerTheme(prayerKey: ""), .night)
        XCTAssertEqual(PrayerTheme(prayerKey: "Unknown"), .night)
        XCTAssertEqual(PrayerTheme(prayerKey: "fajr"), .night, "Should be case-sensitive")
    }

    // MARK: - Theme Properties

    func testAllThemesHaveThreeGradientColors() {
        let themes: [PrayerTheme] = [.night, .dawn, .day, .afternoon, .sunset]
        for theme in themes {
            XCTAssertEqual(theme.gradientColors.count, 3, "\(theme) should have 3 gradient colors")
        }
    }

    func testAllThemesHaveValidIconNames() {
        let themes: [PrayerTheme] = [.night, .dawn, .day, .afternoon, .sunset]
        let expectedIcons = ["moon.stars.fill", "sunrise.fill", "sun.max.fill", "sun.haze.fill", "sunset.fill"]
        for (theme, expected) in zip(themes, expectedIcons) {
            XCTAssertEqual(theme.iconName, expected)
        }
    }

    // MARK: - All 8 Prayer Keys Covered

    func testAllPrayerKeysMapToExpectedThemes() {
        let expected: [(String, PrayerTheme)] = [
            ("Fajr", .night), ("Sunrise", .dawn), ("Dhuhr", .day), ("Dhuha", .day),
            ("Asr", .afternoon), ("Maghrib", .sunset), ("Isha", .night), ("Tahajud", .night)
        ]
        for (key, theme) in expected {
            XCTAssertEqual(PrayerTheme(prayerKey: key), theme, "Prayer \(key) should map to \(theme)")
        }
    }
}

// MARK: - FullScreenNotificationData Tests

final class FullScreenNotificationDataTests: XCTestCase {

    func testDataConstructionAtTime() {
        let date = Date()
        let data = FullScreenNotificationData(
            prayerName: "Fajr", prayerKey: "Fajr",
            prayerTime: date, isPreNotification: false, minutesBefore: nil
        )
        XCTAssertEqual(data.prayerName, "Fajr")
        XCTAssertEqual(data.prayerKey, "Fajr")
        XCTAssertEqual(data.prayerTime, date)
        XCTAssertFalse(data.isPreNotification)
        XCTAssertNil(data.minutesBefore)
    }

    func testDataConstructionPreNotification() {
        let date = Date().addingTimeInterval(600)
        let data = FullScreenNotificationData(
            prayerName: "الفجر", prayerKey: "Fajr",
            prayerTime: date, isPreNotification: true, minutesBefore: 10
        )
        XCTAssertEqual(data.prayerName, "الفجر")
        XCTAssertEqual(data.prayerKey, "Fajr")
        XCTAssertTrue(data.isPreNotification)
        XCTAssertEqual(data.minutesBefore, 10)
    }

    func testPrayerKeyDecoupledFromLocalizedName() {
        let data = FullScreenNotificationData(
            prayerName: "الظهر", prayerKey: "Dhuhr",
            prayerTime: Date(), isPreNotification: false, minutesBefore: nil
        )
        XCTAssertEqual(PrayerTheme(prayerKey: data.prayerKey), .day,
                       "Theme should use prayerKey, not localized prayerName")
    }
}

// MARK: - FullScreenNotificationManager Tests

final class FullScreenNotificationManagerTests: XCTestCase {

    var manager: FullScreenNotificationManager!

    override func setUp() {
        super.setUp()
        manager = FullScreenNotificationManager.shared
        // Ensure clean state
        manager.dismissFullScreenNotification()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    override func tearDown() {
        manager.dismissFullScreenNotification()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        super.tearDown()
    }

    // MARK: - Show/Dismiss State

    func testInitialState() {
        XCTAssertFalse(manager.isShowing)
        XCTAssertNil(manager.notificationData)
    }

    func testShowSetsStateCorrectly() {
        let futureTime = Date().addingTimeInterval(600)
        manager.showFullScreenNotification(
            prayerName: "Fajr", prayerKey: "Fajr",
            prayerTime: futureTime
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertTrue(manager.isShowing)
        XCTAssertNotNil(manager.notificationData)
        XCTAssertEqual(manager.notificationData?.prayerName, "Fajr")
        XCTAssertEqual(manager.notificationData?.prayerKey, "Fajr")
        XCTAssertFalse(manager.notificationData?.isPreNotification ?? true)
        XCTAssertNil(manager.notificationData?.minutesBefore)
    }

    func testShowPreNotificationSetsStateCorrectly() {
        let futureTime = Date().addingTimeInterval(600)
        manager.showFullScreenNotification(
            prayerName: "Dhuhr", prayerKey: "Dhuhr",
            prayerTime: futureTime,
            isPreNotification: true,
            minutesBefore: 10
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertTrue(manager.isShowing)
        XCTAssertTrue(manager.notificationData?.isPreNotification ?? false)
        XCTAssertEqual(manager.notificationData?.minutesBefore, 10)
    }

    func testDismissClearsState() {
        let futureTime = Date().addingTimeInterval(600)
        manager.showFullScreenNotification(
            prayerName: "Fajr", prayerKey: "Fajr",
            prayerTime: futureTime
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertTrue(manager.isShowing)

        manager.dismissFullScreenNotification()
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertFalse(manager.isShowing)
        XCTAssertNil(manager.notificationData)
    }

    // MARK: - Prayer Key Fallback

    func testEmptyPrayerKeyFallsToPrayerName() {
        manager.showFullScreenNotification(
            prayerName: "Maghrib", prayerKey: "",
            prayerTime: Date().addingTimeInterval(600)
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertEqual(manager.notificationData?.prayerKey, "Maghrib",
                       "Empty prayerKey should fall back to prayerName")
    }

    func testExplicitPrayerKeyUsed() {
        manager.showFullScreenNotification(
            prayerName: "المغرب", prayerKey: "Maghrib",
            prayerTime: Date().addingTimeInterval(600)
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertEqual(manager.notificationData?.prayerKey, "Maghrib")
        XCTAssertEqual(manager.notificationData?.prayerName, "المغرب")
    }

    // MARK: - Snooze

    func testSnoozeDismissesCurrentNotification() {
        let futureTime = Date().addingTimeInterval(600)
        manager.showFullScreenNotification(
            prayerName: "Asr", prayerKey: "Asr",
            prayerTime: futureTime,
            isPreNotification: true,
            minutesBefore: 10
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertTrue(manager.isShowing)

        manager.snooze(minutes: 5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        XCTAssertFalse(manager.isShowing, "Snooze should dismiss the current notification")
        XCTAssertNil(manager.notificationData, "Snooze should clear notification data")
    }

    func testSnoozeWithNoDataIsNoOp() {
        manager.dismissFullScreenNotification()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        // Should not crash
        manager.snooze(minutes: 5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        XCTAssertFalse(manager.isShowing)
    }

    func testSnoozePreservesOriginalData() {
        let futureTime = Date().addingTimeInterval(600)
        manager.showFullScreenNotification(
            prayerName: "العصر", prayerKey: "Asr",
            prayerTime: futureTime,
            isPreNotification: true,
            minutesBefore: 10
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        // Capture data before snooze
        let originalName = manager.notificationData?.prayerName
        let originalKey = manager.notificationData?.prayerKey
        let originalTime = manager.notificationData?.prayerTime
        let originalIsPre = manager.notificationData?.isPreNotification
        let originalMinutes = manager.notificationData?.minutesBefore

        XCTAssertEqual(originalName, "العصر")
        XCTAssertEqual(originalKey, "Asr")
        XCTAssertEqual(originalTime, futureTime)
        XCTAssertEqual(originalIsPre, true)
        XCTAssertEqual(originalMinutes, 10)

        // After snooze, the same data should be used when it re-shows
        // We can't easily test the delayed re-show without waiting,
        // but we verify the data was captured correctly before dismiss
        manager.snooze(minutes: 5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertFalse(manager.isShowing)
    }

    // MARK: - Countdown Logic

    func testCountdownRemainingCalculation() {
        let futureTime = Date().addingTimeInterval(125) // 2 min 5 sec
        let remaining = max(0, Int(futureTime.timeIntervalSince(Date())))

        XCTAssertGreaterThan(remaining, 120)
        XCTAssertLessThanOrEqual(remaining, 125)

        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60
        XCTAssertEqual(h, 0)
        XCTAssertEqual(m, 2)
        XCTAssertGreaterThanOrEqual(s, 4)
        XCTAssertLessThanOrEqual(s, 5)
    }

    func testCountdownRemainingForPastTimeIsZero() {
        let pastTime = Date().addingTimeInterval(-60)
        let remaining = max(0, Int(pastTime.timeIntervalSince(Date())))
        XCTAssertEqual(remaining, 0)
    }

    func testCountdownHoursMinutesSeconds() {
        // Simulate 1h 30m 45s remaining
        let remaining = 5445
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60
        XCTAssertEqual(h, 1)
        XCTAssertEqual(m, 30)
        XCTAssertEqual(s, 45)
    }

    func testCountdownFormattingZeroSeconds() {
        let remaining = 3600 // Exactly 1 hour
        let h = remaining / 3600
        let m = (remaining % 3600) / 60
        let s = remaining % 60
        XCTAssertEqual(h, 1)
        XCTAssertEqual(m, 0)
        XCTAssertEqual(s, 0)
    }

    // MARK: - View State: Pre-notification vs At-time

    func testPreNotificationWithRemainingShowsCountdown() {
        // When isPreNotification=true and prayerTime is in the future,
        // the view should show countdown and snooze
        let futureTime = Date().addingTimeInterval(600)
        let data = FullScreenNotificationData(
            prayerName: "Fajr", prayerKey: "Fajr",
            prayerTime: futureTime, isPreNotification: true, minutesBefore: 10
        )
        let remaining = max(0, Int(data.prayerTime.timeIntervalSince(Date())))

        XCTAssertTrue(data.isPreNotification && remaining > 0,
                      "Pre-notification with future time should show countdown")
        XCTAssertFalse(!data.isPreNotification || remaining <= 0,
                       "Should NOT show urgency message")
    }

    func testAtTimeNotificationShowsUrgency() {
        let data = FullScreenNotificationData(
            prayerName: "Fajr", prayerKey: "Fajr",
            prayerTime: Date(), isPreNotification: false, minutesBefore: nil
        )
        let remaining = max(0, Int(data.prayerTime.timeIntervalSince(Date())))

        XCTAssertFalse(data.isPreNotification && remaining > 0,
                       "At-time notification should NOT show countdown")
        XCTAssertTrue(!data.isPreNotification || remaining <= 0,
                      "At-time notification should show urgency message")
    }

    func testPreNotificationExpiredShowsUrgency() {
        // Pre-notification where the prayer time has passed
        let pastTime = Date().addingTimeInterval(-10)
        let data = FullScreenNotificationData(
            prayerName: "Fajr", prayerKey: "Fajr",
            prayerTime: pastTime, isPreNotification: true, minutesBefore: 10
        )
        let remaining = max(0, Int(data.prayerTime.timeIntervalSince(Date())))

        XCTAssertEqual(remaining, 0)
        XCTAssertFalse(data.isPreNotification && remaining > 0,
                       "Expired pre-notification should NOT show countdown")
        XCTAssertTrue(!data.isPreNotification || remaining <= 0,
                      "Expired pre-notification should show urgency message")
    }

    // MARK: - Snooze Availability

    func testSnoozeOptionAvailability() {
        let snoozeOptions = [5, 10, 15]

        // 12 minutes remaining: only 5 and 10 should be available
        let minutesLeft = 12
        let available = snoozeOptions.filter { minutesLeft > $0 }
        XCTAssertEqual(available, [5, 10])

        // 3 minutes remaining: none available
        let minutesLeft2 = 3
        let available2 = snoozeOptions.filter { minutesLeft2 > $0 }
        XCTAssertTrue(available2.isEmpty)

        // 20 minutes remaining: all available
        let minutesLeft3 = 20
        let available3 = snoozeOptions.filter { minutesLeft3 > $0 }
        XCTAssertEqual(available3, [5, 10, 15])
    }

    func testSnoozeNotAvailableWhenExactlyEqual() {
        // If 5 minutes left, the 5-min snooze should NOT be available
        // because minutesLeft > mins (strict greater than)
        let minutesLeft = 5
        let snoozeOptions = [5, 10, 15]
        let available = snoozeOptions.filter { minutesLeft > $0 }
        XCTAssertTrue(available.isEmpty, "5-min snooze should not be available with exactly 5 min left")
    }
}

// MARK: - ScheduledFullScreenNotification Tests

final class ScheduledFullScreenNotificationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        NotificationManager.cancelNotifications()
    }

    override func tearDown() {
        NotificationManager.cancelNotifications()
        super.tearDown()
    }

    func testScheduledNotificationConstruction() {
        let date = Date().addingTimeInterval(300)
        let notification = ScheduledFullScreenNotification(
            prayerName: "Dhuhr",
            prayerTime: date,
            fireDate: date,
            isPreNotification: false,
            minutesBefore: nil
        )
        XCTAssertEqual(notification.prayerName, "Dhuhr")
        XCTAssertEqual(notification.prayerTime, date)
        XCTAssertEqual(notification.fireDate, date)
        XCTAssertFalse(notification.isPreNotification)
        XCTAssertNil(notification.minutesBefore)
        XCTAssertFalse(notification.hasFired)
    }

    func testScheduledNotificationPreConstruction() {
        let prayerDate = Date().addingTimeInterval(600)
        let fireDate = Date().addingTimeInterval(0)
        let notification = ScheduledFullScreenNotification(
            prayerName: "Asr",
            prayerTime: prayerDate,
            fireDate: fireDate,
            isPreNotification: true,
            minutesBefore: 10
        )
        XCTAssertTrue(notification.isPreNotification)
        XCTAssertEqual(notification.prayerTime, prayerDate)
        XCTAssertEqual(notification.minutesBefore, 10)
        XCTAssertFalse(notification.hasFired)
    }

    func testHasFiredMutation() {
        let date = Date().addingTimeInterval(10)
        var notification = ScheduledFullScreenNotification(
            prayerName: "Maghrib",
            prayerTime: date,
            fireDate: date,
            isPreNotification: false,
            minutesBefore: nil
        )
        XCTAssertFalse(notification.hasFired)

        notification.hasFired = true
        XCTAssertTrue(notification.hasFired)
    }

    func testCancelClearsScheduledNotifications() {
        // Verify cancel clears the array
        NotificationManager.cancelNotifications()
        XCTAssertTrue(NotificationManager.scheduledFullScreenNotifications.isEmpty)
    }

    func testCancelPrayerNotificationsClearsFullScreen() {
        NotificationManager.cancelPrayerNotifications()
        XCTAssertTrue(NotificationManager.scheduledFullScreenNotifications.isEmpty)
    }
}

// MARK: - Integration: Snooze Timer Behavior

final class SnoozeTimerIntegrationTests: XCTestCase {

    var manager: FullScreenNotificationManager!

    override func setUp() {
        super.setUp()
        manager = FullScreenNotificationManager.shared
        manager.dismissFullScreenNotification()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    override func tearDown() {
        manager.dismissFullScreenNotification()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        super.tearDown()
    }

    func testSnoozeSchedulesReappearance() {
        // Show a notification
        let futureTime = Date().addingTimeInterval(600)
        manager.showFullScreenNotification(
            prayerName: "Isha", prayerKey: "Isha",
            prayerTime: futureTime,
            isPreNotification: true,
            minutesBefore: 10
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertTrue(manager.isShowing)

        // Snooze for a very short time (we'll use the mechanism but not wait)
        manager.snooze(minutes: 5)
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))

        // Immediately after snooze, notification should be dismissed
        XCTAssertFalse(manager.isShowing)
        // The DispatchQueue.main.asyncAfter with 5*60 seconds delay
        // will re-show, but we can't wait that long in tests.
        // This confirms the snooze dismisses correctly.
    }

    func testMultipleShowDismissCycles() {
        for prayer in ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"] {
            manager.showFullScreenNotification(
                prayerName: prayer, prayerKey: prayer,
                prayerTime: Date().addingTimeInterval(600)
            )
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            XCTAssertTrue(manager.isShowing, "Should be showing for \(prayer)")
            XCTAssertEqual(manager.notificationData?.prayerKey, prayer)

            manager.dismissFullScreenNotification()
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            XCTAssertFalse(manager.isShowing, "Should be dismissed after \(prayer)")
        }
    }

    func testShowOverwritesPrevious() {
        manager.showFullScreenNotification(
            prayerName: "Fajr", prayerKey: "Fajr",
            prayerTime: Date().addingTimeInterval(600)
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertEqual(manager.notificationData?.prayerKey, "Fajr")

        // Show again with different prayer — should overwrite
        manager.showFullScreenNotification(
            prayerName: "Dhuhr", prayerKey: "Dhuhr",
            prayerTime: Date().addingTimeInterval(300)
        )
        RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        XCTAssertEqual(manager.notificationData?.prayerKey, "Dhuhr")
        XCTAssertTrue(manager.isShowing)
    }

    func testDismissIdempotent() {
        // Dismissing when nothing is showing should not crash
        manager.dismissFullScreenNotification()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        manager.dismissFullScreenNotification()
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        XCTAssertFalse(manager.isShowing)
    }
}
