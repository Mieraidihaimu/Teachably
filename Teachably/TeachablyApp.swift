import SwiftUI

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
                .tabItem { Label("Today", systemImage: "sun.max") }
            NavigationStack { WanderView() }
                .tabItem { Label("Wander", systemImage: "safari") }
            NavigationStack { DiscoverView() }
                .tabItem { Label("Discover", systemImage: "square.grid.2x2") }
            NavigationStack { SkillsView() }
                .tabItem { Label("My skills", systemImage: "hand.raised.fingers.spread") }
            NavigationStack { MemoriesView() }
                .tabItem { Label("Memories", systemImage: "heart") }
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
        .alert("Something needs attention", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: { Text(store.errorMessage ?? "") }
    }
}
