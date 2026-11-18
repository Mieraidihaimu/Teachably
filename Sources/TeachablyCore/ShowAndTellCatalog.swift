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

        public let setting: Setting
        public let figures: [Figure]
        public let description: String
        public let text: String
    }

    public let id: String
    public let title: String
    public let pictures: [Picture]
}

public enum ShowAndTellCatalog {
    public static func load() throws -> [ShowAndTellStory] {
        guard let url = Bundle.module.url(forResource: "show-and-tell", withExtension: "json") else {
            throw CocoaError(.fileNoSuchFile)
        }
        return try JSONDecoder().decode([ShowAndTellStory].self, from: Data(contentsOf: url))
    }
}
