import Foundation

public enum WanderAction: String, Codable, Sendable {
    case root, expand, refine, explain, example, refresh
}

public enum WanderLayout: String, Codable, CaseIterable, Sendable {
    case automatic, map, list
    public var title: String {
        switch self { case .automatic: "Auto"; case .map: "Map"; case .list: "List" }
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
    public let activityID: String
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
    public var isMap: Bool { lesson == nil }
    public var displayTitle: String { isMap ? title : summary }
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
            "**Trail:** \(layer.path.map(escaped).joined(separator: " → "))",
            "## Why I saved this", note.isEmpty ? "No personal note yet." : escaped(note),
            "## The idea", escaped(layer.summary)]
        if let lesson = layer.lesson {
            sections += [escaped(lesson.definition), "## Try it together: \(escaped(lesson.exampleTitle))",
                escaped(lesson.example), "## At age 2", escaped(lesson.toddler.action),
                escaped(lesson.toddler.question), "## At age 6", escaped(lesson.older.action),
                escaped(lesson.older.question), "## Bring a little of you", escaped(lesson.personalPrompt),
                "## Keep in mind", escaped(lesson.consideration)]
        } else {
            sections += ["## Ideas to explore", layer.bubbles.map { "- **\(escaped($0.label)):** \(escaped($0.summary))" }.joined(separator: "\n")]
        }
        sections += ["---", "Saved with Teachably · from the activity library."]
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
        case .missingLayer: "That saved idea couldn't be found. Your other trails are still here."
        case .invalidBubble: "That topic doesn't belong to this map. Choose an idea on the current map."
        case .invalidRequest: "Choose a topic or enter a question of up to 240 characters."
        case .requestConflict: "That request was already used for a different exploration. Try again."
        case .unknownTopic: "There isn't a matching idea in this library yet. Try a displayed topic or a word such as shadows, reading, or loops."
        case .depthLimit: "Return to an earlier part of your trail to explore another direction."
        case .invalidScope: "Choose a depth range from 0 to 12, with the smaller number first."
        case .noteTooLong: "Keep your note within 600 characters."
        }
    }
}
