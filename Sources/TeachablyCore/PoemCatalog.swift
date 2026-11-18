import Foundation

public enum PoemLevel: Int, CaseIterable, Decodable, Identifiable, Sendable {
    case zero = 0, one, two, three, four, five

    public var id: Int { rawValue }
    public var title: String { L10n.format("Level %lld", rawValue) }

    public var description: String {
        switch self {
        case .zero: L10n.string("A few tiny lines")
        case .one: L10n.string("Short, playful rhymes")
        case .two: L10n.string("Rhythm and repetition")
        case .three: L10n.string("Poems with a little story")
        case .four: L10n.string("Longer verses")
        case .five: L10n.string("Bigger reads and richer words")
        }
    }
}

public struct Poem: Decodable, Identifiable, Sendable {
    public enum Source: String, Decodable, Sendable {
        case motherGoose, rossetti, stevenson, lear

        public var author: String {
            switch self {
            case .motherGoose: L10n.string("Traditional nursery rhyme")
            case .rossetti: "Christina Rossetti"
            case .stevenson: "Robert Louis Stevenson"
            case .lear: "Edward Lear"
            }
        }
    }

    public let id: String
    public let level: PoemLevel
    public let title: String
    public let source: Source
    public let text: String
}

public enum PoemCatalog {
    public static func load() throws -> [Poem] {
        guard let url = Bundle.module.url(forResource: "poems", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([Poem].self, from: Data(contentsOf: url))
    }

    public static func search(_ query: String, in poems: [Poem], locale: Locale = L10n.language.locale) -> [Poem] {
        let words = query.replacingOccurrences(of: "’", with: "'").split(whereSeparator: \.isWhitespace)
        return poems.filter { poem in
            let text = "\(poem.title) \(poem.source.author)".replacingOccurrences(of: "’", with: "'")
            return words.allSatisfy {
                text.range(of: $0, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                           locale: locale) != nil
            }
        }
    }
}
