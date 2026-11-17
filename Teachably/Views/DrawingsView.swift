import SwiftUI
import TeachablyCore

private struct DrawingSection: Identifiable {
    let level: DrawingLevel
    let drawings: [Drawing]

    var id: DrawingLevel { level }
}

struct DrawingsView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dynamicTypeSize) private var dynamicType
    @FocusState private var searchFocused: Bool
    @State private var search = ""
    @State private var category: DrawingCategory?
    @State private var level: DrawingLevel?
    @State private var starredOnly = false
    @State private var preview: Drawing?

    private var sections: [DrawingSection] {
        let words = search.split(whereSeparator: \.isWhitespace)
        let locale = L10n.language.locale
        let levels = level.map { [$0] } ?? DrawingLevel.allCases
        return levels.compactMap { item in
            let drawings = DrawingCatalog.drawings[item, default: []].filter { drawing in
                (category == nil || drawing.category == category)
                    && (!starredOnly || store.starredDrawingIDs.contains(drawing.id))
                    && (words.isEmpty || drawing.matches(words, locale: locale))
            }
            return drawings.isEmpty ? nil : DrawingSection(level: item, drawings: drawings)
        }
    }

    var body: some View {
        ScrollViewReader { scroll in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 22) {
                    galleryControls
                        .id("drawings.top")

                    let visibleSections = sections
                    if visibleSections.isEmpty {
                        emptyState
                            .frame(maxWidth: .infinity)
                    } else {
                        ForEach(visibleSections) { section in
                            levelSection(section)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: level) {
                searchFocused = false
                scroll.scrollTo("drawings.top", anchor: .top)
            }
        }
        .background(Palette.background)
        .navigationTitle(L10n.string("Drawings"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                levelMenu
            }
        }
        .fullScreenCover(item: $preview) { drawing in
            drawingPreview(drawing)
        }
    }

    private var galleryControls: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.string("What shall we draw?"))
                .font(.system(.largeTitle, design: .serif, weight: .medium))
                .foregroundStyle(Palette.ink)
                .accessibilityAddTraits(.isHeader)
            searchBar
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    categoryButton(L10n.string("All drawings"), category: nil)
                    ForEach(DrawingCategory.allCases, id: \.self) { item in
                        categoryButton(item.title, category: item)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var levelMenu: some View {
        Menu {
            Picker(L10n.string("Drawing level"), selection: $level) {
                Text(L10n.string("All levels")).tag(nil as DrawingLevel?)
                ForEach(DrawingLevel.allCases) { item in
                    Text(item.title).tag(Optional(item))
                }
            }
        } label: {
            Label(level?.title ?? L10n.string("All levels"), systemImage: "line.3.horizontal.decrease")
        }
        .accessibilityIdentifier("drawings.level")
    }

    private func levelSection(_ section: DrawingSection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(title: section.level.title)
                .accessibilityAddTraits(.isHeader)
            DrawingMosaic(singleColumn: dynamicType.isAccessibilitySize) {
                ForEach(section.drawings) { drawing in
                    drawingTile(drawing)
                }
            }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Palette.green)
                    .accessibilityHidden(true)
                TextField(L10n.string("Search drawings"), text: $search)
                    .foregroundStyle(Palette.ink)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onSubmit { searchFocused = false }
                    .accessibilityIdentifier("drawings.search")
                if !search.isEmpty {
                    Button {
                        search = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Palette.muted)
                            .frame(width: 44, height: 48)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(L10n.string("Clear search"))
                }
            }
            .padding(.leading, 14)
            .frame(minHeight: 48)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))

            Button {
                starredOnly.toggle()
            } label: {
                Image(systemName: starredOnly ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(starredOnly ? .white : Palette.green)
                    .frame(width: 48, height: 48)
                    .background(starredOnly ? Palette.green : Palette.sage, in: RoundedRectangle(cornerRadius: 16))
            }
            .accessibilityLabel(L10n.string("Starred drawings"))
            .accessibilityAddTraits(starredOnly ? .isSelected : [])
            .accessibilityIdentifier("drawings.starred")
        }
        .buttonStyle(.plain)
    }

    private func categoryButton(_ title: String, category item: DrawingCategory?) -> some View {
        Button {
            category = item
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .foregroundStyle(category == item ? .white : Palette.green)
                .background(category == item ? Palette.green : .white, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(category == item ? .isSelected : [])
    }

    @ViewBuilder
    private var emptyState: some View {
        if starredOnly && store.starredDrawingIDs.isEmpty {
            ContentUnavailableView {
                Label(L10n.string("No starred drawings yet"), systemImage: "star")
            } description: {
                Text(L10n.string("Tap a star to save a drawing here."))
            }
        } else if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            ContentUnavailableView.search(text: search)
        } else {
            ContentUnavailableView(L10n.string("No drawings here"), systemImage: "pencil.and.outline")
        }
    }

    private func drawingTile(_ drawing: Drawing) -> some View {
        Button {
            searchFocused = false
            preview = drawing
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .aspectRatio(drawing.tileAspectRatio, contentMode: .fit)
                    .overlay {
                        GeometryReader { proxy in
                            drawing.image
                                .resizable()
                                .scaledToFill()
                                .frame(width: proxy.size.width, height: proxy.size.height)
                                .clipped()
                        }
                    }
                    .accessibilityHidden(true)
                Text(drawing.title)
                    .font(.system(.headline, design: .serif, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 11)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(.white)
            .clipShape(.rect(cornerRadius: 18))
            .contentShape(.rect(cornerRadius: 18))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("drawing.\(drawing.id)")
        .overlay(alignment: .topTrailing) {
            DrawingStarButton(drawing: drawing, onTile: true)
                .padding(4)
        }
    }

    private func drawingPreview(_ drawing: Drawing) -> some View {
        NavigationStack {
            GeometryReader { proxy in
                drawing.image
                    .resizable()
                    .scaledToFit()
                    .clipShape(.rect(cornerRadius: 22))
                    .frame(maxWidth: min(900, max(0, proxy.size.width - 32)),
                           maxHeight: max(0, proxy.size.height - 32))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .accessibilityLabel(drawing.title)
                    .accessibilityIdentifier("drawings.preview")
            }
            .background(Palette.background)
            .navigationTitle(drawing.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.string("Done")) { preview = nil }
                }
                ToolbarItem(placement: .primaryAction) {
                    DrawingStarButton(drawing: drawing, onTile: false)
                }
            }
        }
    }
}

