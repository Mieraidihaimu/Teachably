import XCTest
@testable import TeachablyCore

final class WanderGenerationTests: XCTestCase {
    private func engine() throws -> WanderEngine {
        WanderEngine(catalog: WanderCatalog(activities: try ActivityCatalog.load(), interests: Skill.familyInterests))
    }
    private var mapDraft: WanderGeneratedDraft {
        WanderGeneratedDraft(title: "Light and colour", summary: "Notice the colours around us.", topics: [
            WanderGeneratedTopic(label: "Splitting white light", summary: "White light contains many colours."),
            WanderGeneratedTopic(label: "Rain in sunlight", summary: "Water droplets bend and reflect light."),
            WanderGeneratedTopic(label: "Colours we see", summary: "Objects reflect some colours more than others.")
        ])
    }
    private var lessonDraft: WanderGeneratedDraft {
        WanderGeneratedDraft(title: "Why rainbows form", summary: "Sunlight changes direction through water droplets.",
            lesson: WanderGeneratedLesson(definition: "Sunlight bends and reflects inside water droplets. Different colours bend by different amounts.",
                example: "Draw a large arc together and name its colours. Talk about when you have seen a rainbow.",
                toddlerAction: "Point to a colour you like.", toddlerQuestion: "Which colour?",
                olderAction: "Predict when a rainbow might appear.", olderQuestion: "Where would the sun be?",
                consideration: "Never look directly at the sun.", personalPrompt: "Share a time you saw a rainbow."))
    }

