import SwiftUI
import TeachablyCore

struct SessionView: View {
    let activity: Activity
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @State private var stepIndex = 0
    @State private var running = true
    @State private var deadline = Date.now
    @State private var pausedRemaining: TimeInterval = 0
    @State private var reflecting = false
    @State private var memoryNote = ""
    @State private var favourite = false

    private var step: ActivityStep { activity.steps[stepIndex] }
    private var isLast: Bool { stepIndex == activity.steps.count - 1 }

    var body: some View {
        NavigationStack {
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        if reflecting { reflectionContent }
                        else { sessionContent }
                    }
                    .padding(16)
                    .teachablyContainer(.reading)
                    .background(alignment: .top) { Color.clear.frame(height: 1).id("top") }
                }
                .onChange(of: stepIndex) { _, _ in reader.scrollTo("top", anchor: .top) }
                .onChange(of: reflecting) { _, _ in reader.scrollTo("top", anchor: .top) }
                .background(Palette.background)
                .teachablyBottomBar {
                    VStack(spacing: 4) {
                        if reflecting {
                            Button {
                                store.remember(activity: activity, note: memoryNote, favourite: favourite)
                                dismiss()
                            } label: { Text(L10n.string("Save our little memory")) }
                                .buttonStyle(PrimaryButtonStyle())
                        } else {
                            HStack(spacing: 10) {
                                if stepIndex > 0 {
                                    Button { stepIndex -= 1; resetTimer() } label: {
                                        Label(L10n.string("Back"), systemImage: "chevron.backward")
                                    }
                                    .buttonStyle(SecondaryButtonStyle(fullWidth: false))
                                }
                                Button {
                                    if isLast { finish() }
                                    else { stepIndex += 1; resetTimer() }
                                } label: {
                                    HStack {
                                        Text(isLast ? L10n.string("Keep a little memory") : L10n.string("Next little step"))
                                        Image(systemName: "arrow.right")
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            Button(L10n.string("Finish for today")) { finish() }
                                .buttonStyle(QuietButtonStyle(foreground: Palette.muted))
                        }
                    }
                }
            }
            .foregroundStyle(Palette.ink)
            .navigationTitle(reflecting ? L10n.string("A moment to keep") : L10n.string("Together time"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(L10n.string("Close session"))
                }
            }
        }
        .onAppear { resetTimer() }
    }

    private var sessionContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                ForEach(activity.steps.indices, id: \.self) { index in
                    Capsule().fill(index <= stepIndex ? Palette.green : Palette.line).frame(height: 5)
                }
            }.accessibilityLabel(L10n.format("Step %lld of %lld", stepIndex + 1, activity.steps.count))
            Eyebrow(text: L10n.format("%@ · Step %lld of %lld", activity.title, stepIndex + 1, activity.steps.count))
            Text(step.title).font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
            Text(step.instruction).font(.title3).lineSpacing(5)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = max(0, Int(ceil(running ? deadline.timeIntervalSince(context.date) : pausedRemaining)))
                        Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                            .font(.system(.largeTitle, design: .rounded, weight: .medium)).monospacedDigit()
                            .accessibilityLabel(L10n.format("%lld minutes, %lld seconds remaining", remaining / 60, remaining % 60))
                    }
                    Text(L10n.string("A gentle guide. Go at your own pace.")).font(.caption).foregroundStyle(Palette.muted)
                }
                Spacer()
                Button {
                    if running {
                        pausedRemaining = max(0, deadline.timeIntervalSinceNow)
                        running = false
                    } else {
                        deadline = .now.addingTimeInterval(pausedRemaining)
                        running = true
                    }
                } label: {
                    Image(systemName: running ? "pause.fill" : "play.fill")
                        .foregroundStyle(Palette.green)
                        .frame(width: 44, height: 44)
                        .background(Palette.surfaceCard, in: Circle())
                        .overlay(Circle().strokeBorder(Palette.line, lineWidth: 1))
                }
                .contentShape(Circle())
                .accessibilityLabel(running ? L10n.string("Pause timer") : L10n.string("Resume timer"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Palette.sage.opacity(0.55), in: RoundedRectangle(cornerRadius: Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(Palette.sage, lineWidth: 1)
            )
            ActivityFamilyPrompts(activity: activity, compact: true)
            if let note = store.state.teachingNotes[activity.id], !note.isEmpty {
                PaperCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Eyebrow(text: L10n.string("Your own experience"))
                        Text(note).font(.body)
                    }
                }
            } else {
                Text(activity.personalPrompt).font(.system(.body, design: .serif).italic())
                    .foregroundStyle(Palette.green)
            }
        }
    }

    private var reflectionContent: some View {
        VStack(alignment: .leading, spacing: 22) {
            Image(systemName: "heart.circle.fill").font(.system(size: 62)).foregroundStyle(Palette.green)
            Eyebrow(text: L10n.string("It all counts"))
            Text(L10n.string("A little time,\na lovely memory."))
                .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
            Text(L10n.format("%@ — what made you smile, surprised you, or would you like to try again?", activity.title))
                .foregroundStyle(Palette.muted)
            TextField(L10n.string("Something they said. A tiny discovery…"), text: $memoryNote, axis: .vertical)
                .lineLimit(5...10)
                .padding(16)
                .teachablyCardSurface(cornerRadius: Radius.lg)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .strokeBorder(Palette.lineStrong, lineWidth: 1)
                )
                .accessibilityLabel(L10n.string("Memory note"))
            Toggle(isOn: $favourite) {
                Label(L10n.string("We'd love to do this again"), systemImage: "heart")
                    .font(.subheadline)
            }.tint(Palette.green)
            Text(L10n.string("A note is optional. Spending a little time together is enough."))
                .font(.caption).foregroundStyle(Palette.muted)
        }
    }

    private func resetTimer() {
        pausedRemaining = TimeInterval(step.minutes * 60)
        deadline = .now.addingTimeInterval(pausedRemaining)
        running = true
    }

    private func finish() {
        pausedRemaining = max(0, deadline.timeIntervalSinceNow)
        running = false
        reflecting = true
    }
}