private struct DrawingStarButton: View {
    @EnvironmentObject private var store: FamilyStore
    let drawing: Drawing
    let onTile: Bool

    var body: some View {
        let starred = store.starredDrawingIDs.contains(drawing.id)
        Button {
            store.toggleDrawingStar(drawing.id)
        } label: {
            Image(systemName: starred ? "star.fill" : "star")
                .font(.system(size: onTile ? 16 : 20, weight: .semibold))
                .foregroundStyle(starred ? Color(red: 0.57, green: 0.34, blue: 0.09) : Palette.green)
                .frame(width: 34, height: 34)
                .background(.white.opacity(onTile ? 0.94 : 0), in: Circle())
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.format(starred ? "Unstar drawing: %@" : "Star drawing: %@", drawing.title))
        .accessibilityAddTraits(starred ? .isSelected : [])
        .accessibilityIdentifier(onTile ? "drawing.star.\(drawing.id)" : "drawings.preview.star")
    }
}

private struct DrawingMosaic: Layout {
    let singleColumn: Bool
    private let spacing: CGFloat = 12

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let idealWidth: CGFloat = 340
        let proposedWidth = proposal.width ?? idealWidth
        let width = proposedWidth.isFinite ? proposedWidth : idealWidth
        let frames = tileFrames(width: width, subviews: subviews)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (tile, frame) in zip(subviews, tileFrames(width: bounds.width, subviews: subviews)) {
            tile.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                       anchor: .topLeading, proposal: ProposedViewSize(frame.size))
        }
    }

    private func tileFrames(width: CGFloat, subviews: Subviews) -> [CGRect] {
        let columns = singleColumn ? 1 : min(4, max(1, Int((width + spacing) / 136)))
        let tileWidth = max(0, (width - spacing * CGFloat(columns - 1)) / CGFloat(columns))
        var columnHeights = Array(repeating: CGFloat.zero, count: columns)
        return subviews.map { tile in
            let column = columnHeights.indices.min { columnHeights[$0] < columnHeights[$1] } ?? 0
            let height = tile.sizeThatFits(ProposedViewSize(width: tileWidth, height: nil)).height
            let frame = CGRect(x: CGFloat(column) * (tileWidth + spacing), y: columnHeights[column],
                               width: tileWidth, height: height)
            columnHeights[column] = frame.maxY + spacing
            return frame
        }
    }
}
