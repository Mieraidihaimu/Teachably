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
                    Eyebrow(text: L10n.string("The things that stay with you"))
                    Text(L10n.string("Small moments.\nYours to keep."))
                        .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
                    Text(store.state.memories.count == 1
                         ? L10n.string("One shared adventure. No streaks, no catching up.")
                         : L10n.format("%lld shared adventures. No streaks, no catching up.", store.state.memories.count))
                        .font(.subheadline).foregroundStyle(Palette.muted)
                }
                Toggle(isOn: $favouritesOnly) {
                    Label(L10n.string("Favourites to try again"), systemImage: "heart")
                        .font(.subheadline)
                }.tint(Palette.green)
                if memories.isEmpty {
                    ContentUnavailableView(
                        favouritesOnly ? L10n.string("Your favourites will grow here") : L10n.string("Your first memory is waiting"),
                        systemImage: favouritesOnly ? "heart" : "book.closed",
                        description: Text(favouritesOnly ? L10n.string("Mark an adventure you'd love to repeat when saving a memory.") : L10n.string("Try an adventure, then keep a word, a question, or just the moment.")))
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
                                            .accessibilityLabel(L10n.string("Favourite"))
                                    }
                                }
                                Text(activity.title).font(.system(.title3, design: .serif, weight: .medium))
                                if !memory.note.isEmpty { Text(memory.note).font(.subheadline).foregroundStyle(Palette.muted) }
                                NavigationLink(L10n.string("Enjoy this again")) { ActivityDetailView(activity: activity) }
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
            }.padding(22)
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .navigationTitle(L10n.string("Memories")).navigationBarTitleDisplayMode(.inline)
    }
}
