import SwiftUI
import TeachablyCore

enum DrawingCategory: String, CaseIterable {
    case animals = "Animals"
    case things = "Things"
    case toys = "Toys"

    var title: String { L10n.string(rawValue) }
}

struct Drawing: Identifiable {
    let id: String
    let titleKey: String
    let category: DrawingCategory
    let tileAspectRatio: CGFloat

    var title: String { L10n.string(titleKey) }
    var image: Image { Image("Drawing-\(id)") }

    func matches(_ words: [Substring], locale: Locale) -> Bool {
        let names = locale.language.languageCode == .english ? [title, id.replacingOccurrences(of: "-", with: " ")] : [title]
        let text = (names + [category.title]).joined(separator: " ")
        return words.allSatisfy { word in
            text.range(of: word, options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive],
                       locale: locale) != nil
        }
    }
}

enum DrawingLevel: Int, CaseIterable, Identifiable {
    case one = 1, two, three, four, five

    var id: Int { rawValue }
    var title: String { L10n.format("Level %lld", rawValue) }
}

enum DrawingCatalog {
    static let drawings: [DrawingLevel: [Drawing]] = [
        .one: [
            Drawing(id: "rubber-ball", titleKey: "Rubber ball", category: .toys, tileAspectRatio: 0.90),
            Drawing(id: "apple", titleKey: "Apple", category: .things, tileAspectRatio: 1.03),
            Drawing(id: "fish", titleKey: "Little fish", category: .animals, tileAspectRatio: 1.22),
            Drawing(id: "strawberry", titleKey: "Strawberry", category: .things, tileAspectRatio: 0.93),
            Drawing(id: "kite", titleKey: "Diamond kite", category: .toys, tileAspectRatio: 0.87),
            Drawing(id: "cat", titleKey: "Smiling cat", category: .animals, tileAspectRatio: 0.93),
            Drawing(id: "leaf", titleKey: "Leaf", category: .things, tileAspectRatio: 0.89),
            Drawing(id: "balloon", titleKey: "Balloon", category: .toys, tileAspectRatio: 0.86),
            Drawing(id: "cloud", titleKey: "Cloud", category: .things, tileAspectRatio: 1.22),
            Drawing(id: "ladybug", titleKey: "Ladybird", category: .animals, tileAspectRatio: 1.05),
            Drawing(id: "pear", titleKey: "Pear", category: .things, tileAspectRatio: 0.87),
            Drawing(id: "crescent-moon", titleKey: "Crescent moon", category: .things, tileAspectRatio: 1.11),
            Drawing(id: "spinning-top", titleKey: "Spinning top", category: .toys, tileAspectRatio: 1.04),
            Drawing(id: "seashell", titleKey: "Seashell", category: .things, tileAspectRatio: 1.15),
            Drawing(id: "cupcake", titleKey: "Cupcake", category: .things, tileAspectRatio: 0.88),
            Drawing(id: "earthworm", titleKey: "Earthworm", category: .animals, tileAspectRatio: 1.23),
            Drawing(id: "house", titleKey: "Little house", category: .things, tileAspectRatio: 1.00),
            Drawing(id: "mitten", titleKey: "Mitten", category: .things, tileAspectRatio: 0.87),
            Drawing(id: "toy-sailboat", titleKey: "Toy sailboat", category: .toys, tileAspectRatio: 1.07),
            Drawing(id: "daisy", titleKey: "Daisy", category: .things, tileAspectRatio: 0.88),
            Drawing(id: "ice-pop", titleKey: "Ice lolly", category: .things, tileAspectRatio: 0.85),
            Drawing(id: "jellyfish", titleKey: "Jellyfish", category: .animals, tileAspectRatio: 1.00),
            Drawing(id: "yo-yo", titleKey: "Yo-yo", category: .toys, tileAspectRatio: 1.14)
        ],
        .two: [
            Drawing(id: "duck", titleKey: "Duck", category: .animals, tileAspectRatio: 1.16),
            Drawing(id: "snail", titleKey: "Snail", category: .animals, tileAspectRatio: 1.13),
            Drawing(id: "ice-cream-cone", titleKey: "Ice cream cone", category: .things, tileAspectRatio: 0.86),
            Drawing(id: "rocket", titleKey: "Toy rocket", category: .toys, tileAspectRatio: 1.14),
            Drawing(id: "turtle", titleKey: "Little turtle", category: .animals, tileAspectRatio: 1.22),
            Drawing(id: "mushroom", titleKey: "Spotted mushroom", category: .things, tileAspectRatio: 1.18),
            Drawing(id: "whale", titleKey: "Blue whale", category: .animals, tileAspectRatio: 1.22),
            Drawing(id: "boot", titleKey: "Rain boot", category: .things, tileAspectRatio: 0.86),
            Drawing(id: "blocks", titleKey: "Wooden blocks", category: .toys, tileAspectRatio: 1.12),
            Drawing(id: "toy-car", titleKey: "Toy car", category: .toys, tileAspectRatio: 1.18),
            Drawing(id: "potted-cactus", titleKey: "Potted cactus", category: .things, tileAspectRatio: 0.87),
            Drawing(id: "owl", titleKey: "Owl", category: .animals, tileAspectRatio: 0.88),
            Drawing(id: "butterfly", titleKey: "Butterfly", category: .animals, tileAspectRatio: 1.19),
            Drawing(id: "watering-can", titleKey: "Watering can", category: .things, tileAspectRatio: 1.17),
            Drawing(id: "rubber-duck", titleKey: "Rubber duck", category: .toys, tileAspectRatio: 1.02),
            Drawing(id: "bumblebee", titleKey: "Bumblebee", category: .animals, tileAspectRatio: 1.20),
            Drawing(id: "teacup", titleKey: "Teacup", category: .things, tileAspectRatio: 1.17),
            Drawing(id: "chick", titleKey: "Baby chick", category: .animals, tileAspectRatio: 0.90),
            Drawing(id: "rainbow", titleKey: "Rainbow", category: .things, tileAspectRatio: 1.22),
            Drawing(id: "sand-bucket", titleKey: "Sand bucket and spade", category: .toys, tileAspectRatio: 1.04),
            Drawing(id: "watermelon-slice", titleKey: "Watermelon slice", category: .things, tileAspectRatio: 1.20),
            Drawing(id: "frog", titleKey: "Frog", category: .animals, tileAspectRatio: 1.12),
            Drawing(id: "koala", titleKey: "Koala", category: .animals, tileAspectRatio: 0.89),
            Drawing(id: "paper-plane", titleKey: "Paper aeroplane", category: .toys, tileAspectRatio: 1.19),
            Drawing(id: "tulip", titleKey: "Tulip", category: .things, tileAspectRatio: 0.86),
            Drawing(id: "pumpkin", titleKey: "Pumpkin", category: .things, tileAspectRatio: 1.17)
        ],
        .three: [
            Drawing(id: "rabbit", titleKey: "Rabbit", category: .animals, tileAspectRatio: 0.86),
            Drawing(id: "toy-robot", titleKey: "Toy robot", category: .toys, tileAspectRatio: 0.89),
            Drawing(id: "umbrella", titleKey: "Umbrella", category: .things, tileAspectRatio: 1.02),
            Drawing(id: "fox", titleKey: "Sleepy fox", category: .animals, tileAspectRatio: 0.86),
            Drawing(id: "teddy", titleKey: "Teddy bear", category: .toys, tileAspectRatio: 0.86),
            Drawing(id: "train", titleKey: "Toy train", category: .toys, tileAspectRatio: 1.18),
            Drawing(id: "penguin", titleKey: "Penguin", category: .animals, tileAspectRatio: 0.86),
            Drawing(id: "toy-xylophone", titleKey: "Toy xylophone", category: .toys, tileAspectRatio: 1.20),
            Drawing(id: "bicycle", titleKey: "Bicycle", category: .things, tileAspectRatio: 1.19),
            Drawing(id: "squirrel", titleKey: "Squirrel", category: .animals, tileAspectRatio: 0.94),
            Drawing(id: "backpack", titleKey: "School backpack", category: .things, tileAspectRatio: 0.87),
            Drawing(id: "pinwheel", titleKey: "Pinwheel", category: .toys, tileAspectRatio: 0.91),
            Drawing(id: "octopus", titleKey: "Octopus", category: .animals, tileAspectRatio: 1.19),
            Drawing(id: "skateboard", titleKey: "Skateboard", category: .toys, tileAspectRatio: 1.20),
            Drawing(id: "elephant", titleKey: "Elephant", category: .animals, tileAspectRatio: 1.15),
            Drawing(id: "teapot", titleKey: "Teapot", category: .things, tileAspectRatio: 1.17),
            Drawing(id: "toy-dinosaur", titleKey: "Toy dinosaur", category: .toys, tileAspectRatio: 1.07),
            Drawing(id: "sunflower", titleKey: "Sunflower", category: .things, tileAspectRatio: 0.89),
            Drawing(id: "seal", titleKey: "Seal", category: .animals, tileAspectRatio: 1.15),
            Drawing(id: "rag-doll", titleKey: "Rag doll", category: .toys, tileAspectRatio: 0.88),
            Drawing(id: "pineapple", titleKey: "Pineapple", category: .things, tileAspectRatio: 0.86),
            Drawing(id: "rooster", titleKey: "Rooster", category: .animals, tileAspectRatio: 1.00),
            Drawing(id: "toy-helicopter", titleKey: "Toy helicopter", category: .toys, tileAspectRatio: 1.21)
        ],
        .four: [
            Drawing(id: "hedgehog", titleKey: "Hedgehog", category: .animals, tileAspectRatio: 1.18),
            Drawing(id: "rocking-horse", titleKey: "Rocking horse", category: .toys, tileAspectRatio: 1.08),
            Drawing(id: "mushroom-cottage", titleKey: "Mushroom cottage", category: .things, tileAspectRatio: 0.90),
            Drawing(id: "raccoon", titleKey: "Raccoon", category: .animals, tileAspectRatio: 1.05),
            Drawing(id: "toy-fire-engine", titleKey: "Toy fire engine", category: .toys, tileAspectRatio: 1.20),
            Drawing(id: "alpaca", titleKey: "Alpaca", category: .animals, tileAspectRatio: 0.86),
            Drawing(id: "chess-knight", titleKey: "Chess knight", category: .toys, tileAspectRatio: 0.89),
            Drawing(id: "camping-lantern", titleKey: "Camping lantern", category: .things, tileAspectRatio: 0.90),
            Drawing(id: "flamingo", titleKey: "Flamingo", category: .animals, tileAspectRatio: 0.86),
            Drawing(id: "toy-excavator", titleKey: "Toy excavator", category: .toys, tileAspectRatio: 1.20),
            Drawing(id: "tiger-cub", titleKey: "Tiger cub", category: .animals, tileAspectRatio: 1.02),
            Drawing(id: "jack-in-the-box", titleKey: "Jack-in-the-box", category: .toys, tileAspectRatio: 0.89),
            Drawing(id: "instant-camera", titleKey: "Instant camera", category: .things, tileAspectRatio: 1.18),
            Drawing(id: "seahorse", titleKey: "Seahorse", category: .animals, tileAspectRatio: 0.85),
            Drawing(id: "wind-up-mouse", titleKey: "Wind-up mouse", category: .toys, tileAspectRatio: 1.17),
            Drawing(id: "red-panda", titleKey: "Red panda", category: .animals, tileAspectRatio: 1.15),
            Drawing(id: "block-castle", titleKey: "Building-block castle", category: .toys, tileAspectRatio: 1.02),
            Drawing(id: "snow-globe", titleKey: "Snow globe", category: .things, tileAspectRatio: 0.91),
            Drawing(id: "ring-tailed-lemur", titleKey: "Ring-tailed lemur", category: .animals, tileAspectRatio: 1.00),
            Drawing(id: "pinball-machine", titleKey: "Pinball machine", category: .toys, tileAspectRatio: 0.88)
        ],
        .five: [
            Drawing(id: "chameleon", titleKey: "Chameleon on a branch", category: .animals, tileAspectRatio: 1.16),
            Drawing(id: "mini-carousel", titleKey: "Miniature carousel", category: .toys, tileAspectRatio: 1.02),
            Drawing(id: "bakery-shop", titleKey: "Bakery storefront", category: .things, tileAspectRatio: 1.14),
            Drawing(id: "peacock", titleKey: "Peacock", category: .animals, tileAspectRatio: 1.19),
            Drawing(id: "model-submarine", titleKey: "Model submarine", category: .toys, tileAspectRatio: 1.18),
            Drawing(id: "praying-mantis", titleKey: "Praying mantis", category: .animals, tileAspectRatio: 0.89),
            Drawing(id: "marble-run", titleKey: "Marble run", category: .toys, tileAspectRatio: 0.91),
            Drawing(id: "terrarium", titleKey: "Hanging terrarium", category: .things, tileAspectRatio: 0.93),
            Drawing(id: "barn-owl", titleKey: "Barn owl in flight", category: .animals, tileAspectRatio: 1.16),
            Drawing(id: "model-biplane", titleKey: "Model biplane", category: .toys, tileAspectRatio: 1.18),
            Drawing(id: "giraffe", titleKey: "Giraffe", category: .animals, tileAspectRatio: 0.86),
            Drawing(id: "toy-drum-kit", titleKey: "Toy drum kit", category: .toys, tileAspectRatio: 1.12),
            Drawing(id: "cuckoo-clock", titleKey: "Cuckoo clock", category: .things, tileAspectRatio: 0.86),
            Drawing(id: "hummingbird", titleKey: "Hummingbird and flower", category: .animals, tileAspectRatio: 1.11),
            Drawing(id: "model-pirate-ship", titleKey: "Model pirate ship", category: .toys, tileAspectRatio: 1.09),
            Drawing(id: "zebra", titleKey: "Zebra", category: .animals, tileAspectRatio: 1.17),
            Drawing(id: "dollhouse", titleKey: "Dollhouse", category: .toys, tileAspectRatio: 1.12),
            Drawing(id: "telescope", titleKey: "Telescope", category: .things, tileAspectRatio: 0.88),
            Drawing(id: "hermit-crab", titleKey: "Hermit crab", category: .animals, tileAspectRatio: 1.16),
            Drawing(id: "space-station", titleKey: "Toy space station", category: .toys, tileAspectRatio: 1.22)
        ],
    ]
}
