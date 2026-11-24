import SwiftUI
import TeachablyCore

@main
struct TeachablyApp: App {
    @StateObject private var store = FamilyStore()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(store)
                .tint(Palette.green)
                .preferredColorScheme(.light)
        }
    }
}

struct ContentView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var showWelcome = false
    @State private var showError = false

    var body: some View {
        TabView {
            NavigationStack { TodayView() }
                .tabItem { Label(L10n.string("Today"), systemImage: "sun.max") }
            NavigationStack { PoemsView() }
                .tabItem { Label(L10n.string("Poems"), systemImage: "book") }
            NavigationStack { DiscoverView() }
                .tabItem { Label(L10n.string("Discover"), systemImage: "square.grid.2x2") }
            NavigationStack { DrawingsView() }
                .tabItem { Label(L10n.string("Drawings"), systemImage: "pencil.and.outline") }
            NavigationStack { MoreView() }
                .tabItem { Label(L10n.string("More"), systemImage: "ellipsis") }
        }
        .task {
            store.refreshToday()
            showWelcome = !store.profile.hasChosenSkills && store.errorMessage == nil
            showError = store.errorMessage != nil
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshToday() }
        }
        .sheet(isPresented: $showWelcome) {
            NavigationStack { WelcomeView { showWelcome = false } }
                .interactiveDismissDisabled()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Palette.background)
                .presentationCornerRadius(Radius.xl)
        }
        .onChange(of: store.errorMessage) { _, value in showError = value != nil }
        .alert(L10n.string("Something needs attention"), isPresented: $showError) {
            Button(L10n.string("OK"), role: .cancel) { }
        } message: { Text(store.errorMessage ?? "") }
    }
}

private struct WelcomeView: View {
    @EnvironmentObject private var store: FamilyStore
    let onFinish: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 42, weight: .medium))
                        .foregroundStyle(Palette.green)
                        .frame(width: 88, height: 88)
                        .background(Palette.sage, in: RoundedRectangle(cornerRadius: Radius.xl))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.xl)
                                .strokeBorder(Palette.line, lineWidth: 1)
                        )
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(L10n.string("Welcome to Teachably"))
                            .font(.system(.largeTitle, design: .serif, weight: .medium))
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("welcome.heading")
                        Text(L10n.string("A daily activity to try with your kids."))
                            .foregroundStyle(Palette.muted)
                    }
                    .multilineTextAlignment(.center)
                }
                .padding(24)
                .frame(minHeight: geometry.size.height)
                .teachablyContainer(.focused)
            }
        }
        .teachablyBottomBar {
            VStack(spacing: 6) {
                Button {
                    store.saveInterests(store.profile.skills)
                    onFinish()
                } label: {
                    Text(L10n.string("See today’s activity"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("welcome.start")

                NavigationLink {
                    SkillsView(onFinish: onFinish)
                } label: {
                    Text(L10n.string("Choose interests"))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(QuietButtonStyle())
                .accessibilityIdentifier("welcome.interests")
            }
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .toolbar(.hidden, for: .navigationBar)
    }
}

private struct MoreView: View {
    @StateObject private var wander = WanderStore()

    var body: some View {
        List {
            NavigationLink { TodayPrintView() } label: {
                Label(L10n.string("Print for today"), systemImage: "printer")
            }
            .accessibilityIdentifier("more.print-today")
            NavigationLink { ShowAndTellView() } label: {
                Label(L10n.string("Show and Tell"), systemImage: "photo.on.rectangle.angled")
            }
            .accessibilityIdentifier("more.show-and-tell")
            NavigationLink { WanderView(wander: wander) } label: {
                Label(L10n.string("Wander"), systemImage: "safari")
            }
            .accessibilityIdentifier("more.wander")
            NavigationLink { SkillsView() } label: {
                Label(L10n.string("My skills"), systemImage: "hand.raised.fingers.spread")
            }
            .accessibilityIdentifier("more.skills")
            NavigationLink { MemoriesView() } label: {
                Label(L10n.string("Memories"), systemImage: "heart")
            }
            .accessibilityIdentifier("more.memories")
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle(L10n.string("More"))
    }
}
