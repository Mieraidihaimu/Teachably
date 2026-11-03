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
    public let language: AppLanguage
    private let interests: Set<Skill>

    public init(activities: [Activity], interests: Set<Skill>, language: AppLanguage = L10n.language) {
        self.language = language
        self.activities = activities
        self.interests = interests.isEmpty ? Set(Skill.allCases) : interests
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let bytes = (try? encoder.encode(activities.sorted { $0.id < $1.id })) ?? Data()
        self.identity = "teachably-wander-v1:" + language.rawValue + ":" + SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            + ":" + self.interests.map(\.rawValue).sorted().joined(separator: ",")
    }

    private func description(for skill: Skill) -> String {
        switch skill {
        case .numbers: L10n.string("Use counting, patterns, and choices to make everyday maths visible.", language: language)
        case .reading: L10n.string("Share a book, notice its clues, and discover what words can do.", language: language)
        case .movement: L10n.string("Explore comfortable movement, coordination, and taking a pause.", language: language)
        case .science: L10n.string("Notice light, sound, and motion, then change one thing and look again.", language: language)
        case .journaling: L10n.string("Keep a small moment in marks, pictures, dictated words, or writing.", language: language)
        case .coding: L10n.string("Give instructions, repeat a sequence, and find a step worth changing.", language: language)
        case .criticalThinking: L10n.string("Notice clues, ask questions, compare ideas, and let your thinking change.", language: language)
        case .making: L10n.string("Try a design, see how it works, and make a small improvement.", language: language)
        case .nature: L10n.string("Look closely at familiar outdoor places and notice their differences.", language: language)
        case .cooking: L10n.string("Explore quantities and sequences through familiar kitchen routines.", language: language)
        case .music: L10n.string("Listen, copy, and make patterns with sounds and silences.", language: language)
        case .storytelling: L10n.string("Connect characters, places, and possibilities in a story of your own.", language: language)
        }
    }

    private func aliases(for skill: Skill) -> String {
        skill.searchAliases(language: language)
    }

    func node(_ id: String) throws -> WanderNode {
        if id == "root" {
            let skills = Skill.allCases.filter { skill in interests.contains(skill) && activities.contains { $0.skill == skill } }
            return WanderNode(id: id, title: L10n.string("Follow your curiosity.", language: language),
                summary: L10n.string("Start with something you know. Follow an idea until it becomes something you can share.", language: language),
                symbol: "safari", skill: nil, children: skills.map { "skill:\($0.rawValue)" },
                activityID: nil, focus: nil, aliases: "")
        }
        let parts = id.split(separator: ":").map(String.init)
        if parts.count == 2, parts[0] == "skill", let skill = Skill(rawValue: parts[1]) {
            let matching = activities.filter { $0.skill == skill }
            return WanderNode(id: id, title: skill.title(language: language), summary: description(for: skill), symbol: skill.symbol,
                skill: skill, children: matching.map { "activity:\($0.id)" }, activityID: matching.first?.id,
                focus: nil, aliases: aliases(for: skill))
        }
        if parts.count >= 2, ["activity", "lesson"].contains(parts[0]),
           let activity = activities.first(where: { $0.id == parts[1] }) {
            let focus = parts.count == 3 ? parts[2] : nil
            let title: String
            switch focus {
            case "idea": title = L10n.string("The little discovery", language: language)
            case "example": title = L10n.string("An example to try", language: language)
            case "questions": title = L10n.string("Questions worth asking", language: language)
            default: title = activity.title
            }
            let summary: String
            switch focus {
            case "idea": summary = activity.takeaway
            case "example": summary = L10n.string("See it in action, with a way for each child to join in.", language: language)
            case "questions": summary = L10n.string("Notice, wonder, and bring a little of your own experience.", language: language)
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
        let definition = nodeID == "root" ? L10n.string("Something you already know can become a shared discovery. Start with a small example, let each child join in their own way, and follow what they notice.", language: language)
            : nodeID.hasPrefix("skill:") ? selected.summary : activity.parentPrimer
        let practical = isQuestions
            ? L10n.format("At 2, invite: “%@”\n\nAt 6, invite: “%@”\n\n%@", activity.toddler.question, activity.older.question, activity.personalPrompt, language: language)
            : L10n.format("Gather %@.\n\n%@", activity.materials.joined(separator: ", "), activity.steps.first(where: { $0.minutes == 17 })?.instruction ?? activity.subtitle, language: language)
        return WanderContent(title: isQuestions ? L10n.string("Questions worth asking", language: language) : example || selected.focus == "example" ? L10n.string("An example to try", language: language) : L10n.string("The little discovery", language: language),
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
        let normalized = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        var words: [String] = []
        normalized.enumerateSubstrings(in: normalized.startIndex..<normalized.endIndex, options: .byWords) { word, _, _, _ in
            if let word { words.append(word) }
        }
        return words
    }
    static func meaningfulWords(_ text: String) -> [String] {
        let ignored: Set<String> = [
            "a", "an", "the", "and", "to", "of", "for", "with", "me", "i", "you", "my", "is", "are", "does", "do", "can", "could", "would", "please", "explain", "define", "teach", "tell", "about", "what", "why", "how", "show", "give", "example", "examples", "worked", "practical", "concrete", "understand", "help", "explore", "this", "that", "it",
            "el", "la", "los", "las", "un", "una", "unos", "unas", "de", "del", "al", "y", "o", "en", "con", "para", "por", "que", "es", "son", "como", "explica", "explicame", "ensename", "muestra", "dame", "ejemplo", "ejemplos", "sobre", "favor", "puedes", "podrias",
            "apa", "itu", "ini", "mengapa", "kenapa", "bagaimana", "tolong", "jelaskan", "terangkan", "beri", "berikan", "contoh", "tentang", "dengan", "untuk", "dan", "yang", "di", "ke", "dari", "saya", "kami", "kita", "adalah", "bisa", "dapat",
            "请", "請", "解释", "解釋", "说明", "說明", "什么", "什麼", "是", "为什么", "為什麼", "如何", "给", "給", "我", "一个", "一個", "例子",
            "は", "が", "を", "の", "に", "で", "と", "です", "ます", "なぜ", "どうして", "説明", "解説", "教え", "教えて", "て", "し", "例", "何", "なに", "か", "ください", "つい", "について"
        ]
        return words(text).filter { !ignored.contains($0) }
    }
}
