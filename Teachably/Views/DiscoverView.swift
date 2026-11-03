import SwiftUI
import TeachablyCore

struct DiscoverView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var search = ""
    @State private var filter: Skill?

    private var filtered: [Activity] {
        store.activities.filter { activity in
            (filter == nil || activity.skill == filter) &&
            (search.isEmpty || "\(activity.title) \(activity.subtitle) \(activity.skill.title)"
                .localizedCaseInsensitiveContains(search))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 9) {
                    Eyebrow(text: L10n.string("Follow a little curiosity"))
                    Text(L10n.string("What could you\nshare today?"))
                        .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
                    Text(L10n.string("Every idea has a little something for both of them."))
                        .font(.subheadline).foregroundStyle(Palette.muted)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterButton(L10n.string("All ideas"), skill: nil)
                        ForEach(Skill.allCases) { skill in filterButton(skill.title, skill: skill) }
                    }.padding(.vertical, 2)
                }
                if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
                LazyVStack(spacing: 12) {
                    ForEach(filtered) { activity in
                        NavigationLink {
                            ActivityDetailView(activity: activity)
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: activity.symbol).font(.system(size: 27, weight: .light))
                                    .frame(width: 68, height: 76)
                                    .background(Palette.tint(for: activity.skill), in: RoundedRectangle(cornerRadius: 18))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(activity.title).font(.system(.headline, design: .serif))
                                        .foregroundStyle(Palette.ink)
                                    Text(activity.skill.title).font(.caption).foregroundStyle(Palette.muted)
                                    Text(L10n.string("30 min · Ages 2 & 6")).font(.caption2).foregroundStyle(Palette.muted)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.muted)
                            }
                            .padding(14).background(.white, in: RoundedRectangle(cornerRadius: 23))
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(22)
        }
        .background(Palette.background)
        .navigationTitle(L10n.string("Discover")).navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: L10n.string("Find a little adventure"))
    }

    private func filterButton(_ title: String, skill: Skill?) -> some View {
        Button { filter = skill } label: {
            Text(title).font(.caption.weight(.semibold)).padding(.horizontal, 15).padding(.vertical, 11)
                .foregroundStyle(filter == skill ? .white : Palette.green)
                .background(filter == skill ? Palette.green : .white, in: Capsule())
        }
        .accessibilityAddTraits(filter == skill ? .isSelected : [])
    }
}
