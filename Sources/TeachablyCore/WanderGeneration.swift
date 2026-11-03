import Foundation

public struct WanderProvenance: Codable, Equatable, Sendable {
    public let providerID: String
    public let promptVersion: String
    public let context: String
}

public struct WanderGeneratedTopic: Sendable {
    public let label: String
    public let summary: String
    public init(label: String, summary: String) { self.label = label; self.summary = summary }
}

public struct WanderGeneratedLesson: Sendable {
    public let definition: String
    public let example: String
    public let toddlerAction: String
    public let toddlerQuestion: String
    public let olderAction: String
    public let olderQuestion: String
    public let consideration: String
    public let personalPrompt: String
    public init(definition: String, example: String, toddlerAction: String, toddlerQuestion: String,
                olderAction: String, olderQuestion: String, consideration: String, personalPrompt: String) {
        self.definition = definition; self.example = example
        self.toddlerAction = toddlerAction; self.toddlerQuestion = toddlerQuestion
        self.olderAction = olderAction; self.olderQuestion = olderQuestion
        self.consideration = consideration; self.personalPrompt = personalPrompt
    }
}

public struct WanderGeneratedDraft: Sendable {
    public let title: String
    public let summary: String
    public let topics: [WanderGeneratedTopic]
    public let lesson: WanderGeneratedLesson?
    public init(title: String, summary: String, topics: [WanderGeneratedTopic] = [], lesson: WanderGeneratedLesson? = nil) {
        self.title = title; self.summary = summary; self.topics = topics; self.lesson = lesson
    }
}

public struct WanderGenerationPlan: Sendable {
    public let concept: String
    public let requiresLesson: Bool
    public let contextJSON: String
    public let providerID: String
    let incoming: WanderRequest
    let request: WanderRequest
    let parent: WanderLayer?
    let selected: WanderBubble?
    let revisionID: String?
    let cacheKey: String
    let signature: String
    let startingLayerID: String?
    let catalogID: String
}

public enum WanderGenerationError: LocalizedError, Equatable {
    case invalidOutput, staleRequest
    public var errorDescription: String? {
        switch self {
        case .invalidOutput: L10n.string("Apple Intelligence returned an incomplete idea. Your current map is safe; please try again.")
        case .staleRequest: L10n.string("Your exploration changed while this idea was being prepared. Please try from the current map.")
        }
    }
}

extension WanderEngine {
    public static let generationPromptVersion = "teachably-apple-fm-v2"

    public func prepareGeneration(_ incoming: WanderRequest, providerID: String) throws -> WanderGenerationPlan {
        guard incoming.query.count <= 240, !incoming.requestID.isEmpty, !providerID.isEmpty else { throw WanderError.invalidRequest }
        let revision: WanderLayer?
        let request: WanderRequest
        if incoming.action == .refresh {
            guard let old = state.layers.first(where: { $0.id == incoming.refreshLayerID }) else { throw WanderError.missingLayer }
            revision = old; request = old.request
        } else { revision = nil; request = incoming }
        let parent: WanderLayer?
        if let id = request.parentID {
            guard let saved = state.layers.first(where: { $0.id == id }) else { throw WanderError.missingLayer }
            parent = saved
        } else { parent = nil }
        if request.action == .root {
            guard parent == nil, request.bubbleID == nil else { throw WanderError.invalidRequest }
        } else if parent == nil { throw WanderError.missingLayer }
        if let parent, parent.depth >= 12 { throw WanderError.depthLimit }
        let selected: WanderBubble?
        if let id = request.bubbleID {
            guard let bubble = parent?.bubbles.first(where: { $0.id == id }) else { throw WanderError.invalidBubble }
            selected = bubble
        } else { selected = nil }
        if request.action == .expand && selected == nil { throw WanderError.invalidBubble }
        if request.action == .refine && request.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { throw WanderError.invalidRequest }
        let depth = (parent?.depth ?? -1) + 1
        let requiresLesson = request.action == .explain || request.action == .example || Self.requestsExplanation(request.query) || depth >= 6
        let concept = selected?.label ?? (request.query.isEmpty ? parent?.displayTitle ?? L10n.string("Things I can share with my sons", language: catalog.language) : request.query)

        struct Reference: Encodable { let title: String; let idea: String; let explanation: String }
        struct Context: Encodable {
            let goal: String
            let outputLanguage: String
            let ages: [Int]
            let action: String
            let output: String
            let concept: String
            let query: String
            let depth: Int
            let trail: [String]
            let siblings: [String]
            let libraryReferences: [Reference]
        }
        let terms = WanderCatalog.meaningfulWords(concept)
        let references = catalog.activities.filter { activity in
            let words = WanderCatalog.words(activity.title + " " + activity.takeaway + " " + activity.skill.title(language: catalog.language))
            return terms.contains { words.contains($0) }
        }.prefix(2).map { Reference(title: $0.title, idea: $0.takeaway, explanation: String($0.parentPrimer.prefix(400))) }
        let context = Context(goal: "Help a parent share their knowledge through a flexible half-hour family experience.",
            outputLanguage: catalog.language.generationLanguage, ages: [2, 6], action: request.action.rawValue, output: requiresLesson ? "lesson" : "topic map",
            concept: concept, query: request.query, depth: depth,
            trail: Array((parent?.path ?? []).suffix(4)).map { String($0.prefix(80)) },
            siblings: (parent?.bubbles ?? []).map { String($0.label.prefix(40)) }, libraryReferences: references)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        let json = String(decoding: try encoder.encode(context), as: UTF8.self)
        return WanderGenerationPlan(concept: concept, requiresLesson: requiresLesson, contextJSON: json,
            providerID: providerID, incoming: incoming, request: request, parent: parent, selected: selected,
            revisionID: revision?.id,
            cacheKey: try digest(request, includeRefresh: false, providerID: providerID + Self.generationPromptVersion),
            signature: try digest(incoming, providerID: providerID + Self.generationPromptVersion),
            startingLayerID: state.currentLayerID, catalogID: catalog.identity)
    }

