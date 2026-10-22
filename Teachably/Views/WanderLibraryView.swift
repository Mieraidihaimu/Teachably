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
                        Eyebrow(text: "Your Wander")
                        Text("Ideas worth\nreturning to.")
                            .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
                        Text("Keep a little discovery, or pick up an earlier trail.")
                            .font(.subheadline).foregroundStyle(Palette.muted)
                    }
                    Picker("Library section", selection: $tab) {
                        Text("Pinned (\(wander.pins.count))").tag(0)
                        Text("Explored").tag(1)
                    }.pickerStyle(.segmented)
                    if wander.removedPinID != nil {
                        HStack {
                            Text("Unpinned. Your trail is still saved.").font(.caption)
                            Spacer()
                            Button("Undo", action: wander.undoUnpin).font(.caption.bold())
                        }.padding(15).background(Palette.sage, in: RoundedRectangle(cornerRadius: 15))
                    }
                    if let error = wander.errorMessage {
                        WanderNotice(text: error) { wander.errorMessage = nil }
                    }
                    if tab == 0 { pinnedContent } else { exploredContent }
                }.padding(22)
            }
            .background(Palette.background).foregroundStyle(Palette.ink)
            .navigationTitle("Saved ideas").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDragIndicator(.visible)
    }

    private var pinnedContent: some View {
        VStack(spacing: 16) {
            if wander.pins.isEmpty {
                ContentUnavailableView("Keep a little place in your thinking", systemImage: "pin",
                    description: Text("Tap the pin beside the topic field on any map or explanation, then add your own note here."))
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
                TextField("Find an idea you've seen…", text: $query)
                    .font(.subheadline).accessibilityLabel("Search explored ideas")
                    .onChange(of: query) { _, value in if value.count > 240 { query = String(value.prefix(240)) } }
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .accessibilityLabel("Clear recall search")
                }
            }.padding(14).background(.white, in: RoundedRectangle(cornerRadius: 17))
            DisclosureGroup("Search within your trail") {
                VStack(spacing: 13) {
                    Picker("Within", selection: $scope) {
                        Text("All trails").tag("all")
                        Text("This branch").tag("branch")
                        Text("This layer").tag("layer")
                    }.pickerStyle(.menu)
                    Stepper("From layer \(minDepth)", value: $minDepth, in: 0...12)
                    Stepper("To layer \(maxDepth)", value: $maxDepth, in: 0...12)
                }.font(.subheadline).padding(.top, 12)
            }.font(.subheadline)
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Eyebrow(text: "Your recent explorations")
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
                        Text("Matches from maps and explanations you've already seen.")
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
            Text("L\(depth)").font(.caption.bold()).foregroundStyle(Palette.green)
                .padding(9).background(Palette.sage, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(.system(.headline, design: .serif))
                if exact { Text("Exact match").font(.caption2.bold()).foregroundStyle(Palette.green) }
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
                            Text("L\(pin.snapshot.layer.depth) · \(pin.snapshot.layer.path.dropFirst().dropLast().joined(separator: " › "))")
                                .font(.caption).foregroundStyle(Palette.muted)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.caption)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.buttonStyle(.plain).accessibilityLabel("Open pinned \(pin.snapshot.layer.displayTitle)")
                Text("Why did you keep this?").font(.caption.weight(.semibold)).foregroundStyle(Palette.green)
                TextField("A takeaway, a question, a story to share…", text: $note, axis: .vertical)
                    .lineLimit(2...5).font(.subheadline).padding(13)
                    .background(Palette.background, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityLabel("Pinned idea note")
                    .onChange(of: note) { _, value in
                        if value.count > 600 { note = String(value.prefix(600)) }
                        saved = false
                    }
                HStack {
                    Text("\(note.count)/600").font(.caption2).foregroundStyle(Palette.muted)
                    Spacer()
                    Button(saved ? "Note saved ✓" : "Save note") {
                        saved = wander.saveNote(note, pinID: pin.id)
                    }.font(.caption.weight(.semibold))
                        .disabled(note.trimmingCharacters(in: .whitespacesAndNewlines) == pin.note)
                }
                HStack {
                    Menu {
                        if let markdownURL { ShareLink(item: markdownURL) { Label("Notes (.md)", systemImage: "text.document") } }
                        if let jsonURL { ShareLink(item: jsonURL) { Label("Original snapshot (.json)", systemImage: "curlybraces") } }
                    } label: { Label("Share", systemImage: "square.and.arrow.up").font(.caption.weight(.semibold)) }
                    Spacer()
                    Button { wander.removePin(pin.id) } label: {
                        Label("Unpin", systemImage: "pin.slash").font(.caption)
                    }.accessibilityLabel("Unpin \(pin.snapshot.layer.displayTitle)")
                }
            }
        }
        .task(id: pin.note) {
            markdownURL = wander.export(pin, json: false)
            jsonURL = wander.export(pin, json: true)
        }
    }
}
