import Foundation
import CryptoKit

struct WanderNode {
    let id: String
    let title: String
    let summary: String
    let symbol: String
    let skill: Skill?
    let children: [String]
    let activityID: String?
    let focus: String?
    let aliases: String
}

struct WanderContent {
    let title: String
    let summary: String
    let bubbles: [WanderBubble]
    let lesson: WanderLesson?
}

public struct WanderCatalog: Sendable {
    public let activities: [Activity]
    public let identity: String
    private let interests: Set<Skill>

    public init(activities: [Activity], interests: Set<Skill>) {
        self.activities = activities
        self.interests = interests.isEmpty ? Set(Skill.allCases) : interests
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let bytes = (try? encoder.encode(activities.sorted { $0.id < $1.id })) ?? Data()
        self.identity = "teachably-wander-v1:" + SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            + ":" + self.interests.map(\.rawValue).sorted().joined(separator: ",")
    }

    private func description(for skill: Skill) -> String {
        switch skill {
        case .numbers: "Use counting, patterns, and choices to make everyday maths visible."
        case .reading: "Share a book, notice its clues, and discover what words can do."
        case .movement: "Explore comfortable movement, coordination, and taking a pause."
        case .science: "Notice light, sound, and motion, then change one thing and look again."
        case .journaling: "Keep a small moment in marks, pictures, dictated words, or writing."
        case .coding: "Give instructions, repeat a sequence, and find a step worth changing."
        case .criticalThinking: "Notice clues, ask questions, compare ideas, and let your thinking change."
        case .making: "Try a design, see how it works, and make a small improvement."
        case .nature: "Look closely at familiar outdoor places and notice their differences."
        case .cooking: "Explore quantities and sequences through familiar kitchen routines."
        case .music: "Listen, copy, and make patterns with sounds and silences."
        case .storytelling: "Connect characters, places, and possibilities in a story of your own."
        }
    }

    private func aliases(for skill: Skill) -> String {
        switch skill {
        case .numbers: "math maths mathematics counting quantity numbers money patterns"
        case .reading: "read reading books words literacy letters pictures"
        case .movement: "movement exercise sport balance coordination"
        case .science: "science physics light sound gravity motion shadows vibrations ramp"
        case .journaling: "diary writing journal journaling reflection memory memories feelings"
        case .coding: "coding programming code algorithms sequences loop loops debugging instructions robot"
        case .criticalThinking: "critical thinking reasoning evidence clues questions guesses decisions"
        default: skill.title.lowercased()
        }
    }

    func node(_ id: String) throws -> WanderNode {
        if id == "root" {
            let skills = Skill.allCases.filter { skill in interests.contains(skill) && activities.contains { $0.skill == skill } }
            return WanderNode(id: id, title: "Follow your curiosity.",
                summary: "Start with something you know. Follow an idea until it becomes something you can share.",
                symbol: "safari", skill: nil, children: skills.map { "skill:\($0.rawValue)" },
                activityID: nil, focus: nil, aliases: "")
        }
        let parts = id.split(separator: ":").map(String.init)
        if parts.count == 2, parts[0] == "skill", let skill = Skill(rawValue: parts[1]) {
            let matching = activities.filter { $0.skill == skill }
            return WanderNode(id: id, title: skill.title, summary: description(for: skill), symbol: skill.symbol,
                skill: skill, children: matching.map { "activity:\($0.id)" }, activityID: matching.first?.id,
                focus: nil, aliases: aliases(for: skill))
        }
        if parts.count >= 2, ["activity", "lesson"].contains(parts[0]),
           let activity = activities.first(where: { $0.id == parts[1] }) {
            let focus = parts.count == 3 ? parts[2] : nil
            let title: String
            switch focus {
            case "idea": title = "The little discovery"
            case "example": title = "An example to try"
            case "questions": title = "Questions worth asking"
            default: title = activity.title
            }
            let summary: String
            switch focus {
            case "idea": summary = activity.takeaway
            case "example": summary = "See it in action, with a way for each child to join in."
            case "questions": summary = "Notice, wonder, and bring a little of your own experience."
            default: summary = activity.takeaway
            }
            return WanderNode(id: id, title: title, summary: summary, symbol: activity.symbol, skill: activity.skill,
                children: parts[0] == "lesson" ? [] : ["idea", "example", "questions"].map { "lesson:\(activity.id):\($0)" },
                activityID: activity.id, focus: focus, aliases: activity.title + " " + activity.subtitle)
        }
        throw WanderError.unknownTopic
    }

