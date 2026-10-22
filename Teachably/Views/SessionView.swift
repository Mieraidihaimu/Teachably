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
                    VStack(alignment: .leading, spacing: 25) {
                        Color.clear.frame(height: 1).id("top")
                        if reflecting { reflectionContent }
                        else { sessionContent }
                    }.padding(24)
                }
                .onChange(of: stepIndex) { _, _ in reader.scrollTo("top", anchor: .top) }
                .onChange(of: reflecting) { _, _ in reader.scrollTo("top", anchor: .top) }
                .background(Palette.background)
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 6) {
                        if reflecting {
                            Button {
                                store.remember(activity: activity, note: memoryNote, favourite: favourite)
                                dismiss()
                            } label: { Text("Save our little memory") }
                                .buttonStyle(PrimaryButtonStyle())
                        } else {
                            Button {
                                if isLast { finish() }
                                else { stepIndex += 1; resetTimer() }
                            } label: {
                                HStack {
                                    Text(isLast ? "Keep a little memory" : "Next little step")
                                    Image(systemName: "arrow.right")
                                }
                            }.buttonStyle(PrimaryButtonStyle())
                            Button("Finish for today") { finish() }
                                .font(.subheadline).frame(minHeight: 38)
                        }
                    }.padding(.horizontal, 24).padding(.vertical, 12).background(Palette.background)
                }
            }
            .foregroundStyle(Palette.ink)
            .navigationTitle(reflecting ? "A moment to keep" : "Together time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                        .accessibilityLabel("Close session")
                }
                if stepIndex > 0 && !reflecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { stepIndex -= 1; resetTimer() }
                    }
                }
            }
        }
        .onAppear { resetTimer() }
    }

    private var sessionContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 6) {
                ForEach(activity.steps.indices, id: \.self) { index in
                    Capsule().fill(index <= stepIndex ? Palette.green : Palette.line).frame(height: 5)
                }
            }.accessibilityLabel("Step \(stepIndex + 1) of \(activity.steps.count)")
            Eyebrow(text: "\(activity.title) · Step \(stepIndex + 1) of \(activity.steps.count)")
            Text(step.title).font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
            Text(step.instruction).font(.title3).lineSpacing(5)
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        let remaining = max(0, Int(ceil(running ? deadline.timeIntervalSince(context.date) : pausedRemaining)))
                        Text(String(format: "%02d:%02d", remaining / 60, remaining % 60))
                            .font(.system(.largeTitle, design: .rounded, weight: .medium)).monospacedDigit()
                            .accessibilityLabel("\(remaining / 60) minutes, \(remaining % 60) seconds remaining")
                    }
                    Text("A gentle guide. Go at your own pace.").font(.caption).foregroundStyle(Palette.muted)
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
                        .frame(width: 48, height: 48).background(.white, in: Circle())
                }.accessibilityLabel(running ? "Pause timer" : "Resume timer")
            }
            .padding(18).background(Palette.sage.opacity(0.5), in: RoundedRectangle(cornerRadius: 22))
            AgeCard(name: store.profile.youngerName, age: 2, prompt: activity.toddler)
            AgeCard(name: store.profile.olderName, age: 6, prompt: activity.older)
            if let note = store.state.teachingNotes[activity.id], !note.isEmpty {
                PaperCard {
                    VStack(alignment: .leading, spacing: 9) {
                        Eyebrow(text: "Your own experience")
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
            Eyebrow(text: "It all counts")
            Text("A little time,\na lovely memory.")
                .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
            Text("\(activity.title) — what made you smile, surprised you, or would you like to try again?")
                .foregroundStyle(Palette.muted)
            TextField("Something they said. A tiny discovery…", text: $memoryNote, axis: .vertical)
                .lineLimit(5...10).padding(18).background(.white, in: RoundedRectangle(cornerRadius: 20))
                .accessibilityLabel("Memory note")
            Toggle(isOn: $favourite) {
                Label("We'd love to do this again", systemImage: "heart")
                    .font(.subheadline)
            }.tint(Palette.green)
            Text("A note is optional. Spending a little time together is enough.")
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
