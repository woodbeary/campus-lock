import XCTest

@MainActor
final class CampusLockUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSetupStartFocusAndUnlockFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.buttons["tab.lock"].waitForExistence(timeout: 5))
        assertFooterTabsStayReachable(app)
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

        assertFooterTabsStayReachable(app)
        assertTabAction("Apps", actionIdentifier: "apps.chooseSpecific", app: app)
        assertTabAction("Zone", actionIdentifier: "zone.enable", app: app)
        assertTabAction("Stats", actionIdentifier: "insights.prepareCSV", app: app)
        assertTabAction("Attend", actionIdentifier: "attendance.enter", app: app)
        XCTAssertTrue(app.buttons["attendance.exit"].isHittable)
    }

    private func assertTabAction(_ tabLabel: String, actionIdentifier: String, app: XCUIApplication) {
        let tab = app.buttons["tab.\(tabLabel.lowercased())"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(tabLabel) tab should exist")
        tab.tap()

        let action = app.buttons[actionIdentifier]
        XCTAssertTrue(action.waitForExistence(timeout: 5), "\(actionIdentifier) should exist")
        XCTAssertTrue(action.isHittable, "\(actionIdentifier) should be reachable")
        XCTAssertGreaterThan(action.frame.minY, app.frame.midY, "\(actionIdentifier) should stay in the predictable bottom action area")
    }

    private func assertFooterTabsStayReachable(_ app: XCUIApplication) {
        for tabIdentifier in ["tab.lock", "tab.apps", "tab.zone", "tab.stats", "tab.attend"] {
            let tab = app.buttons[tabIdentifier]
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(tabIdentifier) should exist")
            XCTAssertTrue(tab.isHittable, "\(tabIdentifier) should be hittable")
            XCTAssertGreaterThan(tab.frame.midY, app.frame.midY, "\(tabIdentifier) should stay in the fixed footer area")
        }
    }
}
