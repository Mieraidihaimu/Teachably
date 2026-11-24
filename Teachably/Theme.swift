import SwiftUI
import TeachablyCore

enum Palette {
    static let background = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let surfaceCard = Color.white
    static let surfacePaper = Color(red: 0.988, green: 0.984, blue: 0.969)
    static let ink = Color(red: 0.16, green: 0.24, blue: 0.20)
    static let muted = Color(red: 0.31, green: 0.37, blue: 0.33)
    static let mutedSubtle = Color(red: 0.42, green: 0.47, blue: 0.44)
    static let green = Color(red: 0.20, green: 0.37, blue: 0.29)
    static let greenPressed = Color(red: 0.15, green: 0.28, blue: 0.22)
    static let greenTintedSurface = Color(red: 0.89, green: 0.93, blue: 0.90)
    static let sage = Color(red: 0.86, green: 0.90, blue: 0.80)
    static let peach = Color(red: 0.97, green: 0.85, blue: 0.76)
    static let terracotta = Color(red: 0.54, green: 0.27, blue: 0.13)
    static let gold = Color(red: 0.94, green: 0.75, blue: 0.39)
    static let starActive = Color(red: 0.60, green: 0.36, blue: 0.07)
    static let recording = Color(red: 0.72, green: 0.23, blue: 0.18)
    static let line = Color(red: 0.85, green: 0.86, blue: 0.82)
    static let lineStrong = Color(red: 0.77, green: 0.79, blue: 0.73)
    static let disabledFill = line

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

enum Radius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
}

enum LayoutWidth {
    case focused
    case reading
    case browse

    var maxWidth: CGFloat {
        switch self {
        case .focused: 480
        case .reading: 640
        case .browse: 880
        }
    }
}

extension View {
    /// Centers content within a standardized Teachably width tier.
    func teachablyContainer(_ width: LayoutWidth) -> some View {
        frame(maxWidth: width.maxWidth)
            .frame(maxWidth: .infinity)
    }

    /// Styles an interactive or hero card with subtle border and warm ambient shadow.
    func teachablyCardSurface(cornerRadius: CGFloat = Radius.lg) -> some View {
        background(Palette.surfaceCard, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Palette.line, lineWidth: 1)
            )
            .shadow(color: Palette.ink.opacity(0.06), radius: 10, y: 4)
    }

    /// Styles a supporting paper block with solid cream-white fill and crisp border.
    func teachablyPaperSurface(cornerRadius: CGFloat = Radius.lg) -> some View {
        background(Palette.surfacePaper, in: RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Palette.line, lineWidth: 1)
            )
    }

    /// Pins a bottom action bar with consistent padding, focused container width, and top divider.
    func teachablyBottomBar<Bar: View>(
        width: LayoutWidth = .focused,
        @ViewBuilder content: () -> Bar
    ) -> some View {
        safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Palette.line)
                    .frame(height: 1)
                content()
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .teachablyContainer(width)
            }
            .background(Palette.background)
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 50)
            .foregroundStyle(isEnabled ? .white : Palette.mutedSubtle)
            .background(
                isEnabled
                    ? (configuration.isPressed ? Palette.greenPressed : Palette.green)
                    : Palette.disabledFill,
                in: RoundedRectangle(cornerRadius: Radius.md)
            )
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    var tint: Color = Palette.green
    var backgroundColor: Color = Palette.greenTintedSurface
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .frame(maxWidth: fullWidth ? .infinity : nil, minHeight: 44)
            .foregroundStyle(isEnabled ? tint : Palette.mutedSubtle)
            .background(
                isEnabled
                    ? (configuration.isPressed ? backgroundColor.opacity(0.75) : backgroundColor)
                    : Palette.disabledFill.opacity(0.6),
                in: RoundedRectangle(cornerRadius: Radius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(isEnabled ? Palette.line : Palette.line.opacity(0.6), lineWidth: 1)
            )
    }
}

struct QuietButtonStyle: ButtonStyle {
    var foreground: Color = Palette.green
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .foregroundStyle(isEnabled ? foreground : Palette.mutedSubtle)
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.65 : 1)
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
        content.padding(18).frame(maxWidth: .infinity, alignment: .leading)
            .teachablyPaperSurface(cornerRadius: Radius.lg)
    }
}

struct ActivityArtwork: View {
    let activity: Activity
    let height: CGFloat
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Palette.tint(for: activity.skill)
                Circle().fill(.white.opacity(0.30)).frame(width: 176, height: 176)
                    .offset(x: -proxy.size.width * 0.25, y: 58)
                Circle().fill(Palette.gold).frame(width: 64, height: 64)
                    .offset(x: proxy.size.width * 0.31, y: -49)
                RoundedRectangle(cornerRadius: Radius.xl)
                    .fill(.white.opacity(0.65)).frame(width: 108, height: 124)
                    .rotationEffect(.degrees(-12)).offset(x: -35, y: 1)
                RoundedRectangle(cornerRadius: Radius.xl)
                    .fill(Palette.green).frame(width: 108, height: 124)
                    .rotationEffect(.degrees(10)).offset(x: 30, y: 8)
                Image(systemName: activity.symbol)
                    .font(.system(size: 57, weight: .light)).foregroundStyle(.white)
                    .rotationEffect(.degrees(10)).offset(x: 30, y: 8)
                Image(systemName: "sparkle").font(.system(size: 29)).foregroundStyle(Palette.green)
                    .offset(x: -91, y: -51)
                Image(systemName: "sparkle").font(.system(size: 16)).foregroundStyle(Palette.green)
                    .offset(x: 111, y: 50)
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
    let stage: ChildStage
    let prompt: AgePrompt
    var compact: Bool = false

    private var isToddler: Bool { stage.band == .toddler }
    private var headerColor: Color { isToddler ? Palette.green : Palette.terracotta }
    private var fillColor: Color { (isToddler ? Palette.sage : Palette.peach).opacity(0.55) }
    private var borderColor: Color { isToddler ? Palette.sage : Palette.peach }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 10) {
            HStack {
                Image(systemName: isToddler ? "hand.wave" : "lightbulb")
                Text(name).fontWeight(.semibold)
                Spacer()
                Text(stage.label).font(.caption2.bold()).tracking(1)
            }
            .foregroundStyle(headerColor)
            Text(prompt.action).font(.subheadline).foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("“\(prompt.question)”").font(.system(.body, design: .serif).italic())
                .foregroundStyle(headerColor)
        }
        .padding(compact ? 14 : 16).frame(maxWidth: .infinity, alignment: .leading)
        .background(fillColor, in: RoundedRectangle(cornerRadius: Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }
}

struct ActivityFamilyPrompts: View {
    let activity: Activity
    var compact: Bool = false
    @EnvironmentObject private var store: FamilyStore

    var body: some View {
        let stages = store.stages
        AgeCard(name: store.profile.youngerDisplayName, stage: stages.younger,
                prompt: activity.prompt(for: stages.younger.band), compact: compact)
        AgeCard(name: store.profile.olderDisplayName, stage: stages.older,
                prompt: activity.prompt(for: stages.older.band), compact: compact)
        PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                Label(L10n.string("Big brother’s turn"), systemImage: "person.2")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Palette.green)
                Text(activity.siblingPrompt(for: store.profile))
                    .font(.subheadline).foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityIdentifier("activity.sibling-role")
    }
}
