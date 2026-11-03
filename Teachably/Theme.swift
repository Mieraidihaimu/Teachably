import SwiftUI
import TeachablyCore

enum Palette {
    static let background = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let ink = Color(red: 0.16, green: 0.24, blue: 0.20)
    static let muted = Color(red: 0.40, green: 0.45, blue: 0.41)
    static let green = Color(red: 0.20, green: 0.37, blue: 0.29)
    static let sage = Color(red: 0.86, green: 0.90, blue: 0.80)
    static let peach = Color(red: 0.97, green: 0.85, blue: 0.76)
    static let gold = Color(red: 0.94, green: 0.75, blue: 0.39)
    static let line = Color(red: 0.87, green: 0.88, blue: 0.83)

    static func tint(for skill: Skill) -> Color {
        switch skill {
        case .nature, .making: sage
        case .cooking, .storytelling, .journaling: peach
        case .music, .movement: Color(red: 0.88, green: 0.86, blue: 0.95)
        case .science, .numbers, .coding: Color(red: 0.84, green: 0.90, blue: 0.93)
        case .reading, .criticalThinking: Color(red: 0.94, green: 0.90, blue: 0.75)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(.white)
            .background(Palette.green, in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased()).font(.system(.caption2, design: .rounded, weight: .bold))
            .tracking(1.8).foregroundStyle(Palette.muted)
    }
}

struct SectionTitle: View {
    let title: String
    var body: some View {
        Text(title).font(.system(.title2, design: .serif, weight: .semibold))
            .foregroundStyle(Palette.ink)
    }
}

struct PaperCard<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        content.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 24))
    }
}

struct ActivityArtwork: View {
    let activity: Activity
    var height: CGFloat = 190
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Palette.tint(for: activity.skill)
                Circle().fill(.white.opacity(0.30)).frame(width: 176, height: 176)
                    .offset(x: -proxy.size.width * 0.25, y: 58)
                Circle().fill(Palette.gold).frame(width: 64, height: 64)
                    .offset(x: proxy.size.width * 0.31, y: -49)
                RoundedRectangle(cornerRadius: 26)
                    .fill(.white.opacity(0.65)).frame(width: 108, height: 124)
                    .rotationEffect(.degrees(-12)).offset(x: -35, y: 1)
                RoundedRectangle(cornerRadius: 26)
                    .fill(Palette.green).frame(width: 108, height: 124)
                    .rotationEffect(.degrees(10)).offset(x: 30, y: 8)
                Image(systemName: activity.symbol)
                    .font(.system(size: 57, weight: .light)).foregroundStyle(.white)
                    .rotationEffect(.degrees(10)).offset(x: 30, y: 8)
                Image(systemName: "sparkle").font(.system(size: 29)).foregroundStyle(Palette.green)
                    .offset(x: -91, y: -51)
                Image(systemName: "sparkle").font(.system(size: 16)).foregroundStyle(Palette.green)
                    .offset(x: 111, y: 50)
                Text(L10n.string("a little wonder")).font(.system(.caption, design: .serif).italic())
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundStyle(Palette.green).rotationEffect(.degrees(-8)).offset(x: -77, y: 64)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
}

struct AgeCard: View {
    let name: String
    let age: Int
    let prompt: AgePrompt
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: age == 2 ? "hand.wave" : "lightbulb")
                Text(name).fontWeight(.semibold)
                Spacer()
                Text(L10n.format("AGE %lld", age)).font(.caption2.bold()).tracking(1)
            }
            .foregroundStyle(Palette.green)
            Text(prompt.action).font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Text("“\(prompt.question)”").font(.system(.body, design: .serif).italic())
                .foregroundStyle(Palette.green)
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(age == 2 ? Palette.sage.opacity(0.5) : Palette.peach.opacity(0.6),
                    in: RoundedRectangle(cornerRadius: 20))
    }
}
