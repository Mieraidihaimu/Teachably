import SwiftUI
import TeachablyCore

@MainActor
final class WanderStore: ObservableObject {
    @Published private(set) var engine: WanderEngine
    @Published var errorMessage: String?
    @Published private(set) var highlightID: String?
    @Published private(set) var highlightLabel: String?
    @Published private(set) var removedPinID: String?
    private let defaults: UserDefaults
    private let key = "teachably.wander.v1"
    private var unreadableStorage = false
    private var interests = Skill.familyInterests

    init() {
        var storage = UserDefaults.standard
        #if DEBUG
        if let suite = ProcessInfo.processInfo.environment["TEACHABLY_TEST_SUITE"], let test = UserDefaults(suiteName: suite) {
            storage = test
        }
        #endif
        defaults = storage
        var state = WanderState()
        var problem: String?
        if let data = storage.data(forKey: key) {
            do { state = try WanderState.decode(data) }
            catch {
                unreadableStorage = true
                problem = "Your saved Wander trails couldn't be opened. They have been kept on this device. Please close the app and try again."
            }
        }
        let activities: [Activity]
        do { activities = try ActivityCatalog.load() }
        catch { activities = []; problem = "The activity library couldn't be opened. Please reopen the app." }
        engine = WanderEngine(catalog: WanderCatalog(activities: activities, interests: Skill.familyInterests), state: state)
        errorMessage = problem
    }

    var current: WanderLayer? { engine.current }
    var pins: [WanderPin] { engine.activePins }
    var currentPin: WanderPin? { pins.first { $0.snapshot.layer.id == current?.id } }
    var layout: WanderLayout { engine.state.layout }
    var viewport: WanderViewport { engine.viewport }
    var trail: [WanderLayer] {
        (current?.ancestorIDs ?? []).compactMap { id in engine.state.layers.first { $0.id == id } }
    }

    func start(interests: Set<Skill>) {
        let refreshStartingMap = self.interests != interests && current?.depth == 0
        if self.interests != interests {
            self.interests = interests
            engine = WanderEngine(catalog: WanderCatalog(activities: engine.catalog.activities, interests: interests), state: engine.state)
        }
        if (current == nil || refreshStartingMap) && errorMessage == nil { explore(.root) }
    }

    @discardableResult
    private func change(_ action: (inout WanderEngine) throws -> Void) -> Bool {
        guard !unreadableStorage else { return false }
        do {
            var next = engine
            try action(&next)
            let data = try next.state.encoded()
            defaults.set(data, forKey: key)
            engine = next
            errorMessage = nil
            return true
        } catch { errorMessage = error.localizedDescription; return false }
    }

    func explore(_ action: WanderAction, bubbleID: String? = nil, query: String = "") {
        let request = WanderRequest(action: action, parentID: action == .root || action == .refresh ? nil : current?.id,
            bubbleID: bubbleID, query: query, refreshLayerID: action == .refresh ? current?.id : nil)
        if change({ _ = try $0.explore(request) }) { highlightID = nil; highlightLabel = nil }
    }
    func open(_ id: String) {
        if change({ try $0.open(id) }) { highlightID = nil; highlightLabel = nil }
    }
    func open(_ hit: WanderSearchHit) {
        if change({ try $0.open(hit.layerID) }) { highlightID = hit.bubbleID; highlightLabel = hit.label }
    }
    func clearHighlight() { highlightID = nil; highlightLabel = nil }
    func setLayout(_ layout: WanderLayout) { _ = change { $0.setLayout(layout) } }
    func setViewport(_ viewport: WanderViewport) { _ = change { $0.setViewport(viewport) } }
    func pin() { _ = change { _ = try $0.pinCurrent() } }
    func removePin(_ id: String) {
        if change({ try $0.archivePin(id, archived: true) }) { removedPinID = id }
    }
    func undoUnpin() {
        guard let id = removedPinID else { return }
        if change({ try $0.archivePin(id, archived: false) }) { removedPinID = nil }
    }
    func openPin(_ id: String) {
        if change({ try $0.openPin(id) }) { highlightID = nil; highlightLabel = nil }
    }
    @discardableResult
    func saveNote(_ note: String, pinID: String) -> Bool { change { try $0.setNote(note, pinID: pinID) } }

    func export(_ pin: WanderPin, json: Bool) -> URL? {
        do {
            let data: Data
            if json {
                let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                data = try encoder.encode(pin)
            } else { data = Data(pin.markdown.utf8) }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("Teachably-Wander-\(pin.id).\(json ? "json" : "md")")
            try data.write(to: url, options: .atomic)
            return url
        } catch { errorMessage = "Your saved idea couldn't be prepared for sharing. Please try again."; return nil }
    }
}
