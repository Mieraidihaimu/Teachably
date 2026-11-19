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
        XCTAssertTrue(app.staticTexts["welcome.heading"].waitForExistence(timeout: 10))
        attachScreenshot("Welcome", app: app)
        app.buttons["welcome.interests"].tap()
        let begin = app.buttons["skills.save"]
        XCTAssertTrue(begin.waitForExistence(timeout: 5))
        XCTAssertFalse(begin.isEnabled)
        let nature = app.buttons["skills.interest.nature"]
        if !nature.isHittable { app.swipeUp() }
        nature.tap()
        XCTAssertTrue(begin.isEnabled)
        attachScreenshot("Your interests", app: app)
        begin.tap()

        let adventure = app.buttons["today.activity.open"]
        XCTAssertTrue(adventure.waitForExistence(timeout: 5))
        let skill = app.descendants(matching: .any)["today.activity.skill"].firstMatch
        XCTAssertEqual(skill.label, "Nature & outdoors")
        attachScreenshot("Today", app: app)
        adventure.tap()
        app.buttons["Start activity"].tap()
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
        openMemories(in: app)
        XCTAssertTrue(app.staticTexts["We made something together."].waitForExistence(timeout: 5))
        attachScreenshot("Memories", app: app)
        app.terminate()
        app.launch()
        XCTAssertTrue(adventure.waitForExistence(timeout: 5))
        XCTAssertEqual(skill.label, "Nature & outdoors")
        XCTAssertFalse(app.staticTexts["welcome.heading"].exists)
        openMemories(in: app)
        XCTAssertTrue(app.staticTexts["We made something together."].waitForExistence(timeout: 5))
    }

    @MainActor
    func testTodayShortIdeaRemainsSelectedAfterRelaunch() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB", "--demo"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.today.tests.\(UUID().uuidString)"
        app.launch()

        let title = app.staticTexts["today.activity.title"]
        let duration = app.descendants(matching: .any)["today.activity.duration"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let first = title.label
        let short = app.buttons["today.filter.fifteenMinutes"]
        if !short.isHittable { app.swipeUp() }
        XCTAssertTrue(short.isHittable)
        short.tap()
        app.buttons["today.another-idea"].tap()
        XCTAssertNotEqual(title.label, first)
        XCTAssertTrue(duration.label.contains("15 min"))
        let newTitle = title.label

        app.terminate()
        app.launch()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, newTitle)
        XCTAssertTrue(duration.label.contains("15 min"))
    }

    @MainActor
    func testShowAndTellOpensPicturesAndRevealsStoryOnDemand() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB", "--demo"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.stories.tests.\(UUID().uuidString)"
        app.launch()

        app.tabBars.buttons["More"].tap()
        app.buttons["more.show-and-tell"].tap()
        XCTAssertTrue(app.staticTexts["60 stories in English"].waitForExistence(timeout: 5))
        let story = app.buttons["show-and-tell.story.kite-in-the-tree"]
        XCTAssertTrue(story.isHittable)
        attachScreenshot("Show and Tell mosaics", app: app)
        story.tap()

        let read = app.buttons["show-and-tell.read"]
        XCTAssertTrue(read.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["show-and-tell.record.start"].isHittable)
        for number in 1...6 {
            XCTAssertTrue(app.buttons["show-and-tell.picture.\(number)"].exists)
        }
        XCTAssertFalse(app.staticTexts["show-and-tell.text.1"].exists)
        attachScreenshot("Six picture sequence", app: app)

        app.buttons["show-and-tell.picture.2"].tap()
        XCTAssertTrue(app.staticTexts["Picture 2 of 6"].waitForExistence(timeout: 5))
        app.buttons["Next picture"].tap()
        XCTAssertTrue(app.staticTexts["Picture 3 of 6"].exists)
        XCTAssertEqual(app.images["show-and-tell.enlarged"].label, "A grown-up beside the girl and the tree.")
        attachScreenshot("Enlarged picture", app: app)
        app.buttons["Done"].tap()

        read.tap()
        XCTAssertTrue(app.staticTexts["show-and-tell.text.1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["show-and-tell.text.6"].exists)
        attachScreenshot("Written story", app: app)
        app.buttons["Done"].tap()
        XCTAssertTrue(read.isHittable)
        XCTAssertFalse(app.staticTexts["show-and-tell.text.1"].exists)
    }

    @MainActor
    func testDrawingsCanFilterSearchPreviewAndRestoreStars() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB", "--demo"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.drawings.tests.\(UUID().uuidString)"
        app.launch()
        app.tabBars.buttons["Drawings"].tap()
        let levels = app.buttons["drawings.level"]
        levels.tap()
        app.buttons["Level 1"].tap()
        let ball = app.buttons["drawing.rubber-ball"]
        let fish = app.buttons["drawing.fish"]
        XCTAssertTrue(ball.waitForExistence(timeout: 5))
        XCTAssertTrue(fish.exists)
        XCTAssertTrue(app.staticTexts["Level 1"].isHittable)
        attachScreenshot("Drawings mosaic", app: app)
        app.buttons["Animals"].tap()
        XCTAssertTrue(fish.exists)
        XCTAssertFalse(ball.exists)
        app.buttons["All drawings"].tap()

        levels.tap()
        app.buttons["Level 5"].tap()
        XCTAssertTrue(app.buttons["drawing.chameleon"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Level 5"].isHittable)
        XCTAssertFalse(ball.exists)
        levels.tap()
        app.buttons["All levels"].tap()

        let search = app.textFields["drawings.search"]
        search.tap()
        search.typeText("toy TRAIN")
        let train = app.buttons["drawing.train"]
        XCTAssertTrue(train.waitForExistence(timeout: 5))
        XCTAssertFalse(ball.exists)
        let star = app.buttons["drawing.star.train"]
        star.tap()
        XCTAssertEqual(star.label, "Unstar drawing: Toy train")
        train.tap()
        XCTAssertTrue(app.images["drawings.preview"].waitForExistence(timeout: 5))
        let previewStar = app.buttons["drawings.preview.star"]
        XCTAssertEqual(previewStar.label, "Unstar drawing: Toy train")
        attachScreenshot("Drawing preview", app: app)
        app.buttons["Done"].tap()
        app.buttons["Clear search"].tap()
        app.buttons["drawings.starred"].tap()
        XCTAssertTrue(train.exists)
        XCTAssertFalse(ball.exists)

        app.terminate()
        app.launch()
        app.tabBars.buttons["Drawings"].tap()
        app.buttons["drawings.starred"].tap()
        XCTAssertTrue(train.waitForExistence(timeout: 5))
        train.tap()
        XCTAssertTrue(app.images["drawings.preview"].waitForExistence(timeout: 5))
        previewStar.tap()
        XCTAssertEqual(previewStar.label, "Star drawing: Toy train")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["No starred drawings yet"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLevelZeroCanFindTraceAndClearGuides() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB", "--demo"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.drawings.tests.\(UUID().uuidString)"
        app.launch()
        app.tabBars.buttons["Drawings"].tap()
        XCTAssertTrue(app.staticTexts["Level 0"].isHittable)
        attachScreenshot("Level 0 gallery", app: app)

        app.buttons["drawings.level"].tap()
        app.buttons["Level 0"].tap()
        let line = app.buttons["drawing.horizontal-line"]
        XCTAssertTrue(line.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["drawing.rubber-ball"].exists)
        line.tap()

        let canvas = app.descendants(matching: .any)["drawings.practice.canvas"]
        let clear = app.buttons["drawings.practice.clear"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        XCTAssertFalse(clear.isEnabled)
        let start = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        let end = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
        XCTAssertTrue(clear.isEnabled)
        attachScreenshot("Level 0 tracing", app: app)
        clear.tap()
        XCTAssertFalse(clear.isEnabled)

        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
        XCTAssertTrue(clear.isEnabled)
        app.buttons["Done"].tap()
        let search = app.textFields["drawings.search"]
        search.tap()
        search.typeText("circle")
        let circle = app.buttons["drawing.circle"]
        XCTAssertTrue(circle.waitForExistence(timeout: 5))
        XCTAssertFalse(line.exists)
        circle.tap()
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        XCTAssertEqual(canvas.label, "Circle")
        XCTAssertFalse(clear.isEnabled)
    }

    @MainActor
    func testPoemsOpenFromSecondTabAndReadAcrossLevels() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB", "--demo"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.poems.tests.\(UUID().uuidString)"
        app.launch()
        let tabs = app.tabBars.buttons
        XCTAssertEqual(tabs.element(boundBy: 1).label, "Poems")
        XCTAssertFalse(tabs["Wander"].exists)
        tabs["Poems"].tap()
        XCTAssertTrue(app.staticTexts["200 poems in English"].waitForExistence(timeout: 5))
        attachScreenshot("Poems library", app: app)

        app.buttons["poems.level.0"].tap()
        app.buttons["poem.rain-rain-go-away"].tap()
        let verse = app.staticTexts["poems.verse"]
        XCTAssertTrue(verse.waitForExistence(timeout: 5))
        XCTAssertTrue(verse.label.hasPrefix("Rain, rain, go away,"))
        let back = app.navigationBars.buttons.element(boundBy: 0)
        back.tap()
        back.tap()

        let levelFive = app.buttons["poems.level.5"]
        if !levelFive.isHittable { app.swipeUp() }
        levelFive.tap()
        app.buttons["poem.the-owl-and-the-pussy-cat"].tap()
        XCTAssertTrue(verse.waitForExistence(timeout: 5))
        XCTAssertTrue(verse.label.contains("pea-green boat"))
        XCTAssertTrue(app.staticTexts["Edward Lear"].exists)
        attachScreenshot("Poem reader", app: app)
        let read = app.buttons["poems.read"]
        XCTAssertEqual(read.label, "Read aloud")
        read.tap()
        XCTAssertEqual(read.label, "Stop reading")
        read.tap()
        XCTAssertEqual(read.label, "Read aloud")
        back.tap()
        back.tap()

        let search = app.textFields["poems.search"]
        if !search.isHittable { app.swipeDown() }
        search.tap()
        search.typeText("the SWING")
        let swing = app.buttons["poem.the-swing"]
        XCTAssertTrue(swing.waitForExistence(timeout: 5))
        swing.tap()
        XCTAssertTrue(verse.waitForExistence(timeout: 5))
        XCTAssertTrue(verse.label.contains("Up in the air so blue?"))
    }

    @MainActor
    func testWanderCanExplorePinRecallAndRestoreAfterRelaunch() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.wander.tests.\(UUID().uuidString)"
        app.launchArguments += ["--demo"]
        app.launch()
        openWander(in: app)
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
        openWander(in: app)
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
    func testAppleGenerationRestoresAndSavesAnIdeaOrPreservesTheMapOnServiceFailure() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.apple.tests.\(UUID().uuidString)"
        app.launchArguments += ["--demo", "--apple-ai"]
        app.launch()
        openWander(in: app)
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
        openWander(in: app)
        XCTAssertTrue(source.waitForExistence(timeout: 10))
        XCTAssertEqual(app.buttons["wander.pin"].label, "Unpin this idea")
        attachScreenshot("Apple generated idea restored", app: app)

        let save = app.buttons["wander.activity.save"]
        XCTAssertTrue(save.isHittable)
        save.tap()
        let open = app.buttons["wander.activity.open"]
        wait(for: [expectation(for: NSPredicate { _, _ in open.exists || failure.exists }, evaluatedWith: nil)],
             timeout: 180)
        XCTAssertTrue(open.exists, failure.exists ? failure.label : "Expected a saved activity")
        open.tap()
        let activityTitle = app.staticTexts["activity.detail.title"]
        XCTAssertTrue(activityTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["30 min"].exists)
        let savedTitle = activityTitle.label
        app.terminate()
        app.launch()
        app.tabBars.buttons["Discover"].tap()
        app.buttons["Saved from Wander"].tap()
        XCTAssertTrue(app.staticTexts[savedTitle].waitForExistence(timeout: 5))
    }

    @MainActor
    func testPrintForTodayUsesCurrentActivityAndSelectedPages() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_GB", "--demo"]
        app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.print.tests.\(UUID().uuidString)"
        app.launch()

        let title = app.staticTexts["today.activity.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let firstTitle = title.label
        let anotherIdea = app.buttons["today.another-idea"]
        if !anotherIdea.isHittable { app.swipeUp() }
        anotherIdea.tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let currentTitle = title.label
        XCTAssertNotEqual(firstTitle, currentTitle)

        app.tabBars.buttons["More"].tap()
        app.buttons["more.print-today"].tap()
        let activity = app.switches["print.today.activity"]
        let drawing = app.switches["print.today.drawing"]
        let poem = app.switches["print.today.poem"]
        let printButton = app.buttons["print.today.open-options"]
        XCTAssertTrue(activity.waitForExistence(timeout: 5))
        XCTAssertTrue(activity.label.contains(currentTitle))
        printButton.tap()
        XCTAssertTrue(app.cells["Page 1 of 3"].waitForExistence(timeout: 5))
        attachScreenshot("All three print pages", app: app)
        app.buttons["Cancel"].tap()

        for page in [activity, drawing, poem] {
            XCTAssertEqual(page.value as? String, "1")
            page.switches.firstMatch.tap()
            XCTAssertEqual(page.value as? String, "0")
        }
        XCTAssertFalse(printButton.isEnabled)
        drawing.switches.firstMatch.tap()
        XCTAssertTrue(printButton.isEnabled)
        attachScreenshot("Print for today", app: app)
        printButton.tap()
        XCTAssertTrue(app.cells["Page 1 of 1"].waitForExistence(timeout: 5))
        attachScreenshot("Drawing print preview", app: app)
    }

    @MainActor
    func testEverySupportedLanguageLocalizesOnboardingTodayAndMemories() throws {
        let languages: [(code: String, welcome: String, today: String, memories: String)] = [
            ("en", "Welcome to Teachably", "Today", "Memories"),
            ("zh-Hans", "欢迎使用 Teachably", "今天", "回忆"),
            ("zh-Hant", "歡迎使用 Teachably", "今天", "回憶"),
            ("ja", "Teachablyへようこそ", "今日", "思い出"),
            ("es", "Te damos la bienvenida a Teachably", "Hoy", "Recuerdos"),
            ("id", "Selamat datang di Teachably", "Hari ini", "Kenangan")
        ]
        var englishActivityTitle = ""
        for language in languages {
            let app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(\(language.code))", "-AppleLocale", language.code]
            app.launchEnvironment["TEACHABLY_TEST_SUITE"] = "dev.teachably.localization.\(UUID().uuidString)"
            app.launch()
            let welcome = app.staticTexts["welcome.heading"]
            XCTAssertTrue(welcome.waitForExistence(timeout: 10), language.code)
            XCTAssertEqual(welcome.label, language.welcome, language.code)
            app.buttons["welcome.start"].tap()
            let heading = app.staticTexts["today.heading"]
            XCTAssertTrue(heading.waitForExistence(timeout: 10), language.code)
            XCTAssertEqual(heading.label, language.today, language.code)
            XCTAssertEqual(app.tabBars.buttons.element(boundBy: 0).label, language.today, language.code)
            let title = app.staticTexts["today.activity.title"]
            XCTAssertTrue(title.waitForExistence(timeout: 5), language.code)
            if language.code == "en" { englishActivityTitle = title.label }
            else {
                XCTAssertNotEqual(title.label, englishActivityTitle, language.code)
            }
            attachScreenshot("Today · \(language.code)", app: app)
            openMemories(in: app)
            XCTAssertTrue(app.navigationBars[language.memories].waitForExistence(timeout: 5), language.code)
            app.terminate()
        }
    }

    @MainActor
    private func openMemories(in app: XCUIApplication) {
        app.tabBars.buttons.element(boundBy: 4).tap()
        app.buttons["more.memories"].tap()
    }

    @MainActor
    private func openWander(in app: XCUIApplication) {
        app.tabBars.buttons["More"].tap()
        app.buttons["more.wander"].tap()
    }

    @MainActor
    private func attachScreenshot(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
