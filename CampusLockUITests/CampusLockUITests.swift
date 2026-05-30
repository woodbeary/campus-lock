import XCTest

final class CampusLockUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSetupStartFocusAndUnlockFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Lock"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["lock.startFocus"].waitForExistence(timeout: 5))

        app.buttons["lock.startFocus"].tap()
        XCTAssertTrue(app.staticTexts["lock.lockedTitle"].waitForExistence(timeout: 3))

        app.buttons["lock.unlock"].tap()
        XCTAssertTrue(app.staticTexts["lock.unlockedTitle"].waitForExistence(timeout: 3))
    }

    func testPrimaryTabActionsStayReachable() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        assertTabAction("Apps", actionIdentifier: "apps.chooseSpecific", app: app)
        assertTabAction("Zone", actionIdentifier: "zone.enable", app: app)
        assertTabAction("Stats", actionIdentifier: "insights.prepareCSV", app: app)
        assertTabAction("Attend", actionIdentifier: "attendance.enter", app: app)
        XCTAssertTrue(app.buttons["attendance.exit"].isHittable)
    }

    private func assertTabAction(_ tabLabel: String, actionIdentifier: String, app: XCUIApplication) {
        let tab = app.tabBars.buttons[tabLabel]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(tabLabel) tab should exist")
        tab.tap()

        let action = app.buttons[actionIdentifier]
        XCTAssertTrue(action.waitForExistence(timeout: 5), "\(actionIdentifier) should exist")
        XCTAssertTrue(action.isHittable, "\(actionIdentifier) should be reachable")
        XCTAssertGreaterThan(action.frame.minY, app.frame.midY, "\(actionIdentifier) should stay in the predictable bottom action area")
    }
}
