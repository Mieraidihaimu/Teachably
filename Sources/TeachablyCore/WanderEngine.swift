import Foundation
import CryptoKit

/// A local, value-based port of Wander's saved-layer, exact-reuse, trail,
/// recall, and immutable-pin mechanics. Model generation is prepared and
/// validated here; the app supplies an on-device provider asynchronously.
public struct WanderEngine: Sendable {
    public internal(set) var state: WanderState
    public let catalog: WanderCatalog
    public init(catalog: WanderCatalog, state: WanderState = WanderState()) {
        self.catalog = catalog; self.state = state
    }
    public var current: WanderLayer? { state.layers.first { $0.id == state.currentLayerID } }
    public var activePins: [WanderPin] { state.pins.filter { !$0.isArchived }.reversed() }
    public var visitedBubbleIDs: Set<String> { Set(state.layers.compactMap(\.selectedBubbleID)) }
    public var viewport: WanderViewport { state.currentLayerID.flatMap { state.viewports[$0] } ?? WanderViewport() }

    private struct Identity: Codable {
        let catalog: String
        let action: WanderAction
        let parentID: String?
        let bubbleID: String?
        let query: String
        let refreshLayerID: String?
        let providerID: String?
    }
    func digest(_ request: WanderRequest, includeRefresh: Bool = true, providerID: String? = nil) throws -> String {
        let identity = Identity(catalog: catalog.identity, action: request.action, parentID: request.parentID,
            bubbleID: request.bubbleID, query: request.query.trimmingCharacters(in: .whitespacesAndNewlines),
            refreshLayerID: includeRefresh ? request.refreshLayerID : nil, providerID: providerID)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys]
        return SHA256.hash(data: try encoder.encode(identity)).map { String(format: "%02x", $0) }.joined()
    }

    public mutating func explore(_ incoming: WanderRequest) throws -> WanderLayer {
        guard incoming.query.count <= 240, !incoming.requestID.isEmpty else { throw WanderError.invalidRequest }
        let signature = try digest(incoming)
        if let receipt = state.receipts.first(where: { $0.requestID == incoming.requestID }) {
            guard receipt.signature == signature else { throw WanderError.requestConflict }
            try open(receipt.layerID)
            return current!
        }
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

        var selected: WanderBubble?
        if let bubbleID = request.bubbleID {
            guard let bubble = parent?.bubbles.first(where: { $0.id == bubbleID }) else { throw WanderError.invalidBubble }
            selected = bubble
        }
        if request.action == .expand && selected == nil { throw WanderError.invalidBubble }
        let query = request.query.trimmingCharacters(in: .whitespacesAndNewlines)
        if request.action == .refine && query.isEmpty { throw WanderError.invalidRequest }
        let nodeID: String
        if let selected { nodeID = selected.targetID }
        else if !query.isEmpty {
            if Self.requestsExplanation(query), WanderCatalog.meaningfulWords(query).isEmpty, let parent {
                nodeID = parent.nodeID
            } else { nodeID = try catalog.resolve(query, near: parent?.nodeID) }
        } else { nodeID = request.action == .root ? "root" : parent!.nodeID }

        let cacheKey = try digest(request, includeRefresh: false)
        if revision == nil, let cached = state.layers.last(where: { $0.cacheKey == cacheKey }) {
            state.currentLayerID = cached.id
            state.receipts.append(WanderReceipt(requestID: incoming.requestID, signature: signature, layerID: cached.id))
            return cached
        }
        let content = try catalog.content(nodeID: nodeID,
            forceLesson: request.action == .explain || request.action == .example || Self.requestsExplanation(query),
            example: request.action == .example)
        let id = UUID().uuidString
        let layer = WanderLayer(id: id, parentID: parent?.id, selectedBubbleID: selected?.id,
            ancestorIDs: parent.map { $0.ancestorIDs + [$0.id] } ?? [],
            branchID: parent.map { $0.depth == 0 ? id : $0.branchID } ?? id,
            depth: (parent?.depth ?? -1) + 1, path: (parent?.path ?? []) + [content.title],
            nodeID: nodeID, title: content.title, summary: content.summary, bubbles: content.bubbles,
            lesson: content.lesson, createdAt: Date(), cacheKey: cacheKey, revisionOf: revision?.id, request: request, provenance: nil)
        // Nothing is changed until the complete layer has been prepared.
        state.layers.append(layer)
        state.currentLayerID = id
        state.receipts.append(WanderReceipt(requestID: incoming.requestID, signature: signature, layerID: id))
        return layer
    }

    public mutating func open(_ id: String) throws {
        guard state.layers.contains(where: { $0.id == id }) else { throw WanderError.missingLayer }
        state.currentLayerID = id
    }
    public mutating func setLayout(_ layout: WanderLayout) { state.layout = layout }
    public mutating func setViewport(_ viewport: WanderViewport) {
        if let id = state.currentLayerID { state.viewports[id] = viewport.bounded() }
    }

    @discardableResult
    public mutating func pinCurrent() throws -> WanderPin {
        guard let layer = current else { throw WanderError.missingLayer }
        if let index = state.pins.firstIndex(where: { $0.snapshot.layer.id == layer.id }) {
            state.pins[index].isArchived = false
            return state.pins[index]
        }
        let pin = WanderPin(id: UUID().uuidString, createdAt: Date(),
            snapshot: WanderSnapshot(layer: layer, viewport: viewport), note: "", isArchived: false)
        state.pins.append(pin)
        return pin
    }
    public mutating func setNote(_ note: String, pinID: String) throws {
        guard note.count <= 600 else { throw WanderError.noteTooLong }
        guard let index = state.pins.firstIndex(where: { $0.id == pinID }) else { throw WanderError.missingLayer }
        state.pins[index].note = note.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    public mutating func archivePin(_ id: String, archived: Bool) throws {
        guard let index = state.pins.firstIndex(where: { $0.id == id }) else { throw WanderError.missingLayer }
        state.pins[index].isArchived = archived
    }
    public mutating func openPin(_ id: String) throws {
        guard let pin = state.pins.first(where: { $0.id == id && !$0.isArchived }) else { throw WanderError.missingLayer }
        if !state.layers.contains(where: { $0.id == pin.snapshot.layer.id }) { state.layers.append(pin.snapshot.layer) }
        state.currentLayerID = pin.snapshot.layer.id
        state.viewports[pin.snapshot.layer.id] = pin.snapshot.viewport
    }

    public func search(_ query: String, scope: WanderSearchScope = .all,
                       minDepth: Int = 0, maxDepth: Int = 12) throws -> [WanderSearchHit] {
        guard minDepth >= 0, maxDepth <= 12, minDepth <= maxDepth else { throw WanderError.invalidScope }
        let terms = WanderCatalog.words(query)
        guard !terms.isEmpty else { return [] }
        let phrase = terms.joined(separator: " ")
        let scoped: [WanderLayer]
        switch scope {
        case .all: scoped = state.layers
        case .branch(let id):
            guard state.layers.contains(where: { $0.id == id }) else { throw WanderError.missingLayer }
            scoped = state.layers.filter { $0.id == id || $0.ancestorIDs.contains(id) }
        case .layer(let id):
            guard let layer = state.layers.first(where: { $0.id == id }) else { throw WanderError.missingLayer }
            scoped = [layer]
        }
        var hits: [WanderSearchHit] = []
        for layer in scoped.reversed() where (minDepth...maxDepth).contains(layer.depth) {
            let records: [(String?, String, String)] = layer.isMap
                ? layer.bubbles.map { ($0.id, $0.label, $0.summary) }
                : [(nil, layer.displayTitle, [layer.summary, layer.lesson?.definition, layer.lesson?.example].compactMap { $0 }.joined(separator: " "))]
            for (bubbleID, label, summary) in records {
                let labelWords = WanderCatalog.words(label)
                let summaryWords = WanderCatalog.words(summary)
                let exact = labelWords.joined(separator: " ") == phrase
                let score = (exact ? 1000 : 0) + terms.reduce(0) { $0 + (labelWords.contains($1) ? 8 : summaryWords.contains($1) ? 1 : 0) }
                if score > 0 {
                    hits.append(WanderSearchHit(id: layer.id + ":" + (bubbleID ?? "lesson"), layerID: layer.id,
                        bubbleID: bubbleID, label: label, summary: summary, depth: layer.depth, isExact: exact, score: score))
                }
            }
        }
        // Search the visible labels and summaries, never match lineage alone.
        return hits.sorted { $0.score > $1.score }.prefix(60).map { $0 }
    }

    public static func requestsExplanation(_ query: String) -> Bool {
        if WanderQuery.requestsLocalizedExplanation(query) { return true }
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"^(?:(?:please\s+)?(?:can|could|would|will)\s+you\s+(?:please\s+)?)"#,
                                  with: "", options: [.regularExpression, .caseInsensitive])
        return text.range(of: #"^(?:please\s+)?(?:explain\b|define\b|teach\s+me\b|tell\s+me\s+about\b|help\s+me\s+understand\b|what\s+(?:is|are|does)\b|why\b|how\s+(?:does|do|can)\b|(?:show|give)\s+(?:me\s+)?(?:a|an|the|some)?\s*(?:worked\s+|concrete\s+|practical\s+)?examples?\b)"#,
                          options: [.regularExpression, .caseInsensitive]) != nil
    }
}