    public mutating func reuseGeneration(_ plan: WanderGenerationPlan) throws -> WanderLayer? {
        if let receipt = state.receipts.first(where: { $0.requestID == plan.incoming.requestID }) {
            guard receipt.signature == plan.signature else { throw WanderError.requestConflict }
            try open(receipt.layerID)
            return current
        }
        if plan.revisionID == nil, let saved = state.layers.last(where: { $0.cacheKey == plan.cacheKey }) {
            state.currentLayerID = saved.id
            state.receipts.append(WanderReceipt(requestID: plan.incoming.requestID, signature: plan.signature, layerID: saved.id))
            return saved
        }
        return nil
    }

    public mutating func acceptGenerated(_ draft: WanderGeneratedDraft, for plan: WanderGenerationPlan) throws -> WanderLayer {
        if let reused = try reuseGeneration(plan) { return reused }
        guard state.currentLayerID == plan.startingLayerID, catalog.identity == plan.catalogID else {
            throw WanderGenerationError.staleRequest
        }
        func checked(_ value: String, max: Int) throws -> String {
            let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, text.count <= max else { throw WanderGenerationError.invalidOutput }
            return text
        }
        if let parent = plan.parent {
            guard state.layers.contains(where: { $0.id == parent.id }) else { throw WanderGenerationError.staleRequest }
        }
        let title = try checked(draft.title, max: 80)
        let summary = try checked(draft.summary, max: 260)
        let bubbles: [WanderBubble]
        let lesson: WanderLesson?
        if plan.requiresLesson {
            guard draft.topics.isEmpty, let value = draft.lesson else { throw WanderGenerationError.invalidOutput }
            bubbles = []
            lesson = try WanderLesson(definition: checked(value.definition, max: 1400), exampleTitle: title,
                example: checked(value.example, max: 2000), consideration: checked(value.consideration, max: 700),
                toddler: AgePrompt(action: checked(value.toddlerAction, max: 600), question: checked(value.toddlerQuestion, max: 250)),
                older: AgePrompt(action: checked(value.olderAction, max: 600), question: checked(value.olderQuestion, max: 250)),
                personalPrompt: checked(value.personalPrompt, max: 500), activityID: nil)
        } else {
            guard draft.lesson == nil, (2...6).contains(draft.topics.count) else { throw WanderGenerationError.invalidOutput }
            let labels = draft.topics.map { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            guard Set(labels).count == labels.count,
                  !labels.contains(plan.concept.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) else { throw WanderGenerationError.invalidOutput }
            let skill = plan.selected?.skill ?? plan.parent?.bubbles.compactMap(\.skill).first
            bubbles = try draft.topics.map { topic in
                let id = UUID().uuidString
                return try WanderBubble(id: id, targetID: "generated:\(id)", label: checked(topic.label, max: 40),
                    summary: checked(topic.summary, max: 240), symbol: skill?.symbol ?? "sparkles", skill: skill)
            }
            lesson = nil
        }
        let id = UUID().uuidString
        let parent = plan.parent
        let layer = WanderLayer(id: id, parentID: parent?.id, selectedBubbleID: plan.selected?.id,
            ancestorIDs: parent.map { $0.ancestorIDs + [$0.id] } ?? [],
            branchID: parent.map { $0.depth == 0 ? id : $0.branchID } ?? id,
            depth: (parent?.depth ?? -1) + 1, path: (parent?.path ?? []) + [title],
            nodeID: "generated:\(id)", title: title, summary: summary, bubbles: bubbles, lesson: lesson,
            createdAt: Date(), cacheKey: plan.cacheKey, revisionOf: plan.revisionID, request: plan.request,
            provenance: WanderProvenance(providerID: plan.providerID, promptVersion: Self.generationPromptVersion, context: plan.contextJSON))
        state.layers.append(layer)
        state.currentLayerID = id
        state.receipts.append(WanderReceipt(requestID: plan.incoming.requestID, signature: plan.signature, layerID: id))
        return layer
    }
}
