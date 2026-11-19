import SwiftUI
import TeachablyCore

struct TodayView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var showFamily = false
    @State private var constraints: Set<IdeaConstraint> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(spacing: 9) {
                    Image(systemName: "leaf.circle.fill").font(.title).foregroundStyle(Palette.green)
                    Text("teachably").font(.system(.title2, design: .rounded, weight: .semibold))
                    Spacer()
                    Button { showFamily = true } label: {
                        Image(systemName: "person.2").font(.body.weight(.medium))
                            .frame(width: 44, height: 44)
                            .background(.white, in: Circle())
                    }
                    .accessibilityLabel(L10n.string("Your family"))
                }
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    Text(L10n.string("Little moments.\nBig discoveries."))
                        .font(.system(.largeTitle, design: .serif, weight: .medium))
                        .tracking(-1)
                        .accessibilityIdentifier("today.heading")
                    Text(L10n.string("A little of what you know. A whole lot of together."))
                        .font(.subheadline).foregroundStyle(Palette.muted)
                }
                if let activity = store.today {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Eyebrow(text: store.completedToday ? L10n.string("A lovely day of discovery") : L10n.string("Your idea for today"))
                            Spacer()
                            if store.completedToday {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(Palette.green)
                            }
                        }
                        VStack(alignment: .leading, spacing: 0) {
                            ActivityArtwork(activity: activity)
                            VStack(alignment: .leading, spacing: 15) {
                                Label(activity.skill.title, systemImage: activity.skill.symbol)
                                    .font(.caption.weight(.semibold)).foregroundStyle(Palette.green)
                                Text(activity.title)
                                    .font(.system(.title, design: .serif, weight: .medium))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .accessibilityIdentifier("today.activity.title")
                                Text(activity.subtitle).font(.subheadline).foregroundStyle(Palette.muted)
                                Label(L10n.format("%lld min", activity.duration), systemImage: "clock")
                                    .font(.caption).foregroundStyle(Palette.muted)
                                    .accessibilityIdentifier("today.activity.duration")
                                NavigationLink {
                                    ActivityDetailView(activity: activity)
                                } label: {
                                    HStack {
                                        Text(store.completedToday ? L10n.string("Enjoy another moment") : L10n.string("Let's do this together"))
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                    }.padding(.horizontal, 18)
                                }.buttonStyle(PrimaryButtonStyle())
                            }.padding(22)
                        }
                        .background(.white, in: RoundedRectangle(cornerRadius: 27))
                        .clipShape(RoundedRectangle(cornerRadius: 27))
                        ideaPicker
                    }
                    PaperCard {
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "heart.text.clipboard").font(.title2).foregroundStyle(Palette.green)
                            VStack(alignment: .leading, spacing: 7) {
                                Text(L10n.string("One idea. Two little explorers.")).font(.subheadline.weight(.semibold))
                                Text(L10n.string("Give each child a way to join in, and let the older one show the younger one how to start."))
                                    .font(.subheadline).foregroundStyle(Palette.muted)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(L10n.string("Start with what you love"), systemImage: "sparkles",
                        description: Text(L10n.string("Choose your interests in My skills to find your first shared adventure.")))
                }
                Text(L10n.string("The best thing you bring is you."))
                    .font(.system(.body, design: .serif).italic()).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity).padding(.vertical, 5)
            }
            .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 24)
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showFamily) { NavigationStack { FamilyView() } }
        .onChange(of: store.todayKey) { _, _ in constraints = [] }
    }

    private var ideaPicker: some View {
        let hasMatch = store.nextIdea(matching: constraints) != nil
        return VStack(alignment: .leading, spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(IdeaConstraint.allCases) { condition in
                        let selected = constraints.contains(condition)
                        Button {
                            if selected { constraints.remove(condition) }
                            else { constraints.insert(condition) }
                        } label: {
                            Text(condition.title).font(.subheadline.weight(.medium))
                                .padding(.horizontal, 10).frame(minHeight: 44)
                                .foregroundStyle(selected ? .white : Palette.green)
                                .background(selected ? Palette.green : .white, in: Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                        .accessibilityIdentifier("today.filter.\(condition.id)")
                    }
                }
            }
            Button { withAnimation { store.chooseToday(matching: constraints) } } label: {
                Label(L10n.string("Another idea for today"), systemImage: "arrow.triangle.2.circlepath")
                    .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity, minHeight: 44)
            }
            .disabled(!hasMatch)
            .accessibilityIdentifier("today.another-idea")
            if !hasMatch {
                Text(L10n.string(constraints.isEmpty
                    ? "You've seen today's ideas for your interests. Discover has more to explore."
                    : "No new ideas match these filters today. Try clearing a filter."))
                    .font(.caption).foregroundStyle(Palette.muted)
            }
        }
    }
}

