import XCTest

@MainActor
final class CampusLockUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSetupScreenKeepsFooterAndFixedAction() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-setup-required"]
        app.launch()

        XCTAssertTrue(tabButton("Lock", app: app).waitForExistence(timeout: 5))
        assertFooterTabsStayReachable(app)
        XCTAssertTrue(app.buttons["setup.continue"].waitForExistence(timeout: 5))
        assertActionSitsAboveFooter("setup.continue", app: app)
    }

    func testSetupStartFocusAndUnlockFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(tabButton("Lock", app: app).waitForExistence(timeout: 5))
        assertFooterTabsStayReachable(app)
        XCTAssertTrue(app.buttons["lock.startFocus"].waitForExistence(timeout: 5))
        assertActionSitsAboveFooter("lock.startFocus", app: app)

        app.buttons["lock.startFocus"].tap()
        XCTAssertTrue(app.staticTexts["lock.lockedTitle"].waitForExistence(timeout: 3))
        assertActionSitsAboveFooter("lock.unlock", app: app)

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
        let tab = tabButton(tabLabel, app: app)
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(tabLabel) tab should exist")
        tab.tap()

        let action = app.buttons[actionIdentifier]
        XCTAssertTrue(action.waitForExistence(timeout: 5), "\(actionIdentifier) should exist")
        XCTAssertTrue(action.isHittable, "\(actionIdentifier) should be reachable")
        assertActionSitsAboveFooter(actionIdentifier, app: app)
    }

    private func assertFooterTabsStayReachable(_ app: XCUIApplication) {
        for tabLabel in ["Lock", "Apps", "Zone", "Stats", "Attend"] {
            let tab = tabButton(tabLabel, app: app)
            XCTAssertTrue(tab.waitForExistence(timeout: 5), "\(tabLabel) tab should exist")
            XCTAssertTrue(tab.isHittable, "\(tabLabel) tab should be hittable")
            XCTAssertGreaterThan(tab.frame.midY, app.frame.midY, "\(tabLabel) should stay in the native footer area")
            XCTAssertLessThanOrEqual(tab.frame.maxY, app.frame.maxY, "\(tabLabel) should not be cropped below the screen")
        }
    }

    private func assertActionSitsAboveFooter(_ actionIdentifier: String, app: XCUIApplication) {
        let action = app.buttons[actionIdentifier]
        let footer = tabButton("Lock", app: app)
        XCTAssertTrue(action.waitForExistence(timeout: 5), "\(actionIdentifier) should exist")
        XCTAssertTrue(footer.waitForExistence(timeout: 5), "footer should exist")
        XCTAssertTrue(action.isHittable, "\(actionIdentifier) should be hittable")
        XCTAssertGreaterThan(action.frame.minY, app.frame.midY, "\(actionIdentifier) should stay in the predictable bottom action area")
        XCTAssertLessThan(action.frame.maxY, footer.frame.minY, "\(actionIdentifier) should not overlap the footer")
        XCTAssertGreaterThan(footer.frame.minY - action.frame.maxY, 2, "\(actionIdentifier) should leave visible breathing room above the footer")
        XCTAssertGreaterThanOrEqual(action.frame.minY, app.frame.minY, "\(actionIdentifier) should not be cropped above the screen")
    }

    private func tabButton(_ label: String, app: XCUIApplication) -> XCUIElement {
        app.tabBars.buttons[label]
    }
}
