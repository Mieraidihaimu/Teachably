import XCTest
@testable import TeachablyCore

final class WanderTests: XCTestCase {
    private func engine() throws -> WanderEngine {
        WanderEngine(catalog: WanderCatalog(activities: try ActivityCatalog.load(), interests: Skill.familyInterests))
    }
    private func expand(_ label: String, from layer: WanderLayer, engine: inout WanderEngine) throws -> WanderLayer {
        let bubble = try XCTUnwrap(layer.bubbles.first { $0.label == label })
        return try engine.explore(WanderRequest(action: .expand, parentID: layer.id, bubbleID: bubble.id))
    }

    func testRootUsesTheParentsInterestsAndRepeatedRequestsReuseSavedLayers() throws {
        var engine = try engine()
        let request = WanderRequest(action: .root)
        let root = try engine.explore(request)
        XCTAssertEqual(Set(root.bubbles.compactMap(\.skill)), Skill.familyInterests)
        XCTAssertEqual(try engine.explore(request), root)
        XCTAssertEqual(try engine.explore(WanderRequest(action: .root)), root)
        XCTAssertEqual(engine.state.layers.count, 1)
        var changed = request; changed.query = "coding"
        XCTAssertThrowsError(try engine.explore(changed)) { XCTAssertEqual($0 as? WanderError, .requestConflict) }
    }

