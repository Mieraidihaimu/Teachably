import Foundation

public struct ShowAndTellStory: Decodable, Identifiable, Sendable {
    public struct Picture: Decodable, Hashable, Sendable {
        public enum Setting: String, Decodable, Sendable {
            case garden, park, forest, shore, water, room, kitchen, town, rain, snow, night
        }

        public struct Figure: Decodable, Hashable, Sendable {
            public enum Position: String, Decodable, Sendable {
                case left, centre, right, frontLeft, front, frontRight, upperLeft, upper, upperRight
            }

            public let position: Position
            public let symbol: String
        }

        public enum Artwork: Hashable, Sendable {
            case illustration(String)
            case symbols(setting: Setting, figures: [Figure])
        }

        public let artwork: Artwork
        public let description: String
        public let text: String

        private enum CodingKeys: String, CodingKey {
            case image, setting, figures, description, text
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            description = try container.decode(String.self, forKey: .description)
            text = try container.decode(String.self, forKey: .text)
            if let image = try container.decodeIfPresent(String.self, forKey: .image) {
                artwork = .illustration(image)
            } else {
                artwork = .symbols(
                    setting: try container.decode(Setting.self, forKey: .setting),
                    figures: try container.decode([Figure].self, forKey: .figures)
                )
            }
        }
    }

    public let id: String
    public let title: String
    public let pictures: [Picture]
}

public enum ShowAndTellCatalog {
    public static func load() throws -> [ShowAndTellStory] {
        try load(resource: "show-and-tell-classics")
    }

    public static func loadOriginals() throws -> [ShowAndTellStory] {
        try load(resource: "show-and-tell")
    }

    private static func load(resource: String) throws -> [ShowAndTellStory] {
        guard let url = Bundle.module.url(forResource: resource, withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([ShowAndTellStory].self, from: Data(contentsOf: url))
    }
}
