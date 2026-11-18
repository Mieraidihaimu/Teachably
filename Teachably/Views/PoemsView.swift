import AVFoundation
import SwiftUI
import TeachablyCore

struct PoemsView: View {
    @State private var query = ""
    @FocusState private var searchFocused: Bool
    private let poems = (try? PoemCatalog.load()) ?? []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                if poems.isEmpty {
                    ContentUnavailableView(L10n.string("Poems are unavailable"), systemImage: "book.closed")
                } else {
                    searchField
                    if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(L10n.format("%lld poems in English", poems.count))
                            .font(.system(.title2, design: .serif, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, 6)
                        ForEach(PoemLevel.allCases) { level in
                            levelLink(level)
                        }
                    } else {
                        let results = PoemCatalog.search(query, in: poems)
                        if results.isEmpty {
                            ContentUnavailableView.search(text: query)
                        } else {
                            ForEach(results) { PoemLink(poem: $0, showsLevel: true) }
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Palette.background)
        .navigationTitle(L10n.string("Poems"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.green)
                .accessibilityHidden(true)
            TextField(L10n.string("Search poems"), text: $query)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .focused($searchFocused)
                .onSubmit { searchFocused = false }
                .accessibilityIdentifier("poems.search")
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.muted)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.string("Clear search"))
            }
        }
        .padding(.leading, 14)
        .padding(.trailing, 4)
        .frame(minHeight: 48)
        .background(.white, in: .rect(cornerRadius: 16))
    }

    private func levelLink(_ level: PoemLevel) -> some View {
        NavigationLink {
            PoemLevelView(level: level, poems: poems.filter { $0.level == level })
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.title)
                        .font(.system(.title3, design: .serif, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text(level.description)
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.green)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .background(.white, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("poems.level.\(level.id)")
    }
}

private struct PoemLevelView: View {
    let level: PoemLevel
    let poems: [Poem]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(poems) { PoemLink(poem: $0, showsLevel: false) }
            }
            .padding(20)
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background)
        .navigationTitle(level.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PoemLink: View {
    let poem: Poem
    let showsLevel: Bool

    var body: some View {
        NavigationLink {
            PoemReader(poem: poem)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: poem.title)
                        .font(.system(.headline, design: .serif, weight: .semibold))
                        .foregroundStyle(Palette.ink)
                    Text(verbatim: poem.source.author)
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                    if showsLevel {
                        Text(poem.level.title)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Palette.green)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.green)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(.white, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("poem.\(poem.id)")
    }
}

private struct PoemReader: View {
    let poem: Poem
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var narration = PoemNarration()

    var body: some View {
        ScrollView {
            PaperCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(verbatim: poem.title)
                        .font(.system(.largeTitle, design: .serif, weight: .medium))
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: poem.source.author)
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                    Text(verbatim: poem.text)
                        .font(.system(.title2, design: .serif))
                        .lineSpacing(6)
                        .padding(.top, 8)
                        .accessibilityIdentifier("poems.verse")
                }
                .foregroundStyle(Palette.ink)
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background)
        .navigationTitle(poem.level.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Button {
                if narration.isReading {
                    narration.stop()
                } else {
                    narration.read(poem.text)
                }
            } label: {
                Label(L10n.string(narration.isReading ? "Stop reading" : "Read aloud"),
                      systemImage: narration.isReading ? "stop.fill" : "speaker.wave.2.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("poems.read")
            .frame(maxWidth: 480)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Palette.background)
        }
        .onDisappear { narration.stop() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { narration.stop() }
        }
    }
}

@MainActor
private final class PoemNarration: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private var current: ObjectIdentifier?
    private let synthesizer = AVSpeechSynthesizer()

    var isReading: Bool { current != nil }

    override init() {
        super.init()
        synthesizer.delegate = self
        synthesizer.usesApplicationAudioSession = false
    }

    func read(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB") ?? AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.84
        current = ObjectIdentifier(utterance)
        synthesizer.speak(utterance)
    }

    func stop() {
        guard current != nil else { return }
        current = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finished(utterance)
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finished(utterance)
    }

    private nonisolated func finished(_ utterance: AVSpeechUtterance) {
        let finished = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self, self.current == finished else { return }
            self.current = nil
        }
    }
}
