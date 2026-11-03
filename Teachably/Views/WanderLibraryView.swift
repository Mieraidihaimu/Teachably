import SwiftUI
import TeachablyCore

struct WanderLibraryView: View {
    @ObservedObject var wander: WanderStore
    @Environment(\.dismiss) private var dismiss
    @State private var tab: Int
    @State private var query: String
    @State private var scope = "all"
    @State private var minDepth = 0
    @State private var maxDepth = 12

    init(wander: WanderStore, initialQuery: String) {
        self.wander = wander
        _query = State(initialValue: initialQuery)
        _tab = State(initialValue: initialQuery.isEmpty ? 0 : 1)
    }
    private var results: Result<[WanderSearchHit], Error> {
        let searchScope: WanderSearchScope
        if scope == "branch", let layer = wander.current { searchScope = .branch(layer.branchID) }
        else if scope == "layer", let layer = wander.current { searchScope = .layer(layer.id) }
        else { searchScope = .all }
        return Result { try wander.engine.search(query, scope: searchScope, minDepth: minDepth, maxDepth: maxDepth) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 9) {
                        Eyebrow(text: L10n.string("Your Wander"))
                        Text(L10n.string("Ideas worth\nreturning to."))
                            .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
                        Text(L10n.string("Keep a little discovery, or pick up an earlier trail."))
                            .font(.subheadline).foregroundStyle(Palette.muted)
                    }
                    Picker(L10n.string("Library section"), selection: $tab) {
                        Text(L10n.format("Pinned (%lld)", wander.pins.count)).tag(0)
                        Text(L10n.string("Explored")).tag(1)
                    }.pickerStyle(.segmented)
                    if wander.removedPinID != nil {
                        HStack {
                            Text(L10n.string("Unpinned. Your trail is still saved.")).font(.caption)
                            Spacer()
                            Button(L10n.string("Undo"), action: wander.undoUnpin).font(.caption.bold())
                        }.padding(15).background(Palette.sage, in: RoundedRectangle(cornerRadius: 15))
                    }
                    if let error = wander.errorMessage {
                        WanderNotice(text: error) { wander.errorMessage = nil }
                    }
                    if tab == 0 { pinnedContent } else { exploredContent }
                }.padding(22)
            }
            .background(Palette.background).foregroundStyle(Palette.ink)
            .navigationTitle(L10n.string("Saved ideas")).navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(L10n.string("Done")) { dismiss() } } }
        }
        .presentationDragIndicator(.visible)
    }

    private var pinnedContent: some View {
        VStack(spacing: 16) {
            if wander.pins.isEmpty {
                ContentUnavailableView(L10n.string("Keep a little place in your thinking"), systemImage: "pin",
                    description: Text(L10n.string("Tap the pin beside the topic field on any map or explanation, then add your own note here.")))
            }
            ForEach(wander.pins) { pin in
                WanderPinCard(pin: pin, wander: wander) { wander.openPin(pin.id); dismiss() }
            }
        }
    }

    private var exploredContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(Palette.muted)
                TextField(L10n.string("Find an idea you've seen…"), text: $query)
                    .font(.subheadline).accessibilityLabel(L10n.string("Search explored ideas"))
                    .onChange(of: query) { _, value in if value.count > 240 { query = String(value.prefix(240)) } }
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel(L10n.string("Clear recall search"))
                }
            }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 17))
            DisclosureGroup(L10n.string("Search within your trail")) {
                VStack(spacing: 13) {
                    Picker(L10n.string("Within"), selection: $scope) {
                        Text(L10n.string("All trails")).tag("all")
                        Text(L10n.string("This branch")).tag("branch")
                        Text(L10n.string("This layer")).tag("layer")
                    }.pickerStyle(.menu)
                    Stepper(L10n.format("From layer %lld", minDepth), value: $minDepth, in: 0...12)
                    Stepper(L10n.format("To layer %lld", maxDepth), value: $maxDepth, in: 0...12)
                }.font(.subheadline).padding(.top, 12)
            }.font(.subheadline)
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Eyebrow(text: L10n.string("Your recent explorations"))
                ForEach(Array(wander.engine.state.layers.reversed().prefix(60))) { layer in
                    Button { wander.open(layer.id); dismiss() } label: {
                        row(title: layer.displayTitle, subtitle: layer.path.dropLast().joined(separator: " › "), depth: layer.depth)
                    }.buttonStyle(.plain)
                }
            } else {
                switch results {
                case .success(let hits):
                    if hits.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        Text(L10n.string("Matches from maps and explanations you've already seen."))
                            .font(.caption).foregroundStyle(Palette.muted)
                        ForEach(hits) { hit in
                            Button { wander.open(hit); dismiss() } label: {
                                row(title: hit.label, subtitle: hit.summary, depth: hit.depth, exact: hit.isExact)
                            }.buttonStyle(.plain)
                        }
                    }
                case .failure(let error):
                    Text(error.localizedDescription).font(.caption).foregroundStyle(Palette.green)
                }
            }
        }
    }

    private func row(title: String, subtitle: String, depth: Int, exact: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 13) {
            Text(L10n.format("L%lld", depth)).font(.caption.bold()).foregroundStyle(Palette.green)
                .padding(9).background(Palette.sage, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.system(.headline, design: .serif))
                if exact { Text(L10n.string("Exact match")).font(.caption2.bold()).foregroundStyle(Palette.green) }
                if !subtitle.isEmpty { Text(subtitle).font(.caption).foregroundStyle(Palette.muted).lineLimit(3) }
            }
            Spacer(minLength: 0)
            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Palette.green)
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct WanderPinCard: View {
    let pin: WanderPin
    @ObservedObject var wander: WanderStore
    let open: () -> Void
    @State private var note: String
    @State private var saved = false
    @State private var markdownURL: URL?
    @State private var jsonURL: URL?

    init(pin: WanderPin, wander: WanderStore, open: @escaping () -> Void) {
        self.pin = pin; self.wander = wander; self.open = open
        _note = State(initialValue: pin.note)
    }
    var body: some View {
        PaperCard {
            VStack(alignment: .leading, spacing: 16) {
                Button(action: open) {
                    HStack(alignment: .top, spacing: 13) {
                        Image(systemName: pin.snapshot.layer.isMap ? "circle.hexagongrid" : "lightbulb")
                            .font(.title2).foregroundStyle(Palette.green)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(pin.snapshot.layer.displayTitle).font(.system(.title3, design: .serif, weight: .medium))
                            Text(L10n.format("L%lld · %@", pin.snapshot.layer.depth, pin.snapshot.layer.path.dropFirst().dropLast().joined(separator: " › ")))
                                .font(.caption).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.caption)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain).accessibilityLabel(L10n.format("Open pinned %@", pin.snapshot.layer.displayTitle))
                Text(L10n.string("Why did you keep this?")).font(.caption.weight(.semibold)).foregroundStyle(Palette.green)
                TextField(L10n.string("A takeaway, a question, a story to share…"), text: $note, axis: .vertical)
                    .lineLimit(2...5).font(.subheadline).padding(13)
                    .background(Palette.background, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel(L10n.string("Pinned idea note"))
                    .onChange(of: note) { _, value in
                        if value.count > 600 { note = String(value.prefix(600)) }
                        saved = false
                    }
                HStack {
                    Text("\(note.count)/600").font(.caption2).foregroundStyle(Palette.muted)
                    Spacer()
                    Button(saved ? L10n.string("Note saved ✓") : L10n.string("Save note")) {
                        saved = wander.saveNote(note, pinID: pin.id)
                    }.font(.caption.weight(.semibold))
                        .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines) == pin.note)
                }
                HStack {
                    Menu {
                        if let markdownURL { ShareLink(item: markdownURL) { Label(L10n.string("Notes (.md)"), systemImage: "text.document") } }
                        if let jsonURL { ShareLink(item: jsonURL) { Label(L10n.string("Original snapshot (.json)"), systemImage: "curlybraces") } }
                    } label: { Label(L10n.string("Share"), systemImage: "square.and.arrow.up").font(.caption.weight(.semibold)) }
                    Spacer()
                    Button { wander.removePin(pin.id) } label: {
                        Label(L10n.string("Unpin"), systemImage: "pin.slash").font(.caption)
                    }.accessibilityLabel(L10n.format("Unpin %@", pin.snapshot.layer.displayTitle))
                }
            }
        }
        .task(id: pin.note) {
            markdownURL = wander.export(pin, json: false)
            jsonURL = wander.export(pin, json: true)
        }
    }
}
