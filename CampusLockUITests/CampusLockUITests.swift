import XCTest

@MainActor
final class CampusLockUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingRequiresPermissionsThenZoneBeforeHome() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-setup-required"]
        app.launch()

        XCTAssertFalse(app.buttons["home.settings"].exists, "onboarding should not show home actions")
        XCTAssertTrue(app.buttons["setup.continue"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["setup.continue"].isEnabled, "continue should stay disabled until required permissions are complete")
        XCTAssertFalse(app.staticTexts["Not set"].exists, "setup should not expose placeholder permission copy")
        assertActionSitsInBottomSafeArea("setup.continue", app: app)

        XCTAssertTrue(app.otherElements["setup.screenTime"].waitForExistence(timeout: 5))
        app.buttons["Allow"].tap()
        XCTAssertTrue(app.otherElements["setup.location"].waitForExistence(timeout: 5))
        app.buttons["Allow"].tap()
        XCTAssertTrue(app.otherElements["setup.ready"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["setup.continue"].isEnabled)

        app.buttons["setup.continue"].tap()
        XCTAssertFalse(app.buttons["home.settings"].exists, "zone onboarding should still hide home actions")
        XCTAssertTrue(app.buttons["zone.enable"].waitForExistence(timeout: 5))

        app.buttons["zone.enable"].tap()
        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["footer.menu"].exists)
        XCTAssertTrue(app.buttons["attendance.enter"].waitForExistence(timeout: 5))
    }

    func testAttendanceConfirmEnterHallPassAndExitFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["footer.menu"].exists)
        XCTAssertTrue(app.buttons["attendance.enter"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["attendance.class.selected"].exists)
        assertActionSitsInBottomSafeArea("attendance.enter", app: app)

        app.buttons["attendance.enter"].tap()
        XCTAssertTrue(app.otherElements["attendance.nfcSheet"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["attendance.nfc.manualEnter"].exists, "manual fallback should not appear before the NFC scan gets a chance to run")
        XCTAssertTrue(app.buttons["attendance.nfc.manualEnter"].waitForExistence(timeout: 5))
        app.buttons["attendance.nfc.manualEnter"].tap()

        XCTAssertFalse(app.buttons["attendance.enter"].exists)
        XCTAssertFalse(app.buttons["attendance.done"].exists, "active class should not be marked done while locked")
        XCTAssertTrue(app.otherElements["attendance.active.panel"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["attendance.active.elapsed"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["attendance.active.average"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["attendance.hallPass"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["attendance.exit"].waitForExistence(timeout: 5))
        assertActionSitsInBottomSafeArea("attendance.exit", app: app)

        app.buttons["attendance.hallPass"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        app.alerts.firstMatch.buttons["Start"].tap()
        XCTAssertTrue(app.otherElements["attendance.hallPass.status"].waitForExistence(timeout: 5))

        app.buttons["attendance.exit"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 3))
        app.alerts.firstMatch.buttons["Exit"].tap()
        XCTAssertFalse(app.buttons["attendance.enter"].exists)
        XCTAssertTrue(app.buttons["attendance.done"].waitForExistence(timeout: 5))
        assertActionSitsInBottomSafeArea("attendance.done", app: app)
    }

    func testHomeGearOwnsAppsZoneAndStats() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 5))
        app.buttons["home.settings"].tap()

        XCTAssertTrue(app.buttons["apps.chooseSpecific"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["settings.zone"].exists)
        XCTAssertTrue(app.buttons["settings.stats"].exists)
        XCTAssertTrue(app.buttons["settings.reset"].exists)
        XCTAssertFalse(app.staticTexts["Emergency Safe"].exists)
        XCTAssertFalse(app.otherElements["footer.menu"].exists)
        XCTAssertFalse(app.buttons["tab.stats"].exists)
        XCTAssertFalse(app.buttons["tab.apps"].exists)
        XCTAssertFalse(app.buttons["insights.prepareCSV"].exists)
    }

    private func assertActionSitsInBottomSafeArea(_ actionIdentifier: String, app: XCUIApplication) {
        let action = app.buttons[actionIdentifier]
        XCTAssertTrue(action.waitForExistence(timeout: 5), "\(actionIdentifier) should exist")
        XCTAssertGreaterThan(action.frame.minY, app.frame.midY, "\(actionIdentifier) should stay in the predictable bottom action area")
        XCTAssertLessThanOrEqual(action.frame.maxY, app.frame.maxY, "\(actionIdentifier) should not be cropped below the screen")
        XCTAssertGreaterThanOrEqual(action.frame.minY, app.frame.minY, "\(actionIdentifier) should not be cropped above the screen")
    }

}