    func testNewConceptsGenerateIndependentLessonsWithProvenanceAndRecall() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let plan = try engine.prepareGeneration(WanderRequest(action: .refine, parentID: root.id, query: "Why do rainbows form?"), providerID: "apple-test-v1")
        XCTAssertTrue(plan.requiresLesson)
        XCTAssertTrue(plan.contextJSON.contains(#""band":"toddler""#))
        XCTAssertTrue(plan.contextJSON.contains(#""band":"earlyYears""#))
        XCTAssertNil(try engine.reuseGeneration(plan))
        let layer = try engine.acceptGenerated(lessonDraft, for: plan)
        XCTAssertNil(layer.lesson?.activityID)
        XCTAssertEqual(layer.provenance?.providerID, "apple-test-v1")
        XCTAssertEqual(layer.provenance?.promptVersion, WanderEngine.generationPromptVersion)
        XCTAssertEqual(layer.parentID, root.id)
        XCTAssertEqual(layer.displayTitle, "Why rainbows form")
        XCTAssertEqual(try engine.search("Why rainbows form").first?.layerID, layer.id)
        XCTAssertTrue(try XCTUnwrap(engine.search("Why rainbows form").first).isExact)
        XCTAssertEqual(try WanderState.decode(engine.state.encoded()), engine.state)
        XCTAssertTrue(try engine.pinCurrent().markdown.contains("generated on device with Apple Intelligence"))
    }

    func testNewFamilyStageChangesAppleGenerationContextAndCacheKey() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let request = WanderRequest(action: .refine, parentID: root.id, query: "Patterns")
        let previous = try engine.prepareGeneration(request, providerID: "test")
        _ = try engine.acceptGenerated(mapDraft, for: previous)
        let date = try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-11-01T12:00:00Z"))
        var profile = FamilyProfile()
        profile.youngerName = "Private nickname"
        profile.olderBirthMonth = BirthMonth(year: 2019, month: 11)
        let next = try engine.prepareGeneration(
            WanderRequest(action: .refine, parentID: root.id, query: "Patterns"),
            providerID: "test", stages: profile.stages(on: date))
        XCTAssertTrue(next.contextJSON.contains(#""age":7,"band":"primary""#))
        XCTAssertFalse(next.contextJSON.contains("2019"))
        XCTAssertFalse(next.contextJSON.contains("Private nickname"))
        XCTAssertNotEqual(previous.cacheKey, next.cacheKey)
        XCTAssertNil(try engine.reuseGeneration(next))
    }

    func testPinnedActivityRequiresFourStepsAndPersistsInFamilyLibrary() throws {
        var engine = try engine()
        _ = try engine.explore(WanderRequest(action: .root))
        let pin = try engine.pinCurrent()
        func makeActivity(stepCount: Int) throws -> Activity {
            let prompt = AgePrompt(action: "Point to a pattern.", question: "What comes next?")
            let primary = AgePrompt(action: "Explain the rule.", question: "Would a different rule work?")
            return try pin.makeLibraryActivity(title: "Our pattern", subtitle: "Play with patterns together.",
                skill: " numbers ", takeaway: "Patterns repeat.", parentPrimer: "Pick a simple repeated action.",
                materials: ["A picture book", "A picture book"], toddler: prompt, earlyYears: prompt,
                primary: primary, siblingRole: "Clap once and invite your brother to copy.",
                steps: Array(repeating: (title: "Try a pattern", instruction: "Clap together."), count: stepCount),
                personalPrompt: "Share a pattern you know.", careNote: "Keep the sound gentle.")
        }
        XCTAssertThrowsError(try makeActivity(stepCount: 3))
        let activity = try makeActivity(stepCount: 4)
        XCTAssertEqual(activity.id, pin.libraryActivityID)
        XCTAssertEqual(activity.duration, 30)
        XCTAssertEqual(activity.materials, ["A picture book"])
        XCTAssertEqual(activity.prompt(for: .primary).action, "Explain the rule.")
        var state = FamilyState()
        state.customActivities = [activity]
        XCTAssertEqual(try FamilyState.decode(state.encoded()).customActivities, [activity])
    }

    func testExactReuseAndRequestReplayAreIsolatedFromLibraryAndOtherProviders() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let coding = try XCTUnwrap(root.bubbles.first { $0.skill == .coding })
        let request = WanderRequest(action: .expand, parentID: root.id, bubbleID: coding.id)
        let library = try engine.explore(request)
        try engine.open(root.id)
        var aiRequest = request; aiRequest.requestID = UUID().uuidString
        let plan = try engine.prepareGeneration(aiRequest, providerID: "apple-v1")
        XCTAssertNil(try engine.reuseGeneration(plan))
        let generated = try engine.acceptGenerated(mapDraft, for: plan)
        XCTAssertNotEqual(generated.id, library.id)
        XCTAssertEqual(try engine.reuseGeneration(plan), generated)
        // A completed request replays the original result rather than accepting a new response.
        XCTAssertEqual(try engine.acceptGenerated(WanderGeneratedDraft(title: "", summary: ""), for: plan), generated)
        aiRequest.requestID = UUID().uuidString
        let repeatPlan = try engine.prepareGeneration(aiRequest, providerID: "apple-v1")
        XCTAssertEqual(try engine.reuseGeneration(repeatPlan), generated)
        let otherProvider = try engine.prepareGeneration(aiRequest, providerID: "apple-v2")
        XCTAssertThrowsError(try engine.reuseGeneration(otherProvider)) { XCTAssertEqual($0 as? WanderError, .requestConflict) }
        aiRequest.requestID = UUID().uuidString
        XCTAssertNil(try engine.reuseGeneration(engine.prepareGeneration(aiRequest, providerID: "apple-v2")))
    }

    func testMalformedGeneratedContentNeverChangesHistoryOrPins() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        _ = try engine.pinCurrent()
        let plan = try engine.prepareGeneration(WanderRequest(action: .refine, parentID: root.id, query: "Rainbows"), providerID: "apple-v1")
        let before = engine.state
        let badDrafts = [
            WanderGeneratedDraft(title: "", summary: "Missing title", topics: mapDraft.topics),
            WanderGeneratedDraft(title: "Repeated", summary: "Repeated ideas", topics: [
                WanderGeneratedTopic(label: "Rainbows", summary: "Parent repeated."),
                WanderGeneratedTopic(label: "Other", summary: "A different idea.")]),
            WanderGeneratedDraft(title: "Duplicates", summary: "Repeated labels", topics: [
                WanderGeneratedTopic(label: "Colour", summary: "First."),
                WanderGeneratedTopic(label: " colour ", summary: "Second.")]),
            lessonDraft
        ]
        for draft in badDrafts {
            XCTAssertThrowsError(try engine.acceptGenerated(draft, for: plan)) { XCTAssertEqual($0 as? WanderGenerationError, .invalidOutput) }
            XCTAssertEqual(engine.state, before)
        }
        let lessonPlan = try engine.prepareGeneration(WanderRequest(action: .explain, parentID: root.id), providerID: "apple-v1")
        XCTAssertThrowsError(try engine.acceptGenerated(mapDraft, for: lessonPlan))
        XCTAssertEqual(engine.state, before)
    }

    func testLateResponsesAreRejectedAfterNavigationOrInterestChanges() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let plan = try engine.prepareGeneration(WanderRequest(action: .refine, parentID: root.id, query: "Rainbows"), providerID: "apple-v1")
        let changed = try engine.explore(WanderRequest(action: .expand, parentID: root.id, bubbleID: root.bubbles[0].id))
        let before = engine.state
        XCTAssertThrowsError(try engine.acceptGenerated(mapDraft, for: plan)) { XCTAssertEqual($0 as? WanderGenerationError, .staleRequest) }
        XCTAssertEqual(engine.current?.id, changed.id)
        XCTAssertEqual(engine.state, before)
        try engine.open(root.id)
        var differentInterests = WanderEngine(catalog: WanderCatalog(activities: engine.catalog.activities, interests: [.music]), state: engine.state)
        XCTAssertThrowsError(try differentInterests.acceptGenerated(mapDraft, for: plan)) { XCTAssertEqual($0 as? WanderGenerationError, .staleRequest) }
    }

    func testRefreshCreatesANewRevisionWithoutChangingPinnedGeneratedContent() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let plan = try engine.prepareGeneration(WanderRequest(action: .refine, parentID: root.id, query: "Rainbows"), providerID: "apple-v1")
        let original = try engine.acceptGenerated(mapDraft, for: plan)
        let pin = try engine.pinCurrent()
        try engine.setNote("Ask the boys after the rain.", pinID: pin.id)
        let refresh = try engine.prepareGeneration(WanderRequest(action: .refresh, refreshLayerID: original.id), providerID: "apple-v1")
        XCTAssertNil(try engine.reuseGeneration(refresh))
        let revision = try engine.acceptGenerated(mapDraft, for: refresh)
        XCTAssertEqual(revision.revisionOf, original.id)
        XCTAssertNotEqual(revision.id, original.id)
        XCTAssertEqual(engine.activePins.first?.snapshot.layer, original)
        XCTAssertEqual(engine.activePins.first?.note, "Ask the boys after the rain.")
        var reopened = WanderEngine(catalog: engine.catalog, state: try WanderState.decode(engine.state.encoded()))
        try reopened.openPin(pin.id)
        XCTAssertEqual(reopened.current, original)
    }

    func testExistingLibraryStorageLoadsWithoutNewProvenanceField() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let lesson = try engine.explore(WanderRequest(action: .refine, parentID: root.id, query: "Explain coding"))
        XCTAssertNotNil(lesson.lesson?.activityID)
        let data = try engine.state.encoded()
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("provenance"))
        let restored = try WanderState.decode(data)
        XCTAssertEqual(restored, engine.state)
        XCTAssertNil(restored.layers.last?.provenance)
    }
}