struct FamilyView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @State private var younger = ""
    @State private var older = ""
    @State private var youngerBirth = BirthMonthInput()
    @State private var olderBirth = BirthMonthInput()

    var body: some View {
        Form {
            Section(L10n.string("Younger child")) {
                TextField(L10n.string("Nickname"), text: $younger)
                BirthMonthFields(input: $youngerBirth)
            }
            Section(L10n.string("Older child")) {
                TextField(L10n.string("Nickname"), text: $older)
                BirthMonthFields(input: $olderBirth)
            }
            Section {
                Text(L10n.string("Add both birth month and year to let activities grow with each child. Ages update during their birthday month."))
            }
            Section {
                Label(L10n.string("Saved on this device"), systemImage: "iphone")
                Text(L10n.string("Your names, interests, teaching notes, and memories stay in the app's local storage. This version has no account or cloud sync."))
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle(L10n.string("Your family")).navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button(L10n.string("Cancel")) { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.string("Save")) {
                    var profile = store.profile
                    profile.youngerName = younger.trimmingCharacters(in: .whitespacesAndNewlines)
                    profile.olderName = older.trimmingCharacters(in: .whitespacesAndNewlines)
                    profile.youngerBirthMonth = youngerBirth.value
                    profile.olderBirthMonth = olderBirth.value
                    store.updateProfile(profile)
                    dismiss()
                }
                .disabled(!youngerBirth.isComplete || !olderBirth.isComplete)
            }
        }
        .onAppear {
            younger = store.profile.youngerName == "Little explorer" ? "" : store.profile.youngerName
            older = store.profile.olderName == "Big explorer" ? "" : store.profile.olderName
            youngerBirth = BirthMonthInput(store.profile.youngerBirthMonth)
            olderBirth = BirthMonthInput(store.profile.olderBirthMonth)
        }
    }
}

private struct BirthMonthInput {
    var month: Int?
    var year: Int?

    init(_ birth: BirthMonth? = nil) {
        month = birth?.month
        year = birth?.year
    }

    var value: BirthMonth? {
        guard let month, let year, let birth = BirthMonth(year: year, month: month),
              birth.age() != nil else { return nil }
        return birth
    }

    var isComplete: Bool { (month == nil && year == nil) || value != nil }
}

private struct BirthMonthFields: View {
    @Binding var input: BirthMonthInput

    var body: some View {
        let current = BirthMonth.containing(.now)
        let formatter = DateFormatter()
        let firstYear = min(current.year - 18, input.year ?? current.year)
        let lastMonth = input.year == current.year ? current.month : 12
        formatter.locale = L10n.language.locale
        formatter.calendar = Calendar(identifier: .gregorian)
        return Group {
            Picker(L10n.string("Birth year"), selection: $input.year) {
                Text(L10n.string("None")).tag(nil as Int?)
                ForEach((firstYear...current.year).reversed(), id: \.self) { year in
                    Text(year, format: .number.grouping(.never)).tag(Optional(year))
                }
            }
            Picker(L10n.string("Birth month"), selection: $input.month) {
                Text(L10n.string("None")).tag(nil as Int?)
                ForEach(1...lastMonth, id: \.self) { month in
                    Text(formatter.standaloneMonthSymbols[month - 1]).tag(Optional(month))
                }
            }
        }
        .onChange(of: input.year) { _, year in
            if year == current.year, let month = input.month, month > current.month {
                input.month = nil
            }
        }
    }
}