    func content(nodeID: String, forceLesson: Bool, example: Bool) throws -> WanderContent {
        let selected = try node(nodeID)
        if !forceLesson && !selected.children.isEmpty {
            let bubbles = try selected.children.map { id -> WanderBubble in
                let child = try node(id)
                return WanderBubble(id: UUID().uuidString, targetID: id, label: child.title,
                    summary: child.summary, symbol: child.symbol, skill: child.skill)
            }
            return WanderContent(title: selected.title, summary: selected.summary, bubbles: bubbles, lesson: nil)
        }
        guard let activity = activities.first(where: { $0.id == selected.activityID })
            ?? activities.first(where: { interests.contains($0.skill) }) else { throw WanderError.unknownTopic }
        let isQuestions = selected.focus == "questions"
        let definition = nodeID == "root" ? "Something you already know can become a shared discovery. Start with a small example, let each child join in their own way, and follow what they notice."
            : nodeID.hasPrefix("skill:") ? selected.summary : activity.parentPrimer
        let practical = isQuestions
            ? "At 2, invite: “\(activity.toddler.question)”\n\nAt 6, invite: “\(activity.older.question)”\n\n\(activity.personalPrompt)"
            : "Gather \(activity.materials.joined(separator: ", ").lowercased()).\n\n\(activity.steps.first(where: { $0.minutes == 17 })?.instruction ?? activity.subtitle)"
        return WanderContent(title: isQuestions ? "Questions worth asking" : example || selected.focus == "example" ? "An example to try" : "The little discovery",
            summary: selected.focus == nil ? selected.title : activity.title, bubbles: [],
            lesson: WanderLesson(definition: definition, exampleTitle: activity.title, example: practical,
                consideration: activity.careNote, toddler: activity.toddler, older: activity.older,
                personalPrompt: activity.personalPrompt, activityID: activity.id))
    }

    func resolve(_ query: String, near parentNodeID: String?) throws -> String {
        let terms = Self.meaningfulWords(query)
        guard !terms.isEmpty else { throw WanderError.unknownTopic }
        let candidates = Skill.allCases.map { "skill:\($0.rawValue)" } + activities.map { "activity:\($0.id)" }
        let parent = try parentNodeID.map(node)
        let ranked = try candidates.map { id -> (String, Int) in
            let item = try node(id)
            let label = Self.words(item.title)
            let aliases = Self.words(item.aliases)
            let summary = Self.words(item.summary)
            var score = terms.reduce(0) { value, term in
                value + (label.contains(term) ? 8 : aliases.contains(term) ? 4 : summary.contains(term) ? 1 : 0)
            }
            if score > 0, parent?.children.contains(id) == true { score += 2 }
            return (id, score)
        }.sorted { $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 > $1.1 }
        guard let best = ranked.first, best.1 > 0 else { throw WanderError.unknownTopic }
        return best.0
    }

    static func words(_ text: String) -> [String] {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_GB"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
    }
    static func meaningfulWords(_ text: String) -> [String] {
        let ignored: Set<String> = ["a", "an", "the", "and", "to", "of", "for", "with", "me", "i", "you", "my", "is", "are", "does", "do", "can", "could", "would", "please", "explain", "define", "teach", "tell", "about", "what", "why", "how", "show", "give", "example", "examples", "worked", "practical", "concrete", "understand", "help", "explore", "this", "that", "it"]
        return words(text).filter { !ignored.contains($0) }
    }
}
