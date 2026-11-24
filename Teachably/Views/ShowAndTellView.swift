import AVFAudio
import SwiftUI
import TeachablyCore

struct ShowAndTellView: View {
    private let stories = (try? ShowAndTellCatalog.load()) ?? []
    @State private var earlierStories: [ShowAndTellStory] = []

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 10) {
                if stories.isEmpty {
                    ContentUnavailableView(L10n.string("Stories are unavailable"),
                                           systemImage: "rectangle.on.rectangle")
                } else {
                    Text(L10n.format("%lld stories in English", stories.count))
                        .font(.subheadline)
                        .foregroundStyle(Palette.muted)
                        .padding(.bottom, 4)
                    ForEach(stories, content: storyLink)
                }
                if !earlierStories.isEmpty {
                    SectionTitle(title: L10n.string("Earlier stories with recordings"))
                        .padding(.top, 12)
                    ForEach(earlierStories, content: storyLink)
                }
            }
            .padding(16)
            .teachablyContainer(.reading)
        }
        .background(Palette.background)
        .navigationTitle(L10n.string("Show and Tell"))
        .onAppear {
            earlierStories = ((try? ShowAndTellCatalog.loadOriginals()) ?? []).filter {
                StoryAudioRecorder.hasRecordings(for: $0.id)
            }
        }
    }

    private func storyLink(_ story: ShowAndTellStory) -> some View {
        NavigationLink {
            ShowAndTellDetail(story: story)
        } label: {
            storyRow(story)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: story.title))
        .accessibilityIdentifier("show-and-tell.story.\(story.id)")
    }

    private func storyRow(_ story: ShowAndTellStory) -> some View {
        HStack(spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                ForEach(story.pictures.indices, id: \.self) { index in
                    StoryPictureArtwork(picture: story.pictures[index])
                        .clipShape(.rect(cornerRadius: 4))
                }
            }
            .frame(width: 120)
            .accessibilityHidden(true)
            Text(verbatim: story.title)
                .font(.system(.headline, design: .serif))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Palette.green)
                .accessibilityHidden(true)
        }
        .padding(12)
        .teachablyCardSurface(cornerRadius: Radius.lg)
        .contentShape(.rect(cornerRadius: Radius.lg))
    }
}

private struct ShowAndTellDetail: View {
    @State private var sheet: StorySheet?
    @State private var textDetent: PresentationDetent = .large
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var audio: StoryAudioRecorder
    @State private var recordingToDelete: StoryRecording?
    let story: ShowAndTellStory

