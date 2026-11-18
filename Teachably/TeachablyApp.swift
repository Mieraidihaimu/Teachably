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
            NavigationStack { SkillsView(isOnboarding: true) }
                .interactiveDismissDisabled()
        }
        .onChange(of: store.errorMessage) { _, value in showError = value != nil }
        .alert(L10n.string("Something needs attention"), isPresented: $showError) {
            Button(L10n.string("OK"), role: .cancel) { }
        } message: { Text(store.errorMessage ?? "") }
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