    func testDrillingDownKeepsAncestryAndArrivesAtAnAgeAdaptedLesson() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let coding = try expand("Coding & logic", from: root, engine: &engine)
        let robot = try expand("Be my friendly robot", from: coding, engine: &engine)
        let lesson = try expand("An example to try", from: robot, engine: &engine)
        XCTAssertEqual(lesson.depth, 3)
        XCTAssertEqual(lesson.ancestorIDs, [root.id, coding.id, robot.id])
        XCTAssertEqual(lesson.branchID, coding.id)
        XCTAssertEqual(lesson.lesson?.activityID, "friendly-robot")
        XCTAssertFalse(try XCTUnwrap(lesson.lesson).toddler.action.isEmpty)
        XCTAssertFalse(try XCTUnwrap(lesson.lesson).older.action.isEmpty)
        try engine.open(root.id)
        XCTAssertEqual(engine.current?.id, root.id)
        XCTAssertTrue(engine.visitedBubbleIDs.contains(try XCTUnwrap(coding.selectedBubbleID)))
    }

    func testExplicitQuestionsTeachImmediatelyAndUnknownTopicsKeepTheCurrentLayer() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let lesson = try engine.explore(WanderRequest(action: .refine, parentID: root.id, query: "Please explain shadows"))
        XCTAssertNotNil(lesson.lesson)
        XCTAssertEqual(lesson.depth, 1)
        let before = engine.state
        XCTAssertThrowsError(try engine.explore(WanderRequest(action: .refine, parentID: lesson.id, query: "quantum chromodynamics")))
        XCTAssertEqual(engine.state, before)
        for question in ["Explain loops", "Could you please show me a practical example?", "What is a shadow?", "Help me understand coding"] {
            XCTAssertTrue(WanderEngine.requestsExplanation(question), question)
        }
        XCTAssertFalse(WanderEngine.requestsExplanation("Explore coding"))
        XCTAssertFalse(WanderEngine.requestsExplanation("Explainability research"))
    }

    func testForeignBubbleReferencesAreRejectedWithoutChangingHistory() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let coding = try expand("Coding & logic", from: root, engine: &engine)
        let before = engine.state
        XCTAssertThrowsError(try engine.explore(WanderRequest(action: .expand, parentID: root.id, bubbleID: coding.bubbles[0].id))) {
            XCTAssertEqual($0 as? WanderError, .invalidBubble)
        }
        XCTAssertEqual(engine.state, before)
    }

    func testUnselectedBubblesAreRecalledWithExactMatchesFirstAndScopesApplied() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let coding = try expand("Coding & logic", from: root, engine: &engine)
        let physics = try expand("Everyday physics", from: root, engine: &engine)
        let hits = try engine.search("A loop of silly moves")
        XCTAssertEqual(hits.first?.layerID, coding.id)
        XCTAssertTrue(try XCTUnwrap(hits.first).isExact)
        XCTAssertFalse(engine.visitedBubbleIDs.contains(try XCTUnwrap(hits.first?.bubbleID)))
        XCTAssertTrue(try engine.search("loop", scope: .branch(physics.id)).isEmpty)
        XCTAssertFalse(try engine.search("loop", scope: .branch(coding.id), minDepth: 1, maxDepth: 1).isEmpty)
        XCTAssertTrue(try engine.search("loop", scope: .layer(root.id)).isEmpty)
        XCTAssertThrowsError(try engine.search("loop", minDepth: 4, maxDepth: 2))
    }

    func testPinsKeepTheirOriginalSnapshotAcrossRefreshNotesAndUndo() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        var viewport = WanderViewport(); viewport.scale = 1.2; viewport.x = 20
        engine.setViewport(viewport)
        let original = try engine.pinCurrent()
        try engine.setNote("Share this idea on Saturday.", pinID: original.id)
        let updated = try XCTUnwrap(engine.activePins.first)
        XCTAssertEqual(updated.snapshot, original.snapshot)
        let revision = try engine.explore(WanderRequest(action: .refresh, refreshLayerID: root.id))
        XCTAssertEqual(revision.revisionOf, root.id)
        XCTAssertNotEqual(revision.id, root.id)
        XCTAssertEqual(engine.activePins.first?.snapshot.layer, root)
        try engine.archivePin(original.id, archived: true)
        XCTAssertTrue(engine.activePins.isEmpty)
        try engine.open(root.id)
        let restored = try engine.pinCurrent()
        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.note, "Share this idea on Saturday.")
        XCTAssertEqual(restored.snapshot.viewport, viewport)
        try engine.openPin(restored.id)
        XCTAssertEqual(engine.viewport, viewport)
        XCTAssertThrowsError(try engine.setNote(String(repeating: "x", count: 601), pinID: restored.id))
    }

    func testPersistenceRestoresTrailViewportPinsAndRecallWithoutGeneration() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        let coding = try expand("Coding & logic", from: root, engine: &engine)
        engine.setLayout(.list)
        let pin = try engine.pinCurrent()
        try engine.setNote("Our robot game", pinID: pin.id)
        let data = try engine.state.encoded()
        let state = try WanderState.decode(data)
        var reopened = WanderEngine(catalog: engine.catalog, state: state)
        XCTAssertEqual(reopened.state, engine.state)
        XCTAssertEqual(reopened.current?.id, coding.id)
        XCTAssertEqual(reopened.state.layout, .list)
        XCTAssertEqual(reopened.activePins.first?.note, "Our robot game")
        XCTAssertEqual(try reopened.explore(WanderRequest(action: .root)).id, root.id)
        XCTAssertEqual(reopened.state.layers.count, 2)
        XCTAssertFalse(try reopened.search("loop").isEmpty)
    }

    func testMarkdownExportsReadableNotesAndEscapesUntrustedMarkup() throws {
        var engine = try engine()
        let root = try engine.explore(WanderRequest(action: .root))
        _ = try engine.explore(WanderRequest(action: .refine, parentID: root.id, query: "Explain coding"))
        let pin = try engine.pinCurrent()
        try engine.setNote("Remember [this] <script>.", pinID: pin.id)
        let export = try XCTUnwrap(engine.activePins.first).markdown
        XCTAssertTrue(export.contains("## At age 2"))
        XCTAssertTrue(export.contains("## At age 6"))
        XCTAssertTrue(export.contains(#"\[this\]"#))
        XCTAssertTrue(export.contains(#"\<script\>"#))
        XCTAssertFalse(export.contains("requestID"))
        XCTAssertFalse(export.contains("cacheKey"))
    }

    func testChangedInterestsMakeANewRootButLeaveOldTrailsAvailable() throws {
        var original = try engine()
        let root = try original.explore(WanderRequest(action: .root))
        let coding = try expand("Coding & logic", from: root, engine: &original)
        let musicCatalog = WanderCatalog(activities: original.catalog.activities, interests: [.music])
        var updated = WanderEngine(catalog: musicCatalog, state: original.state)
        let music = try updated.explore(WanderRequest(action: .root))
        XCTAssertNotEqual(music.id, root.id)
        XCTAssertEqual(music.bubbles.compactMap(\.skill), [.music])
        let robot = try expand("Be my friendly robot", from: coding, engine: &updated)
        XCTAssertEqual(robot.parentID, coding.id)
    }
}
