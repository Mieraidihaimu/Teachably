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
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .teachablyContainer(.browse)
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
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(L10n.string("Clear search"))
                }
            }
            .padding(.leading, 14)
            .padding(.trailing, search.isEmpty ? 14 : 0)
            .frame(minHeight: 44)
            .background(Palette.surfaceCard, in: RoundedRectangle(cornerRadius: Radius.md))
            .overlay(RoundedRectangle(cornerRadius: Radius.md).strokeBorder(Palette.lineStrong, lineWidth: 1))

            Button {
                starredOnly.toggle()
            } label: {
                Image(systemName: starredOnly ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(starredOnly ? Palette.starActive : Palette.green)
                    .frame(width: 44, height: 44)
                    .background(
                        starredOnly ? Palette.gold.opacity(0.24) : Palette.greenTintedSurface,
                        in: RoundedRectangle(cornerRadius: Radius.md)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md)
                            .strokeBorder(starredOnly ? Palette.starActive : Palette.line, lineWidth: 1)
                    )
            }
            .accessibilityLabel(L10n.string("Starred drawings"))
            .accessibilityAddTraits(starredOnly ? .isSelected : [])
            .accessibilityIdentifier("drawings.starred")
        }
        .buttonStyle(.plain)
    }

    private func categoryButton(_ title: String, category item: DrawingCategory?) -> some View {
        let selected = category == item
        return Button {
            category = item
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .foregroundStyle(selected ? .white : Palette.green)
                .background(selected ? Palette.green : Palette.surfaceCard, in: Capsule())
                .overlay(Capsule().strokeBorder(selected ? Palette.green : Palette.line, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
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
                        if let guide = drawing.guide {
                            guide.stroke(Palette.green, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                                .padding(8)
                                .background(drawing.category == .shapes ? Palette.peach : Palette.sage)
                        } else {
                            GeometryReader { proxy in
                                drawing.image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: proxy.size.width, height: proxy.size.height)
                                    .clipped()
                            }
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
            .background(Palette.surfaceCard)
            .clipShape(.rect(cornerRadius: Radius.lg))
            .overlay(RoundedRectangle(cornerRadius: Radius.lg).strokeBorder(Palette.line, lineWidth: 1))
            .shadow(color: Palette.ink.opacity(0.06), radius: 10, y: 4)
            .contentShape(.rect(cornerRadius: Radius.lg))
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
            Group {
                if let guide = drawing.guide {
                    DrawingPracticeView(guide: guide, title: drawing.title)
                } else {
                    GeometryReader { proxy in
                        drawing.image
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: Radius.lg))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.lg)
                                    .strokeBorder(Palette.line, lineWidth: 1)
                            )
                            .frame(maxWidth: min(760, max(0, proxy.size.width - 32)),
                                   maxHeight: max(0, proxy.size.height - 32))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .accessibilityLabel(drawing.title)
                            .accessibilityIdentifier("drawings.preview")
                    }
                }
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

private struct DrawingPracticeView: View {
    let guide: DrawingGuide
    let title: String
    @State private var ink = Path()
    @State private var stroke = Path()
    @GestureState private var isTracing = false

    private var instruction: String { L10n.string("Trace the dashes, or make your own marks.") }

    var body: some View {
        VStack(spacing: 16) {
            Text(instruction)
                .font(.subheadline)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            GeometryReader { proxy in
                Canvas { context, size in
                    let rect = CGRect(origin: .zero, size: size)
                    context.stroke(guide.path(in: rect), with: .color(Palette.green.opacity(0.45)),
                                   style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round, dash: [3, 11]))

                    let scale = CGAffineTransform(scaleX: size.width, y: size.height)
                    let pen = StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
                    context.stroke(ink.applying(scale), with: .color(Palette.green), style: pen)
                    context.stroke(stroke.applying(scale), with: .color(Palette.green), style: pen)
                }
                .background(Palette.surfaceCard)
                .clipShape(.rect(cornerRadius: Radius.lg))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .strokeBorder(Palette.line, lineWidth: 1)
                )
                .contentShape(.rect(cornerRadius: Radius.lg))
                .gesture(tracing(in: proxy.size))
                .accessibilityElement()
                .accessibilityLabel(title)
                .accessibilityHint(instruction)
                .accessibilityDirectTouch(options: .requiresActivation)
                .accessibilityIdentifier("drawings.practice.canvas")
            }
            .aspectRatio(1, contentMode: .fit)

            Button {
                ink = Path()
                stroke = Path()
            } label: {
                Label(L10n.string("Clear drawing"), systemImage: "arrow.counterclockwise")
            }
            .buttonStyle(
                SecondaryButtonStyle(
                    fullWidth: false,
                    tint: Palette.recording,
                    backgroundColor: Palette.recording.opacity(0.10)
                )
            )
            .disabled(ink.isEmpty && stroke.isEmpty)
            .accessibilityIdentifier("drawings.practice.clear")
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: isTracing) {
            if !isTracing { stroke = Path() }
        }
    }

    private func tracing(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isTracing) { _, isTracing, _ in isTracing = true }
            .onChanged { value in record(value, in: size) }
            .onEnded { value in
                record(value, in: size)
                ink.addPath(stroke)
                stroke = Path()
            }
    }

    private func record(_ value: DragGesture.Value, in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }
        if stroke.isEmpty {
            let start = value.startLocation
            stroke.move(to: CGPoint(x: start.x / size.width, y: start.y / size.height))
            // Give a tap a short segment so the round pen cap leaves a dot.
            stroke.addLine(to: CGPoint(x: (start.x + 0.1) / size.width, y: start.y / size.height))
        }
        stroke.addLine(to: CGPoint(x: value.location.x / size.width, y: value.location.y / size.height))
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
                .foregroundStyle(starred ? Palette.starActive : Palette.green)
                .frame(width: 32, height: 32)
                .background(Palette.surfaceCard.opacity(onTile ? 0.94 : 0), in: Circle())
                .overlay(Circle().strokeBorder(onTile ? Palette.line : .clear, lineWidth: 1))
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
