import SwiftUI
import TeachablyCore

struct MemoriesView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var favouritesOnly = false
    private var memories: [Memory] {
        store.state.memories.filter { !favouritesOnly || $0.favourite }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "The things that stay with you")
                    Text("Small moments.\nYours to keep.")
                        .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
                    Text("\(store.state.memories.count) shared \(store.state.memories.count == 1 ? "adventure" : "adventures"). No streaks, no catching up.")
                        .font(.subheadline).foregroundStyle(Palette.muted)
                }
                Toggle(isOn: $favouritesOnly) {
                    Label("Favourites to try again", systemImage: "heart")
                        .font(.subheadline)
                }.tint(Palette.green)
                if memories.isEmpty {
                    ContentUnavailableView(
                        favouritesOnly ? "Your favourites will grow here" : "Your first memory is waiting",
                        systemImage: favouritesOnly ? "heart" : "book.closed",
                        description: Text(favouritesOnly ? "Mark an adventure you'd love to repeat when saving a memory." : "Try an adventure, then keep a word, a question, or just the moment."))
                        .padding(.top, 30)
                }
                ForEach(memories) { memory in
                    if let activity = store.activity(memory.activityID) {
                        PaperCard {
                            VStack(alignment: .leading, spacing: 14) {
                                HStack {
                                    Image(systemName: activity.symbol).foregroundStyle(Palette.green)
                                    Text(memory.date.formatted(date: .abbreviated, time: .omitted))
                                        .font(.caption).foregroundStyle(Palette.muted)
                                    Spacer()
                                    if memory.favourite {
                                        Image(systemName: "heart.fill").foregroundStyle(Palette.green)
                                            .accessibilityLabel("Favourite")
                                    }
                                }
                                Text(activity.title).font(.system(.title3, design: .serif, weight: .medium))
                                if !memory.note.isEmpty { Text(memory.note).font(.subheadline).foregroundStyle(Palette.muted) }
                                NavigationLink("Enjoy this again") { ActivityDetailView(activity: activity) }
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
            }.padding(22)
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .navigationTitle("Memories").navigationBarTitleDisplayMode(.inline)
    }
}
