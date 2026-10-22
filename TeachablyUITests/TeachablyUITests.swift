import XCTest

final class TeachablyUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testFirstAdventureAndMemorySurviveRelaunch() throws {
        let app = XCUIApplication()
        // A new suite exercises first-run behaviour without erasing user data.
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.tests.\(UUID().uuidString)"
        app.launch()
        XCTAssertTrue(app.staticTexts["You already have\nso much to share."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["7 interests · 21 adventures"].exists)
        let maths = app.buttons.containing(.staticText, identifier: "Maths & numbers").firstMatch
        maths.tap()
        XCTAssertTrue(app.staticTexts["6 interests · 18 adventures"].exists)
        maths.tap()
        XCTAssertTrue(app.staticTexts["7 interests · 21 adventures"].exists)
        attachScreenshot("Your interests", app: app)
        let begin = app.buttons["Find our first adventure"]
        if !begin.isHittable { app.swipeUp() }
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        begin.tap()

        let adventure = app.buttons["Let's do this together"]
        XCTAssertTrue(adventure.waitForExistence(timeout: 5))
        attachScreenshot("Today", app: app)
        adventure.tap()
        app.buttons["Start our little adventure"].tap()
        XCTAssertTrue(app.buttons["Pause timer"].waitForExistence(timeout: 5))
        app.buttons["Pause timer"].tap()
        XCTAssertTrue(app.buttons["Resume timer"].exists)
        attachScreenshot("Together time", app: app)
        app.buttons["Finish for today"].tap()
        let note = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Memory note")).firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        note.typeText("We made something together.")
        app.buttons["Save our little memory"].tap()

        // The session returns to the detail view. Navigate to the root tabs.
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.tabBars.buttons["Memories"].tap()
        XCTAssertTrue(app.staticTexts["We made something together."].waitForExistence(timeout: 5))
        attachScreenshot("Memories", app: app)
        app.terminate()
        app.launch()
        app.tabBars.buttons["Memories"].tap()
        XCTAssertTrue(app.staticTexts["We made something together."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testWanderCanExplorePinRecallAndRestoreAfterRelaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.wander.tests.\(UUID().uuidString)"
        app.launchArguments = ["--demo"]
        app.launch()
        app.tabBars.buttons["Wander"].tap()
        let coding = app.buttons["Coding & logic"]
        XCTAssertTrue(coding.waitForExistence(timeout: 10))
        attachScreenshot("Wander map", app: app)
        coding.tap()
        let robot = app.buttons["Be my friendly robot"]
        XCTAssertTrue(robot.waitForExistence(timeout: 5))
        robot.tap()
        app.buttons["An example to try"].tap()
        XCTAssertTrue(app.staticTexts["TRY IT TOGETHER"].waitForExistence(timeout: 5))
        attachScreenshot("Wander explanation", app: app)
        let pin = app.buttons["wander.pin"]
        for _ in 0..<5 where !pin.isHittable { app.swipeUp() }
        XCTAssertTrue(pin.isHittable)
        pin.tap()
        app.buttons["Wander library"].tap()
        let note = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Pinned idea note")).firstMatch
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap()
        note.typeText("Try the robot game this weekend.")
        app.buttons["Save note"].tap()
        app.buttons["Done"].tap()
        app.terminate()
        app.launch()
        app.tabBars.buttons["Wander"].tap()
        XCTAssertTrue(app.staticTexts["An example to try"].waitForExistence(timeout: 5))
        app.buttons["Wander library"].tap()
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        XCTAssertEqual(note.value as? String, "Try the robot game this weekend.")
        attachScreenshot("Wander pinned note", app: app)
        app.segmentedControls.buttons["Explored"].tap()
        let search = app.textFields["Search explored ideas"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("A loop of silly moves")
        let result = app.buttons.containing(.staticText, identifier: "A loop of silly moves").firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        XCTAssertTrue(app.staticTexts["Found: A loop of silly moves"].waitForExistence(timeout: 5))
        attachScreenshot("Wander recall", app: app)
    }

    @MainActor
    private func attachScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
