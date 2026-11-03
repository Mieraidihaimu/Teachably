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
            NavigationStack { WanderView() }
                .tabItem { Label(L10n.string("Wander"), systemImage: "safari") }
            NavigationStack { DiscoverView() }
                .tabItem { Label(L10n.string("Discover"), systemImage: "square.grid.2x2") }
            NavigationStack { SkillsView() }
                .tabItem { Label(L10n.string("My skills"), systemImage: "hand.raised.fingers.spread") }
            NavigationStack { MemoriesView() }
                .tabItem { Label(L10n.string("Memories"), systemImage: "heart") }
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
