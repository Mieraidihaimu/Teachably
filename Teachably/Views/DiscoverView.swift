import SwiftUI
import TeachablyCore

struct DiscoverView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var search = ""
    @State private var filter: Skill?
    @State private var savedOnly = false

    private var filtered: [Activity] {
        store.activities.filter { activity in
            (!savedOnly || activity.sourceWanderLayerID != nil) &&
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
                        Button {
                            savedOnly = true
                            filter = nil
                        } label: {
                            filterLabel(L10n.string("Saved from Wander"), selected: savedOnly)
                        }
                        .accessibilityAddTraits(savedOnly ? .isSelected : [])
                        ForEach(Skill.allCases) { skill in filterButton(skill.title, skill: skill) }
                    }.padding(.vertical, 2)
                }
                if filtered.isEmpty && search.isEmpty && savedOnly {
                    ContentUnavailableView(L10n.string("No saved Wander activities"), systemImage: "books.vertical")
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
                LazyVStack(spacing: 12) {
                    ForEach(filtered) { activity in
                        NavigationLink {
                            ActivityDetailView(activity: activity)
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: activity.symbol).font(.system(size: 27, weight: .light))
                                    .frame(width: 64, height: 72)
                                    .background(Palette.tint(for: activity.skill), in: RoundedRectangle(cornerRadius: Radius.md))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(activity.title).font(.system(.headline, design: .serif))
                                        .foregroundStyle(Palette.ink)
                                    Text(activity.skill.title).font(.caption).foregroundStyle(Palette.muted)
                                    Text(L10n.format("%lld min", activity.duration)).font(.caption2).foregroundStyle(Palette.muted)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Palette.green)
                            }
                            .padding(14)
                            .teachablyCardSurface(cornerRadius: Radius.lg)
                        }.buttonStyle(.plain)
                    }
                }
            }
            .padding(16)
            .teachablyContainer(.browse)
        }
        .background(Palette.background)
        .navigationTitle(L10n.string("Discover")).navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: L10n.string("Find a little adventure"))
    }

    private func filterButton(_ title: String, skill: Skill?) -> some View {
        let selected = !savedOnly && filter == skill
        return Button { filter = skill; savedOnly = false } label: {
            filterLabel(title, selected: selected)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func filterLabel(_ title: String, selected: Bool) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .foregroundStyle(selected ? .white : Palette.green)
            .background(selected ? Palette.green : Palette.surfaceCard, in: Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(selected ? Palette.green : Palette.line, lineWidth: 1)
            )
    }
}
