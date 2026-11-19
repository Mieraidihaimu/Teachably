import Foundation

public enum Skill: String, Codable, CaseIterable, Identifiable, Sendable {
    // Keep the existing raw values so saved profiles and activities still open.
    case numbers, reading, movement, science, journaling, coding, criticalThinking
    case making, nature, cooking, music, storytelling

    public static let familyInterests: Set<Skill> = [
        .numbers, .reading, .movement, .science, .journaling, .coding, .criticalThinking
    ]

    public var id: String { rawValue }
    public var title: String { title(language: L10n.language) }
    public func title(language: AppLanguage) -> String {
        switch self {
        case .making: L10n.string("Making & fixing", language: language)
        case .nature: L10n.string("Nature & outdoors", language: language)
        case .cooking: L10n.string("Around the kitchen", language: language)
        case .music: L10n.string("Music & rhythm", language: language)
        case .storytelling: L10n.string("Stories & imagination", language: language)
        case .numbers: L10n.string("Maths & numbers", language: language)
        case .reading: L10n.string("Reading together", language: language)
        case .science: L10n.string("Everyday physics", language: language)
        case .movement: L10n.string("Movement & exercise", language: language)
        case .journaling: L10n.string("Diary writing", language: language)
        case .coding: L10n.string("Coding & logic", language: language)
        case .criticalThinking: L10n.string("Critical thinking", language: language)
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

    public init(action: String, question: String) {
        self.action = action
        self.question = question
    }
}

public struct ActivityStep: Codable, Hashable, Sendable {
    public let title: String
    public let minutes: Int
    public let instruction: String

    public init(title: String, minutes: Int, instruction: String) {
        self.title = title
        self.minutes = minutes
        self.instruction = instruction
    }
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
    public private(set) var steps: [ActivityStep]
    public let personalPrompt: String
    public let careNote: String
    public let primary: AgePrompt?
    public let siblingRole: String?
    public let conditions: [IdeaConstraint]?
    public let quickDiscovery: String?
    public let sourceWanderLayerID: String?
    public var duration: Int { steps.reduce(0) { $0 + $1.minutes } }

    init(id: String, title: String, subtitle: String, skill: Skill, symbol: String, takeaway: String,
         parentPrimer: String, materials: [String], toddler: AgePrompt, older: AgePrompt,
         steps: [ActivityStep], personalPrompt: String, careNote: String, primary: AgePrompt? = nil,
         siblingRole: String? = nil, conditions: [IdeaConstraint]? = nil, quickDiscovery: String? = nil,
         sourceWanderLayerID: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.skill = skill
        self.symbol = symbol
        self.takeaway = takeaway
        self.parentPrimer = parentPrimer
        self.materials = materials
        self.toddler = toddler
        self.older = older
        self.steps = steps
        self.personalPrompt = personalPrompt
        self.careNote = careNote
        self.primary = primary
        self.siblingRole = siblingRole
        self.conditions = conditions
        self.quickDiscovery = quickDiscovery
        self.sourceWanderLayerID = sourceWanderLayerID
    }

    public func prompt(for band: DevelopmentalBand, language: AppLanguage = L10n.language) -> AgePrompt {
        switch band {
        case .toddler: toddler
        case .earlyYears: older
        case .primary: primary ?? older.extending(skill, language: language)
        }
    }

    public func siblingPrompt(for profile: FamilyProfile) -> String {
        if let siblingRole {
            return L10n.format("%1$@, help %2$@ get started. %3$@",
                               profile.olderDisplayName, profile.youngerDisplayName, siblingRole)
        }
        return L10n.format("%1$@, show %2$@ how to join in, then ask: “%3$@”",
                           profile.olderDisplayName, profile.youngerDisplayName, toddler.question)
    }

    public var quickVersion: Activity? {
        guard let quickDiscovery, steps.count == 4 else { return nil }
        var activity = self
        let minutes = [2, 3, 8, 2]
        activity.steps = steps.enumerated().map { index, step in
            ActivityStep(title: step.title, minutes: minutes[index],
                         instruction: index == 2 ? quickDiscovery : step.instruction)
        }
        return activity
    }
}

public struct FamilyProfile: Codable, Equatable, Sendable {
    public var youngerName = "Little explorer"
    public var olderName = "Big explorer"
    public var youngerBirthMonth: BirthMonth?
    public var olderBirthMonth: BirthMonth?
    public var skills: Set<Skill> = Skill.familyInterests
    public var youngerDisplayName: String {
        youngerName.isEmpty || youngerName == "Little explorer" ? L10n.string("Little explorer") : youngerName
    }
    public var olderDisplayName: String {
        olderName.isEmpty || olderName == "Big explorer" ? L10n.string("Big explorer") : olderName
    }
    public var hasChosenSkills = false
    public init() {}
}

public struct DailyPlan: Codable, Equatable, Sendable {
    public var day: String
    public var activityID: String
    public var offeredIDs: [String]
    public var isQuick: Bool?
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
    public var customActivities: [Activity]?
    public init() {}
    public func encoded() throws -> Data { try JSONEncoder().encode(self) }
    public static func decode(_ data: Data) throws -> FamilyState {
        try JSONDecoder().decode(Self.self, from: data)
    }
}

public enum ActivityCatalog {
    public static func load(language: AppLanguage = L10n.language) throws -> [Activity] {
        guard let url = L10n.resourceURL("activities", extension: "json", language: language)
            ?? L10n.resourceURL("activities", extension: "json", language: .english) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([Activity].self, from: Data(contentsOf: url))
    }
}
