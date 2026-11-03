import XCTest

final class TeachablyUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testFirstAdventureAndMemorySurviveRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        // A new suite exercises first-run behaviour without erasing user data.
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.tests.\(UUID().uuidString)"
        app.launch()
        XCTAssertTrue(app.staticTexts["You already have\nso much to share."].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Interests: 7 · Adventures: 42"].exists)
        let maths = app.buttons.containing(.staticText, identifier: "Maths & numbers").firstMatch
        maths.tap()
        XCTAssertTrue(app.staticTexts["Interests: 6 · Adventures: 36"].exists)
        maths.tap()
        XCTAssertTrue(app.staticTexts["Interests: 7 · Adventures: 42"].exists)
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
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.wander.tests.\(UUID().uuidString)"
        app.launchArguments += ["--demo"]
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
    func testAppleGenerationRestoresAnIdeaOrPreservesTheMapOnServiceFailure() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.apple.tests.\(UUID().uuidString)"
        app.launchArguments += ["--demo", "--apple-ai"]
        app.launch()
        app.tabBars.buttons["Wander"].tap()
        let ready = app.staticTexts["Choose an interest or ask a question to generate a fresh idea here."]
        guard ready.waitForExistence(timeout: 10) else {
            attachScreenshot("Apple model availability", app: app)
            throw XCTSkip("Apple Intelligence is unavailable on this simulator. The live provider is verified separately on a supported host.")
        }
        let query = app.textFields["Explore a topic"]
        query.tap()
        query.typeText("Why do rainbows form?")
        app.buttons["Explore topic"].tap()
        let source = app.staticTexts["wander.source.apple"]
        let failure = app.staticTexts["wander.error"]
        let completed = expectation(for: NSPredicate { _, _ in source.exists || failure.exists }, evaluatedWith: nil)
        wait(for: [completed], timeout: 90)
        if failure.exists {
            // Some simulator runtimes advertise availability but cannot load
            // their model assets. Exercise the actual service failure path.
            XCTAssertTrue(app.staticTexts["wander.source.library"].exists)
            XCTAssertTrue(app.buttons["Coding & logic"].exists)
            XCTAssertTrue(query.isEnabled)
            XCTAssertFalse(source.exists)
            attachScreenshot("Apple service failure preserves current map", app: app)
            app.buttons["Dismiss message"].tap()
            app.buttons["Wander content source"].tap()
            app.buttons["Activity library"].tap()
            app.buttons["Coding & logic"].tap()
            XCTAssertTrue(app.buttons["Be my friendly robot"].waitForExistence(timeout: 5))
            attachScreenshot("Library usable after Apple service failure", app: app)
            return
        }
        XCTAssertTrue(source.exists)
        XCTAssertTrue(app.staticTexts["THE IDEA"].exists)
        attachScreenshot("Apple generated explanation", app: app)
        app.buttons["wander.pin"].tap()
        app.terminate()
        app.launch()
        app.tabBars.buttons["Wander"].tap()
        XCTAssertTrue(source.waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["wander.pin"].label, "Unpin this idea")
        attachScreenshot("Apple generated idea restored", app: app)
    }

    @MainActor
    func testEverySupportedLanguageLocalizesOnboardingTodayAndMemories() throws {
        let languages: [(code: String, today: String, memories: String)] = [
            ("en", "Today", "Memories"),
            ("zh-Hans", "今天", "回忆"),
            ("zh-Hant", "今天", "回憶"),
            ("ja", "今日", "思い出"),
            ("es", "Hoy", "Recuerdos"),
            ("id", "Hari ini", "Kenangan")
        ]
        var englishActivityTitle = ""
        for language in languages {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(language.code))", "-AppleLocale", language.code]
            app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.localization.\(UUID().uuidString)"
            app.launch()
            let welcome = app.staticTexts["skills.heading"]
            XCTAssertTrue(welcome.waitForExistence(timeout: 10), language.code)
            if language.code != "en" {
                XCTAssertNotEqual(welcome.label, "You already have\nso much to share.", language.code)
            }
            app.buttons["skills.save"].tap()
            let heading = app.staticTexts["today.heading"]
            XCTAssertTrue(heading.waitForExistence(timeout: 10), language.code)
            XCTAssertEqual(app.tabBars.buttons.element(boundBy: 0).label, language.today, language.code)
            let title = app.staticTexts["today.activity.title"].label
            XCTAssertFalse(title.isEmpty)
            if language.code == "en" { englishActivityTitle = title }
            else {
                XCTAssertNotEqual(heading.label, "Little moments.\nBig discoveries.", language.code)
                XCTAssertNotEqual(title, englishActivityTitle, language.code)
            }
            attachScreenshot("Today · \(language.code)", app: app)
            app.tabBars.buttons.element(boundBy: 4).tap()
            XCTAssertTrue(app.navigationBars[language.memories].waitForExistence(timeout: 5), language.code)
            app.terminate()
        }
    }

    @MainActor
    private func attachScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
