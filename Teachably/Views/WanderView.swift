import SwiftUI
import TeachablyCore

struct WanderView: View {
    @EnvironmentObject private var family: FamilyStore
    @StateObject private var wander = WanderStore()
    @State private var showLibrary = false
    @State private var query = ""
    @State private var recallQuery = ""

    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Color.clear.frame(height: 1).id("wander-top")
                    if let layer = wander.current {
                        heading(layer)
                        if let label = wander.highlightLabel {
                            HStack {
                                Label("Found: \(label)", systemImage: "magnifyingglass").font(.caption)
                                Spacer()
                                Button { wander.clearHighlight() } label: { Image(systemName: "xmark") }
                                    .accessibilityLabel("Dismiss search highlight")
                            }.padding(14).background(Palette.sage, in: RoundedRectangle(cornerRadius: 15))
                        }
                        if layer.isMap {
                            mapControls
                            WanderTopicView(layer: layer, layout: wander.layout, viewport: wander.viewport,
                                visited: wander.engine.visitedBubbleIDs, highlightID: wander.highlightID,
                                onExpand: { wander.explore(.expand, bubbleID: $0.id) }, onViewport: wander.setViewport)
                            HStack(spacing: 12) {
                                Button { wander.explore(.explain) } label: { Label("Explain", systemImage: "lightbulb") }
                                Spacer()
                                Button { wander.explore(.example) } label: { Label("Show an example", systemImage: "hands.sparkles") }
                            }
                            .font(.subheadline.weight(.semibold)).padding(.vertical, 8)
                        } else if let lesson = layer.lesson {
                            lessonContent(lesson)
                        }
                        Text("From your activity library · Saved on this device")
                            .font(.caption2).foregroundStyle(Palette.muted).frame(maxWidth: .infinity)
                    } else if wander.errorMessage == nil {
                        ProgressView("Opening your map…").frame(maxWidth: .infinity, minHeight: 300)
                    }
                    if let error = wander.errorMessage {
                        WanderNotice(text: error) { wander.errorMessage = nil }
                    }
                    if wander.removedPinID != nil {
                        HStack {
                            Text("Idea unpinned. Your trail is still saved.").font(.caption)
                            Spacer()
                            Button("Undo", action: wander.undoUnpin).font(.caption.bold())
                        }.padding(16).background(Palette.sage.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                    }
                }.padding(.horizontal, 22).padding(.bottom, 24)
            }
            .onChange(of: wander.current?.id) { _, _ in reader.scrollTo("wander-top", anchor: .top) }
            .background(Palette.background).foregroundStyle(Palette.ink)
            .safeAreaInset(edge: .bottom) { composer }
        }
        .navigationTitle("Wander").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { recallQuery = ""; showLibrary = true } label: {
                    Image(systemName: "bookmark")
                }.accessibilityLabel("Wander library")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Return to starting map", systemImage: "safari") { wander.explore(.root) }
                    Button("Reload this layer", systemImage: "arrow.clockwise") { wander.explore(.refresh) }
                } label: { Image(systemName: "ellipsis") }
                .accessibilityLabel("Wander options")
            }
        }
        .onChange(of: family.profile.skills, initial: true) { _, skills in wander.start(interests: skills) }
        .sheet(isPresented: $showLibrary) {
            WanderLibraryView(wander: wander, initialQuery: recallQuery)
        }
    }

    private func heading(_ layer: WanderLayer) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Eyebrow(text: layer.depth == 0 ? "A little room to wonder" : "Your trail of curiosity")
                Spacer()
                Text("L\(layer.depth)").font(.caption.bold()).foregroundStyle(Palette.green)
                    .padding(.horizontal, 10).padding(.vertical, 6).background(Palette.sage, in: Capsule())
            }
            HStack(alignment: .top, spacing: 12) {
                if let parent = layer.parentID {
                    Button { wander.open(parent) } label: {
                        Image(systemName: "arrow.left").frame(width: 40, height: 40).background(.white, in: Circle())
                    }.accessibilityLabel("Back one layer")
                }
                Text(layer.title).font(.system(.largeTitle, design: .serif, weight: .medium))
                    .tracking(-1).fixedSize(horizontal: false, vertical: true)
            }
            Text(layer.summary).font(.subheadline).foregroundStyle(Palette.muted)
            if !wander.trail.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(wander.trail) { ancestor in
                            Button(ancestor.depth == 0 ? "Starting point" : ancestor.title) { wander.open(ancestor.id) }
                                .accessibilityLabel("Return to \(ancestor.title)")
                            Image(systemName: "chevron.right").font(.system(size: 9))
                        }
                        Text("You are here").foregroundStyle(Palette.muted)
                    }.font(.caption).padding(.vertical, 6)
                }
            }
        }
    }

    private var mapControls: some View {
        HStack {
            Text("Choose an idea").font(.caption).foregroundStyle(Palette.muted)
            Spacer()
            Picker("Topic layout", selection: Binding(get: { wander.layout }, set: wander.setLayout)) {
                ForEach(WanderLayout.allCases, id: \.self) { layout in Text(layout.title).tag(layout) }
            }.pickerStyle(.segmented).frame(maxWidth: 200)
        }
    }

    private func lessonContent(_ lesson: WanderLesson) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            PaperCard {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "The idea")
                    Text(lesson.definition).font(.system(.title3, design: .serif)).lineSpacing(4)
                }
            }
            PaperCard {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "Try it together")
                    Text(lesson.exampleTitle).font(.headline)
                    Text(lesson.example).font(.subheadline).foregroundStyle(Palette.muted)
                }
            }
            AgeCard(name: family.profile.youngerName, age: 2, prompt: lesson.toddler)
            AgeCard(name: family.profile.olderName, age: 6, prompt: lesson.older)
            Text(lesson.personalPrompt).font(.system(.body, design: .serif).italic()).foregroundStyle(Palette.green)
            DisclosureGroup("Keep in mind") {
                Text(lesson.consideration).font(.caption).foregroundStyle(Palette.muted).padding(.top, 8)
            }.font(.subheadline)
            if let activity = family.activity(lesson.activityID) {
                NavigationLink { ActivityDetailView(activity: activity) } label: {
                    Label("Open the 30-minute adventure", systemImage: "arrow.up.right")
                }.buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private var composer: some View {
        HStack(spacing: 12) {
            Button {
                if let pin = wander.currentPin { wander.removePin(pin.id) } else { wander.pin() }
            } label: {
                Image(systemName: wander.currentPin == nil ? "pin" : "pin.fill")
                    .font(.title3).foregroundStyle(Palette.green).frame(width: 36, height: 40)
            }
            .accessibilityLabel(wander.currentPin == nil ? "Keep this idea" : "Unpin this idea")
            .accessibilityIdentifier("wander.pin").disabled(wander.current == nil)
            TextField("A topic, question, or example…", text: $query)
                .font(.subheadline).submitLabel(.search).onSubmit(submit)
                .accessibilityLabel("Explore a topic")
                .onChange(of: query) { _, value in if value.count > 240 { query = String(value.prefix(240)) } }
            Button(action: submit) {
                Image(systemName: "arrow.up").font(.headline).foregroundStyle(.white)
                    .frame(width: 40, height: 40).background(Palette.green, in: Circle())
            }.disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Explore topic")
        }
        .padding(10).background(.white, in: RoundedRectangle(cornerRadius: 23))
        .padding(.horizontal, 18).padding(.vertical, 8).background(Palette.background)
    }
    private func submit() {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        if text.lowercased().hasPrefix("find ") {
            recallQuery = String(text.dropFirst(5)); showLibrary = true
        } else { wander.explore(.refine, query: text) }
        query = ""
    }
}

