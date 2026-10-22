import Foundation

public enum Skill: String, Codable, CaseIterable, Identifiable, Sendable {
    // Keep the existing raw values so saved profiles and activities still open.
    case numbers, reading, movement, science, journaling, coding, criticalThinking
    case making, nature, cooking, music, storytelling

    public static let familyInterests: Set<Skill> = [
        .numbers, .reading, .movement, .science, .journaling, .coding, .criticalThinking
    ]

    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .making: "Making & fixing"
        case .nature: "Nature & outdoors"
        case .cooking: "Around the kitchen"
        case .music: "Music & rhythm"
        case .storytelling: "Stories & imagination"
        case .numbers: "Maths & numbers"
        case .reading: "Reading together"
        case .science: "Everyday physics"
        case .movement: "Movement & exercise"
        case .journaling: "Diary writing"
        case .coding: "Coding & logic"
        case .criticalThinking: "Critical thinking"
        }
    }
    public var symbol: String {
        switch self {
        case .making: "hammer"
        case .nature: "leaf"
        case .cooking: "carrot"
        case .music: "music.note"
        case .storytelling: "book.closed"
        case .numbers: "number"
        case .reading: "book"
        case .science: "sparkles"
        case .movement: "figure.play"
        case .journaling: "square.and.pencil"
        case .coding: "chevron.left.forwardslash.chevron.right"
        case .criticalThinking: "lightbulb"
        }
    }
}

public struct AgePrompt: Codable, Hashable, Sendable {
    public let action: String
    public let question: String
}

public struct ActivityStep: Codable, Hashable, Sendable {
    public let title: String
    public let minutes: Int
    public let instruction: String
}

public struct Activity: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let skill: Skill
    public let symbol: String
    public let takeaway: String
    public let parentPrimer: String
    public let materials: [String]
    public let toddler: AgePrompt
    public let older: AgePrompt
    public let steps: [ActivityStep]
    public let personalPrompt: String
    public let careNote: String
    public var duration: Int { steps.reduce(0) { $0 + $1.minutes } }
}

public struct FamilyProfile: Codable, Equatable, Sendable {
    public var youngerName = "Little explorer"
    public var olderName = "Big explorer"
    public var skills: Set<Skill> = Skill.familyInterests
    public var hasChosenSkills = false
    public init() {}
}

public struct DailyPlan: Codable, Equatable, Sendable {
    public var day: String
    public var activityID: String
    public var offeredIDs: [String]
    public init(day: String, activityID: String, offeredIDs: [String]) {
        self.day = day
        self.activityID = activityID
        self.offeredIDs = offeredIDs
    }
}

public struct Memory: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var activityID: String
    public var date: Date
    public var note: String
    public var favourite: Bool
    public init(activityID: String, date: Date = Date(), note: String, favourite: Bool) {
        self.id = UUID()
        self.activityID = activityID
        self.date = date
        self.note = note
        self.favourite = favourite
    }
}

public struct FamilyState: Codable, Equatable, Sendable {
    public var profile = FamilyProfile()
    public var plans: [DailyPlan] = []
    public var memories: [Memory] = []
    public var teachingNotes: [String: String] = [:]
    public init() {}
    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
    public static func decode(_ data: Data) throws -> FamilyState {
        try JSONDecoder().decode(Self.self, from: data)
    }
}

public enum ActivityCatalog {
    public static func load() throws -> [Activity] {
        guard let url = Bundle.module.url(forResource: "activities", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([Activity].self, from: Data(contentsOf: url))
    }
}