    init(story: ShowAndTellStory) {
        self.story = story
        _audio = StateObject(wrappedValue: StoryAudioRecorder(storyID: story.id))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.string("Look at the pictures. What happens first, next, and last?"))
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)

                recordButton

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                    ForEach(story.pictures.indices, id: \.self) { index in
                        let picture = story.pictures[index]
                        Button {
                            sheet = .pictures(index)
                        } label: {
                            numberedPicture(picture, index: index)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(L10n.format("Picture %lld. %@", index + 1, picture.description))
                        .accessibilityIdentifier("show-and-tell.picture.\(index + 1)")
                    }
                }
                if !audio.recordings.isEmpty { recordingList }
            }
            .padding(16)
            .teachablyContainer(.reading)
        }
        .background(Palette.background)
        .teachablyBottomBar {
            Button {
                textDetent = .large
                sheet = .text
            } label: {
                Label(L10n.string("Read story"), systemImage: "book")
            }
            .buttonStyle(PrimaryButtonStyle())
            .accessibilityIdentifier("show-and-tell.read")
        }
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { audio.stopAudio() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { audio.stopAudio() }
        }
        .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
            if notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt == AVAudioSession.InterruptionType.began.rawValue {
                audio.stopAudio()
            }
        }
        .alert(L10n.string("Delete recording?"), isPresented: Binding(
            get: { recordingToDelete != nil }, set: { if !$0 { recordingToDelete = nil } }
        ), presenting: recordingToDelete) { recording in
            Button(L10n.string("Delete recording"), role: .destructive) { audio.delete(recording) }
            Button(L10n.string("Cancel"), role: .cancel) { }
        }
        .sheet(item: $sheet) { selection in
            NavigationStack {
                switch selection {
                case .text:
                    storyText
                        .presentationDetents([.medium, .large], selection: $textDetent)
                case .pictures(let index):
                    StoryPictureViewer(story: story, index: index)
                        .presentationDetents([.large])
                }
            }
            .presentationDragIndicator(.visible)
            .presentationBackground(Palette.background)
            .presentationCornerRadius(Radius.xl)
        }
    }

    private var recordButton: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 8) {
                if let start = audio.recordingSince {
                    Button { audio.finishRecording() } label: {
                        HStack {
                            Label(L10n.string("Stop and save"), systemImage: "stop.circle.fill")
                            Spacer()
                            Text(start, style: .timer).monospacedDigit()
                        }
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(Palette.recording.opacity(0.12), in: RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .strokeBorder(Palette.recording.opacity(0.35), lineWidth: 1)
                        )
                        .foregroundStyle(Palette.recording)
                    }
                    .accessibilityIdentifier("show-and-tell.record.stop")
                } else {
                    Button { Task { await audio.startRecording() } } label: {
                        Label(L10n.string("Record our story"), systemImage: "mic")
                    }
                    .buttonStyle(SecondaryButtonStyle(fullWidth: false))
                    .disabled(audio.isRequestingPermission)
                    .accessibilityIdentifier("show-and-tell.record.start")
                    Text(L10n.string(audio.recordings.isEmpty
                        ? "Recordings stay on this device."
                        : "Play your recordings below the pictures."))
                        .font(.caption).foregroundStyle(Palette.muted)
                }
                if let error = audio.errorMessage {
                    Text(error).font(.caption).foregroundStyle(Palette.ink)
                }
            }
            .font(.subheadline.weight(.medium))
        }
    }

    private var recordingList: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle(title: L10n.string("Our recordings"))
            ForEach(audio.recordings) { recording in
                let isPlaying = audio.playingID == recording.id
                let date = recording.date.formatted(date: .abbreviated, time: .standard)
                HStack {
                    Button {
                        audio.togglePlayback(recording)
                    } label: {
                        Label(date, systemImage: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                            .frame(minHeight: 44)
                    }
                    .accessibilityLabel(L10n.format(isPlaying ? "Stop recording from %@" : "Play recording from %@", date))
                    .disabled(audio.recordingSince != nil || audio.isRequestingPermission)
                    .accessibilityIdentifier("show-and-tell.record.play")
                    Spacer()
                    Button(role: .destructive) {
                        recordingToDelete = recording
                    } label: {
                        Image(systemName: "trash")
                            .frame(minWidth: 44, minHeight: 44)
                            .foregroundStyle(Palette.recording)
                    }
                    .foregroundStyle(Palette.recording)
                    .tint(Palette.recording)
                    .accessibilityLabel(L10n.string("Delete recording"))
                }
                .padding(.horizontal, 12)
                .teachablyCardSurface(cornerRadius: Radius.md)
            }
        }
    }

    private func numberedPicture(_ picture: ShowAndTellStory.Picture, index: Int) -> some View {
        StoryPictureArtwork(picture: picture)
            .clipShape(.rect(cornerRadius: Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .strokeBorder(Palette.line, lineWidth: 1)
            )
            .overlay(alignment: .topLeading) {
                Text(index + 1, format: .number)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Palette.ink)
                    .frame(minWidth: 25, minHeight: 25)
                    .background(Palette.surfaceCard, in: .circle)
                    .padding(7)
            }
    }

    private var storyText: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(verbatim: story.title)
                    .font(.system(.largeTitle, design: .serif, weight: .medium))
                    .accessibilityAddTraits(.isHeader)
                ForEach(story.pictures.indices, id: \.self) { index in
                    Text(verbatim: story.pictures[index].text)
                        .font(.system(.title3, design: .serif))
                        .lineSpacing(4)
                        .accessibilityIdentifier("show-and-tell.text.\(index + 1)")
                }
            }
            .foregroundStyle(Palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .teachablyContainer(.focused)
        }
        .background(Palette.background)
        .navigationTitle(L10n.string("Read story"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.string("Done")) { sheet = nil }
            }
        }
    }

    private enum StorySheet: Identifiable {
        case text
        case pictures(Int)

        var id: String {
            switch self {
            case .text: "text"
            case .pictures(let index): "picture-\(index)"
            }
        }
    }
}

private struct StoryPictureViewer: View {
    @Environment(\.dismiss) private var dismiss
    let story: ShowAndTellStory
    @State var index: Int

    var body: some View {
        let picture = story.pictures[index]
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            StoryPictureArtwork(picture: picture)
                .clipShape(.rect(cornerRadius: Radius.lg))
                .accessibilityRepresentation {
                    Image(systemName: "photo")
                        .accessibilityLabel(Text(verbatim: picture.description))
                        .accessibilityIdentifier("show-and-tell.enlarged")
                }
                .gesture(DragGesture(minimumDistance: 30).onEnded { drag in
                    if abs(drag.translation.width) > abs(drag.translation.height) {
                        move(drag.translation.width < 0 ? 1 : -1)
                    }
                })
            HStack {
                Button { move(-1) } label: {
                    Image(systemName: "chevron.backward")
                        .frame(width: 44, height: 44)
                        .background(Palette.surfaceCard, in: Circle())
                        .overlay(Circle().strokeBorder(Palette.line, lineWidth: 1))
                }
                .disabled(index == 0)
                .accessibilityLabel(L10n.string("Previous picture"))
                Spacer()
                Text(L10n.format("Picture %lld of %lld", index + 1, story.pictures.count))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Palette.ink)
                    .accessibilityAddTraits(.updatesFrequently)
                Spacer()
                Button { move(1) } label: {
                    Image(systemName: "chevron.forward")
                        .frame(width: 44, height: 44)
                        .background(Palette.surfaceCard, in: Circle())
                        .overlay(Circle().strokeBorder(Palette.line, lineWidth: 1))
                }
                .disabled(index == story.pictures.count - 1)
                .accessibilityLabel(L10n.string("Next picture"))
            }
            .buttonStyle(.borderless)
            Spacer(minLength: 0)
        }
        .padding(20)
        .teachablyContainer(.reading)
        .frame(maxHeight: .infinity)
        .background(Palette.background)
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.string("Done")) { dismiss() }
            }
        }
    }

    private func move(_ delta: Int) {
        let next = index + delta
        if story.pictures.indices.contains(next) {
            index = next
        }
    }
}