struct WanderNotice: View {
    let text: String
    let dismiss: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(text).font(.caption)
            Spacer(minLength: 0)
            Button(action: dismiss) { Image(systemName: "xmark") }.accessibilityLabel("Dismiss message")
        }.padding(16).background(Palette.peach.opacity(0.65), in: RoundedRectangle(cornerRadius: 17))
    }
}

struct WanderTopicView: View {
    let layer: WanderLayer
    let layout: WanderLayout
    let viewport: WanderViewport
    let visited: Set<String>
    let highlightID: String?
    let onExpand: (WanderBubble) -> Void
    let onViewport: (WanderViewport) -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @GestureState private var drag: CGSize = .zero
    @GestureState private var magnification: CGFloat = 1

    private var usesList: Bool {
        if typeSize.isAccessibilitySize { return true }
        if layout != .automatic { return layout == .list }
        return layer.bubbles.count > 7 || layer.bubbles.contains { $0.label.count > 24 || $0.label.split(separator: " ").count > 4 }
    }
    var body: some View {
        if usesList {
            VStack(spacing: 12) {
                ForEach(Array(layer.bubbles.enumerated()), id: \.element.id) { index, bubble in
                    Button { onExpand(bubble) } label: {
                        HStack(spacing: 13) {
                            Image(systemName: bubble.symbol).font(.title3).frame(width: 44, height: 48)
                                .background(tint(bubble, index), in: RoundedRectangle(cornerRadius: 14))
                            VStack(alignment: .leading, spacing: 6) {
                                Text(bubble.label).font(.system(.headline, design: .serif))
                                Text(bubble.summary).font(.caption).foregroundStyle(Palette.muted)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: visited.contains(bubble.id) ? "checkmark" : "arrow.up.right").font(.caption)
                        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white, in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22).stroke(bubble.id == highlightID ? Palette.green : .clear, lineWidth: 2))
                    }.buttonStyle(.plain).accessibilityLabel(bubble.label).accessibilityHint(bubble.summary)
                }
            }
        } else {
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    ZStack {
                        Path { path in
                            for index in layer.bubbles.indices {
                                let point = position(index, count: layer.bubbles.count)
                                path.move(to: CGPoint(x: width * 0.5, y: width * 0.5))
                                path.addLine(to: CGPoint(x: width * point.x, y: width * point.y))
                            }
                        }.stroke(Palette.green.opacity(0.13), style: StrokeStyle(lineWidth: 1.5, dash: [3, 5]))
                        ForEach(Array(layer.bubbles.enumerated()), id: \.element.id) { index, bubble in
                            let point = position(index, count: layer.bubbles.count)
                            let diameter = width * point.size
                            Button { onExpand(bubble) } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: bubble.symbol).font(.system(size: 18, weight: .light))
                                    Text(bubble.label).font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.8)
                                    Image(systemName: visited.contains(bubble.id) ? "checkmark" : "arrow.up.right")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .padding(10).frame(width: diameter, height: diameter)
                                .background(tint(bubble, index), in: Circle())
                                .overlay(Circle().stroke(bubble.id == highlightID ? Palette.green : .white.opacity(0.6), lineWidth: bubble.id == highlightID ? 3 : 1))
                            }
                            .buttonStyle(.plain).foregroundStyle(Palette.green)
                            .position(x: width * point.x, y: width * point.y)
                            .accessibilityLabel(bubble.label).accessibilityHint(bubble.summary)
                        }
                    }
                    .scaleEffect(viewport.scale * magnification)
                    .offset(x: viewport.x + drag.width, y: viewport.y + drag.height)
                    .gesture(DragGesture(minimumDistance: 12).updating($drag) { value, state, _ in
                        if viewport.scale > 1 { state = value.translation }
                    }.onEnded { value in
                        if viewport.scale > 1 {
                            var view = viewport; view.x += value.translation.width; view.y += value.translation.height
                            onViewport(view)
                        }
                    }, including: viewport.scale > 1 ? .all : .subviews)
                    .simultaneousGesture(MagnificationGesture().updating($magnification) { value, state, _ in state = value }
                        .onEnded { value in var view = viewport; view.scale *= value; onViewport(view) })
                }
                .aspectRatio(1, contentMode: .fit).clipped()
                HStack(spacing: 20) {
                    Button { zoom(-0.1) } label: { Image(systemName: "minus") }.accessibilityLabel("Zoom out map")
                    Button("\(Int(viewport.scale * 100))%") { onViewport(WanderViewport()) }.accessibilityLabel("Fit map")
                    Button { zoom(0.1) } label: { Image(systemName: "plus") }.accessibilityLabel("Zoom in map")
                }
                .font(.caption.weight(.medium)).padding(.bottom, 14)
            }
            .padding(8).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 25))
        }
    }
    private func tint(_ bubble: WanderBubble, _ index: Int) -> Color {
        bubble.skill.map(Palette.tint) ?? [Palette.sage, Palette.peach, Palette.gold.opacity(0.4)][index % 3]
    }
    private func zoom(_ delta: Double) { var view = viewport; view.scale += delta; onViewport(view) }
    private func position(_ index: Int, count: Int) -> (x: Double, y: Double, size: Double) {
        switch count {
        case 1: return (0.5, 0.5, 0.55)
        case 2: return index == 0 ? (0.28, 0.36, 0.41) : (0.72, 0.64, 0.41)
        case 3: return [(0.5, 0.25, 0.42), (0.26, 0.71, 0.42), (0.74, 0.71, 0.42)][index]
        case 4: return [(0.27, 0.27, 0.42), (0.73, 0.27, 0.42), (0.27, 0.73, 0.42), (0.73, 0.73, 0.42)][index]
        case 5: return [(0.28, 0.2, 0.33), (0.72, 0.2, 0.33), (0.5, 0.5, 0.34), (0.23, 0.8, 0.33), (0.77, 0.8, 0.33)][index]
        case 6: return [(0.29, 0.18, 0.31), (0.71, 0.18, 0.31), (0.2, 0.5, 0.31), (0.8, 0.5, 0.31), (0.29, 0.82, 0.31), (0.71, 0.82, 0.31)][index]
        case 7: return [(0.5, 0.17, 0.30), (0.80, 0.335, 0.30), (0.80, 0.665, 0.30), (0.5, 0.83, 0.30), (0.20, 0.665, 0.30), (0.20, 0.335, 0.30), (0.5, 0.5, 0.30)][index]
        default:
            let rows = Double((count + 2) / 3)
            return ((Double(index % 3) + 0.5) / 3, (Double(index / 3) + 0.5) / rows, min(0.29, 0.9 / rows))
        }
    }
}
