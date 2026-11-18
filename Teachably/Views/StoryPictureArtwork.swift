import SwiftUI
import TeachablyCore

struct StoryPictureArtwork: View {
    let picture: ShowAndTellStory.Picture

    var body: some View {
        Canvas { canvas, size in
            var context = canvas
            context.scaleBy(x: size.width / 160, y: size.height / 120)
            scenery(in: context)
            for figure in picture.figures {
                draw(figure, in: context)
            }
        }
        .aspectRatio(4.0 / 3, contentMode: .fit)
    }

    private func draw(_ figure: ShowAndTellStory.Picture.Figure, in context: GraphicsContext) {
        let (x, y, size) = placement(for: figure.position)
        if let shirt = shirtColour(for: figure.symbol) {
            drawPerson(figure.symbol, in: context, x: x, y: y, size: size, shirt: shirt)
        } else {
            if y >= 70 {
                oval(context, x - size * 0.39, y + size * 0.37, size * 0.78, 6, Palette.ink.opacity(0.13))
            }
            context.draw(Text(verbatim: figure.symbol).font(.system(size: size)), at: CGPoint(x: x, y: y))
        }
    }

    private func shirtColour(for symbol: String) -> Color? {
        switch symbol.unicodeScalars.first?.value {
        case 0x1F467: ink(0xBD5369) // girl
        case 0x1F466: ink(0x466FA2) // boy
        case 0x1F9D1: ink(0x2B7768) // adult
        case 0x1F475: ink(0x8862A0) // older woman
        default: nil
        }
    }

    private func drawPerson(_ face: String, in context: GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat, shirt: Color) {
        var person = context
        person.translateBy(x: x, y: y)
        person.scaleBy(x: size / 43, y: size / 43)

        oval(person, -15, 20, 30, 6, Palette.ink.opacity(0.16))
        let trousers = ink(0x374B64)
        oval(person, -9, 10, 8, 13, trousers)
        oval(person, 1, 10, 8, 13, trousers)
        oval(person, -11, 19, 10, 5, Palette.ink)
        oval(person, 1, 19, 10, 5, Palette.ink)
        oval(person, -14, 0, 8, 12, shirt)
        oval(person, 6, 0, 8, 12, shirt)
        let top = CGRect(x: -9.5, y: -3, width: 19, height: 18)
        person.fill(Path(roundedRect: top, cornerRadius: 6), with: .color(shirt))
        oval(person, -4, 6, 8, 4, .white.opacity(0.25))
        person.draw(Text(verbatim: face).font(.system(size: 35)), at: CGPoint(x: 0, y: -10))
    }

    private func placement(for position: ShowAndTellStory.Picture.Figure.Position) -> (CGFloat, CGFloat, CGFloat) {
        switch position {
        case .left: (37, 76, 43)
        case .centre: (80, 73, 46)
        case .right: (124, 76, 43)
        case .frontLeft: (37, 99, 27)
        case .front: (80, 100, 29)
        case .frontRight: (124, 99, 27)
        case .upperLeft: (36, 37, 29)
        case .upper: (80, 33, 32)
        case .upperRight: (124, 35, 29)
        }
    }

    private func scenery(in context: GraphicsContext) {
        let (top, horizon, floor) = colours
        context.fill(Path(CGRect(x: 0, y: 0, width: 160, height: 120)),
                     with: .linearGradient(Gradient(colors: [top, horizon]), startPoint: .zero,
                                           endPoint: CGPoint(x: 0, y: 90)))
        switch picture.setting {
        case .room, .kitchen:
            indoorScenery(in: context, floor: floor)
        case .shore, .water:
            waterScenery(in: context, floor: floor)
        default:
            outdoorScenery(in: context, floor: floor)
        }
    }

    private var colours: (Color, Color, Color) {
        switch picture.setting {
        case .garden: (ink(0x9BD9C7), ink(0xECF4CF), ink(0xA6C77C))
        case .park: (ink(0xA4D9F2), ink(0xE4F2CB), ink(0xAFCD83))
        case .forest: (ink(0x8BBEB0), ink(0xD9E9AB), ink(0xA9B56F))
        case .shore: (ink(0x8ED0EB), ink(0xECF8F6), ink(0xEBD092))
        case .water: (ink(0x89C9EE), ink(0xE4F5EA), ink(0x71B7CA))
        case .room: (ink(0xEDD2BD), ink(0xFFF0D5), ink(0xD7B192))
        case .kitchen: (ink(0xC8DAD2), ink(0xEAF2D8), ink(0xDFC18D))
        case .town: (ink(0xACCAE4), ink(0xF4E8D4), ink(0xC9BCAE))
        case .rain: (ink(0x8EA9C4), ink(0xDAE7E4), ink(0x93B79A))
        case .snow: (ink(0xABC6EA), ink(0xE7F4FB), ink(0xD7EAF6))
        case .night: (ink(0x354970), ink(0x8C81AB), ink(0x658776))
        }
    }

