import SwiftUI
import TeachablyCore

enum WanderGenerationMode: String {
    case appleAI, library
}

@MainActor
final class WanderStore: ObservableObject {
    @Published private(set) var engine: WanderEngine
    @Published var errorMessage: String?
    @Published private(set) var highlightID: String?
    @Published private(set) var highlightLabel: String?
    @Published private(set) var removedPinID: String?
    @Published private(set) var modelStatus = FoundationModelWanderProvider.status
    @Published private(set) var mode: WanderGenerationMode = .library
    @Published private(set) var isGenerating = false
    private let defaults: UserDefaults
    private let key = "teachably.wander.v1"
    private var unreadableStorage = false
    private var interests = Skill.familyInterests
    private var generationTask: Task<Void, Never>?
    private var generationID: UUID?
    private var needsLanguageRoot = false

    init() {
        var storage = UserDefaults.standard
        #if DEBUG
        if let suite = ProcessInfo.processInfo.environment["TEACHABLY_TEST_SUITE"], let test = UserDefaults(suiteName: suite) {
            storage = test
        }
        #endif
        defaults = storage
        needsLanguageRoot = (storage.string(forKey: "teachably.wander.language") ?? "en") != L10n.language.rawValue
        var state = WanderState()
        var problem: String?
        if let data = storage.data(forKey: key) {
            do { state = try WanderState.decode(data) }
            catch {
                unreadableStorage = true
                problem = L10n.string("Your saved Wander trails couldn't be opened. They have been kept on this device. Please close the app and try again.")
            }
        }
        let activities: [Activity]
        do { activities = try ActivityCatalog.load() }
        catch { activities = []; problem = L10n.string("The activity library couldn't be opened. Please reopen the app.") }
        engine = WanderEngine(catalog: WanderCatalog(activities: activities, interests: Skill.familyInterests), state: state)
        errorMessage = problem
        mode = storage.string(forKey: "teachably.wander.generation-mode").flatMap(WanderGenerationMode.init(rawValue:))
            ?? (modelStatus.isAvailable ? .appleAI : .library)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--demo") { mode = .library }
        if ProcessInfo.processInfo.arguments.contains("--apple-ai") { mode = .appleAI }
        #endif
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
        refreshModelStatus()
        let refreshStartingMap = self.interests != interests && current?.depth == 0
        if self.interests != interests {
            self.interests = interests
            engine = WanderEngine(catalog: WanderCatalog(activities: engine.catalog.activities, interests: interests), state: engine.state)
        }
        if (current == nil || refreshStartingMap || needsLanguageRoot) && errorMessage == nil {
            explore(.root)
            if errorMessage == nil {
                needsLanguageRoot = false
                defaults.set(L10n.language.rawValue, forKey: "teachably.wander.language")
            }
        }
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
        guard !isGenerating else { return }
        let request = WanderRequest(action: action, parentID: action == .root || action == .refresh ? nil : current?.id,
            bubbleID: bubbleID, query: query, refreshLayerID: action == .refresh ? current?.id : nil)
        // The starting map contains the parent's own selected interests. The
        // model generates new content after a topic or question is chosen.
        let isLibraryRefresh = action == .refresh && current?.provenance == nil
        if action != .root && !isLibraryRefresh && mode == .appleAI {
            generate(request)
            return
        }
        if current?.provenance != nil && action != .root {
            errorMessage = L10n.string("Choose Apple AI to continue this generated trail, or return to the starting map to explore the activity library.")
            return
        }
        if change({ _ = try $0.explore(request) }) { highlightID = nil; highlightLabel = nil }
    }

    func refreshModelStatus() { modelStatus = FoundationModelWanderProvider.status }
    func setMode(_ mode: WanderGenerationMode) {
        cancelGeneration()
        self.mode = mode
        defaults.set(mode.rawValue, forKey: "teachably.wander.generation-mode")
        errorMessage = nil
        explore(.root)
    }
    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        generationID = nil
        isGenerating = false
    }
    private func generate(_ request: WanderRequest) {
        do {
            let plan = try engine.prepareGeneration(request, providerID: FoundationModelWanderProvider.identifier)
            var reused = false
            guard change({ reused = try $0.reuseGeneration(plan) != nil }) else { return }
            if reused { highlightID = nil; highlightLabel = nil; return }
            refreshModelStatus()
            guard modelStatus.isAvailable else { errorMessage = modelStatus.message; return }
            guard #available(iOS 26.0, *) else { errorMessage = modelStatus.message; return }
            let id = UUID()
            generationID = id
            isGenerating = true
            generationTask = Task { [weak self] in
                guard let self else { return }
                do {
                    let draft = try await FoundationModelWanderProvider.generate(plan)
                    try Task.checkCancellation()
                    guard generationID == id else { return }
                    if change({ _ = try $0.acceptGenerated(draft, for: plan) }) {
                        highlightID = nil; highlightLabel = nil
                    }
                } catch is CancellationError {
                    // Cancellation leaves the displayed map and saved data intact.
                } catch {
                    if generationID == id {
                        errorMessage = FoundationModelWanderProvider.failureMessage(error)
                    }
                }
                if generationID == id {
                    isGenerating = false
                    generationID = nil
                    generationTask = nil
                }
            }
        } catch { errorMessage = error.localizedDescription }
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
        } catch { errorMessage = L10n.string("Your saved idea couldn't be prepared for sharing. Please try again."); return nil }
    }
}
