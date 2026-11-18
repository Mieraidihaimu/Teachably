import SwiftUI
import TeachablyCore

struct ShowAndTellView: View {
    private let stories = (try? ShowAndTellCatalog.load()) ?? []

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
                    ForEach(stories) { story in
                        NavigationLink {
                            ShowAndTellDetail(story: story)
                        } label: {
                            storyRow(story)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(verbatim: story.title))
                        .accessibilityIdentifier("show-and-tell.story.\(story.id)")
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background)
        .navigationTitle(L10n.string("Show and Tell"))
    }

    private func storyRow(_ story: ShowAndTellStory) -> some View {
        HStack(spacing: 14) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 3), spacing: 3) {
                ForEach(story.pictures.indices, id: \.self) { index in
                    StoryPictureArtwork(picture: story.pictures[index])
                        .clipShape(.rect(cornerRadius: 3))
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
        .background(.white, in: .rect(cornerRadius: 16))
        .contentShape(Rectangle())
    }
}

private struct ShowAndTellDetail: View {
    @State private var sheet: StorySheet?
    let story: ShowAndTellStory

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    sheet = .text
                } label: {
                    Label(L10n.string("Read story"), systemImage: "book")
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("show-and-tell.read")

                Text(L10n.string("Look at the pictures. What happens first, next, and last?"))
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)

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
            }
            .padding(20)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background)
        .navigationTitle(story.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sheet) { selection in
            NavigationStack {
                switch selection {
                case .text:
                    storyText
                case .pictures(let index):
                    StoryPictureViewer(story: story, index: index)
                }
            }
        }
    }

    private func numberedPicture(_ picture: ShowAndTellStory.Picture, index: Int) -> some View {
        StoryPictureArtwork(picture: picture)
            .clipShape(.rect(cornerRadius: 12))
            .overlay(alignment: .topLeading) {
                Text(index + 1, format: .number)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(Palette.ink)
                    .frame(minWidth: 25, minHeight: 25)
                    .background(.white, in: .circle)
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
            .frame(maxWidth: 540, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity)
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
                .clipShape(.rect(cornerRadius: 20))
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
                        .frame(width: 48, height: 48)
                        .background(.white, in: .circle)
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
                        .frame(width: 48, height: 48)
                        .background(.white, in: .circle)
                }
                .disabled(index == story.pictures.count - 1)
                .accessibilityLabel(L10n.string("Next picture"))
            }
            .buttonStyle(.borderless)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: 680)
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