    private func indoorScenery(in context: GraphicsContext, floor: Color) {
        let isKitchen = picture.setting == .kitchen
        let accent = isKitchen ? ink(0x7FAF9C) : ink(0xDA9779)
        rect(context, 0, 80, 160, 40, floor)
        rect(context, 0, 77, 160, 5, .white.opacity(0.57))
        rect(context, 107, 12, 38, 40, .white.opacity(0.85))
        rect(context, 110, 15, 32, 34, ink(0xA4C9D0))
        oval(context, 112, 21, 14, 7, .white.opacity(0.65))
        rect(context, 125, 15, 2, 34, .white.opacity(0.76))
        rect(context, 110, 31, 32, 2, .white.opacity(0.76))
        if isKitchen {
            for row in 0..<3 {
                for column in 0..<5 {
                    rect(context, CGFloat(column) * 11 + 5, CGFloat(row) * 10 + 40, 10, 9, .white.opacity(0.33))
                }
            }
            rect(context, 0, 71, 59, 5, accent)
        } else {
            oval(context, 18, 93, 123, 27, accent.opacity(0.45))
            oval(context, 26, 97, 107, 19, .white.opacity(0.26))
        }
        for y in [88.0, 105.0, 117.0] {
            rect(context, 0, y, 160, 0.7, Palette.ink.opacity(0.10))
        }
    }

    private func waterScenery(in context: GraphicsContext, floor: Color) {
        cloud(context, x: 20, y: 25)
        oval(context, 117, 11, 17, 17, ink(0xFFD68D))
        rect(context, 0, 61, 160, 59, ink(0x86CBD7))
        if picture.setting == .shore {
            var sand = Path()
            sand.move(to: CGPoint(x: 0, y: 97))
            sand.addQuadCurve(to: CGPoint(x: 160, y: 83), control: CGPoint(x: 62, y: 73))
            sand.addLine(to: CGPoint(x: 160, y: 120))
            sand.addLine(to: CGPoint(x: 0, y: 120))
            sand.closeSubpath()
            context.fill(sand, with: .color(floor))
        }
        for point in [CGPoint(x: 12, y: 72), CGPoint(x: 58, y: 66), CGPoint(x: 110, y: 79),
                      CGPoint(x: 29, y: 92), CGPoint(x: 86, y: 103), CGPoint(x: 142, y: 69)] {
            oval(context, point.x, point.y, 13, 1.6, .white.opacity(0.55))
        }
    }

    private func outdoorScenery(in context: GraphicsContext, floor: Color) {
        let setting = picture.setting
        if setting == .night {
            oval(context, 121, 12, 18, 18, ink(0xFFE3A7))
            for point in [CGPoint(x: 21, y: 16), CGPoint(x: 47, y: 29), CGPoint(x: 74, y: 12),
                          CGPoint(x: 100, y: 30), CGPoint(x: 149, y: 41)] {
                oval(context, point.x, point.y, 2.5, 2.5, .white.opacity(0.88))
            }
        } else {
            cloud(context, x: 13, y: 24)
            if setting == .rain {
                cloud(context, x: 109, y: 28)
            } else {
                oval(context, 119, 12, 20, 20, ink(0xFFE3A7))
            }
        }
        oval(context, -53, 55, 177, 71, floor.opacity(0.67))
        oval(context, 65, 59, 145, 57, floor.opacity(0.73))
        oval(context, -33, 79, 227, 114, floor)
        switch setting {
        case .town:
            for (x, height) in [(0.0, 25.0), (17.0, 17.0), (131.0, 27.0), (145.0, 32.0)] {
                rect(context, x, 80 - height, 14, height, ink(0xB28579))
                rect(context, x + 3, 86 - height, 3, 5, ink(0xF8E2B5))
                rect(context, x + 8, 86 - height, 3, 5, ink(0xF8E2B5))
            }
        case .forest, .park, .garden:
            tree(context, x: 12, y: 59, size: 22)
            tree(context, x: 150, y: 62, size: setting == .forest ? 42 : 21)
            if setting == .forest { tree(context, x: 0, y: 54, size: 46) }
        case .rain:
            for index in 0..<15 {
                let x = CGFloat((index * 37 + 7) % 157)
                let y = CGFloat((index * 19) % 54 + 19)
                var drop = Path()
                drop.move(to: CGPoint(x: x, y: y))
                drop.addLine(to: CGPoint(x: x - 3, y: y + 7))
                context.stroke(drop, with: .color(.white.opacity(0.55)), lineWidth: 1.1)
            }
            oval(context, 7, 105, 29, 4, ink(0xBBD8E1))
            oval(context, 131, 94, 24, 4, ink(0xBBD8E1))
        default:
            break
        }
        for point in [CGPoint(x: 13, y: 101), CGPoint(x: 50, y: 111), CGPoint(x: 98, y: 95),
                      CGPoint(x: 137, y: 112), CGPoint(x: 72, y: 87)] {
            oval(context, point.x, point.y, 7, 1.3, .white.opacity(0.46))
        }
    }

    private func cloud(_ context: GraphicsContext, x: CGFloat, y: CGFloat) {
        let white = Color.white.opacity(0.58)
        oval(context, x, y + 4, 30, 8, white)
        oval(context, x + 5, y, 13, 9, white)
        oval(context, x + 16, y + 2, 9, 7, white)
    }

    private func tree(_ context: GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat) {
        rect(context, x - 2, y, 4, 19, ink(0xA18567))
        oval(context, x - size / 2, y - size * 0.7, size, size * 0.91, ink(0x6EAA7C))
        oval(context, x - size * 0.38, y - size * 0.62, size * 0.57, size * 0.55, ink(0x95BC83))
    }

    private func rect(_ context: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: Color) {
        context.fill(Path(CGRect(x: x, y: y, width: width, height: height)), with: .color(color))
    }

    private func oval(_ context: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat, _ color: Color) {
        context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: width, height: height)), with: .color(color))
    }

    private func ink(_ rgb: UInt32) -> Color {
        Color(red: Double((rgb >> 16) & 255) / 255, green: Double((rgb >> 8) & 255) / 255, blue: Double(rgb & 255) / 255)
    }
}
