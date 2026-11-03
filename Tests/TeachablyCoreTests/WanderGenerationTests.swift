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
        XCTAssertTrue(plan.contextJSON.contains("[2,6]"))
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
