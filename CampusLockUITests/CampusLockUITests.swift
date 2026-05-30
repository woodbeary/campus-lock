import XCTest

final class CampusLockUITests: XCTestCase {
    func testSetupStartFocusAndUnlockFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        XCTAssertTrue(app.tabBars.buttons["Lock"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Ready"].exists || app.navigationBars["Ready"].exists)

        app.buttons["lock.startFocus"].tap()
        XCTAssertTrue(app.staticTexts["lock.lockedTitle"].waitForExistence(timeout: 3))

        app.buttons["lock.unlock"].tap()
        XCTAssertTrue(app.staticTexts["lock.unlockedTitle"].waitForExistence(timeout: 3))
    }
}
