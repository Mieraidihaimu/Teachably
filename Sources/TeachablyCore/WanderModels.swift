import Foundation

public enum WanderAction: String, Codable, Sendable {
    case root, expand, refine, explain, example, refresh
}

public enum WanderLayout: String, Codable, CaseIterable, Sendable {
    case automatic, map, list
    public var title: String {
        switch self { case .automatic: L10n.string("Auto"); case .map: L10n.string("Map"); case .list: L10n.string("List") }
    }
}

public struct WanderViewport: Codable, Equatable, Sendable {
    public var scale: Double = 1
    public var x: Double = 0
    public var y: Double = 0
    public init() {}
    public func bounded() -> Self {
        var result = self
        result.scale = scale.isFinite ? min(1.5, max(0.75, scale)) : 1
        result.x = x.isFinite ? min(150, max(-150, x)) : 0
        result.y = y.isFinite ? min(150, max(-150, y)) : 0
        return result
    }
}

public struct WanderRequest: Codable, Equatable, Sendable {
    public var action: WanderAction
    public var parentID: String?
    public var bubbleID: String?
    public var query: String
    public var refreshLayerID: String?
    public var requestID: String
    public init(action: WanderAction, parentID: String? = nil, bubbleID: String? = nil,
                query: String = "", refreshLayerID: String? = nil, requestID: String = UUID().uuidString) {
        self.action = action; self.parentID = parentID; self.bubbleID = bubbleID
        self.query = query; self.refreshLayerID = refreshLayerID; self.requestID = requestID
    }
}

public struct WanderBubble: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let targetID: String
    public let label: String
    public let summary: String
    public let symbol: String
    public let skill: Skill?
}

public struct WanderLesson: Codable, Equatable, Sendable {
    public let definition: String
    public let exampleTitle: String
    public let example: String
    public let consideration: String
    public let toddler: AgePrompt
    public let older: AgePrompt
    public let personalPrompt: String
    public let activityID: String?
}

public struct WanderLayer: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let parentID: String?
    public let selectedBubbleID: String?
    public let ancestorIDs: [String]
    public let branchID: String
    public let depth: Int
    public let path: [String]
    public let nodeID: String
    public let title: String
    public let summary: String
    public let bubbles: [WanderBubble]
    public let lesson: WanderLesson?
    public let createdAt: Date
    public let cacheKey: String
    public let revisionOf: String?
    public let request: WanderRequest
    public let provenance: WanderProvenance?
    public var isMap: Bool { lesson == nil }
    public var displayTitle: String { isMap || provenance != nil ? title : summary }
}

public struct WanderSnapshot: Codable, Equatable, Sendable {
    public let layer: WanderLayer
    public let viewport: WanderViewport
}

public struct WanderPin: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let createdAt: Date
    public let snapshot: WanderSnapshot
    public var note: String
    public var isArchived: Bool

    public var markdown: String {
        let layer = snapshot.layer
        func escaped(_ value: String) -> String {
            value.replacingOccurrences(of: #"([\\`*_{}\[\]<>#+!|])"#, with: #"\\$1"#, options: .regularExpression)
        }
        var sections = ["# \(escaped(layer.displayTitle))",
            "**\(L10n.string("Trail")):** \(layer.path.map(escaped).joined(separator: " → "))",
            "## " + L10n.string("Why I saved this"), note.isEmpty ? L10n.string("No personal note yet.") : escaped(note),
            "## " + L10n.string("The idea"), escaped(layer.summary)]
        if let lesson = layer.lesson {
            sections += [escaped(lesson.definition), "## " + L10n.format("Try it together: %@", escaped(lesson.exampleTitle)),
                escaped(lesson.example), "## " + L10n.string("At age 2"), escaped(lesson.toddler.action),
                escaped(lesson.toddler.question), "## " + L10n.string("At age 6"), escaped(lesson.older.action),
                escaped(lesson.older.question), "## " + L10n.string("Bring a little of you"), escaped(lesson.personalPrompt),
                "## " + L10n.string("Keep in mind"), escaped(lesson.consideration)]
        } else {
            sections += ["## " + L10n.string("Ideas to explore"), layer.bubbles.map { "- **\(escaped($0.label)):** \(escaped($0.summary))" }.joined(separator: "\n")]
        }
        sections += ["---", layer.provenance == nil ? L10n.string("Saved with Teachably · from the activity library.") : L10n.string("Saved with Teachably · generated on device with Apple Intelligence. Review before sharing with children.")]
        return sections.joined(separator: "\n\n") + "\n"
    }
}

public struct WanderReceipt: Codable, Equatable, Sendable {
    let requestID: String
    let signature: String
    let layerID: String
}

public struct WanderState: Codable, Equatable, Sendable {
    public var layers: [WanderLayer] = []
    public var pins: [WanderPin] = []
    public var currentLayerID: String?
    public var viewports: [String: WanderViewport] = [:]
    public var layout: WanderLayout = .automatic
    var receipts: [WanderReceipt] = []
    public init() {}
    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
    public static func decode(_ data: Data) throws -> Self { try JSONDecoder().decode(Self.self, from: data) }
}

public enum WanderSearchScope: Sendable {
    case all, branch(String), layer(String)
}

public struct WanderSearchHit: Identifiable, Equatable, Sendable {
    public let id: String
    public let layerID: String
    public let bubbleID: String?
    public let label: String
    public let summary: String
    public let depth: Int
    public let isExact: Bool
    let score: Int
}

public enum WanderError: LocalizedError, Equatable {
    case missingLayer, invalidBubble, invalidRequest, requestConflict, unknownTopic, depthLimit, invalidScope, noteTooLong
    public var errorDescription: String? {
        switch self {
        case .missingLayer: L10n.string("That saved idea couldn't be found. Your other trails are still here.")
        case .invalidBubble: L10n.string("That topic doesn't belong to this map. Choose an idea on the current map.")
        case .invalidRequest: L10n.string("Choose a topic or enter a question of up to 240 characters.")
        case .requestConflict: L10n.string("That request was already used for a different exploration. Try again.")
        case .unknownTopic: L10n.string("There isn't a matching idea in this library yet. Try a displayed topic or a word such as shadows, reading, or loops.")
        case .depthLimit: L10n.string("Return to an earlier part of your trail to explore another direction.")
        case .invalidScope: L10n.string("Choose a depth range from 0 to 12, with the smaller number first.")
        case .noteTooLong: L10n.string("Keep your note within 600 characters.")
        }
    }
}
