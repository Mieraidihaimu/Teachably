import SwiftUI
import TeachablyCore

struct TodayView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var showFamily = false
    @State private var constraints: Set<IdeaConstraint> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 9) {
                    Image(systemName: "leaf.circle.fill").font(.title).foregroundStyle(Palette.green)
                    Text("teachably").font(.system(.title2, design: .rounded, weight: .semibold))
                    Spacer()
                    Button { showFamily = true } label: {
                        Image(systemName: "person.2").font(.body.weight(.medium))
                            .frame(width: 44, height: 44)
                            .background(Palette.surfaceCard, in: Circle())
                            .overlay(Circle().strokeBorder(Palette.line, lineWidth: 1))
                    }
                    .contentShape(Circle())
                    .accessibilityLabel(L10n.string("Your family"))
                }
                VStack(alignment: .leading, spacing: 6) {
                    Eyebrow(text: Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    Text(L10n.string("Today"))
                        .font(.system(.largeTitle, design: .serif, weight: .medium))
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("today.heading")
                    if store.completedToday {
                        Label(L10n.string("Done for today"), systemImage: "checkmark.seal.fill")
                            .font(.subheadline.weight(.medium)).foregroundStyle(Palette.green)
                    }
                }
                if let activity = store.today {
                    filterChips
                    activityCard(activity)
                    anotherIdeaControl
                } else {
                    ContentUnavailableView {
                        Label(L10n.string("No activity yet"), systemImage: "sparkles")
                    } actions: {
                        if store.errorMessage == nil {
                            NavigationLink(L10n.string("Choose interests")) { SkillsView() }
                        }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.top, 12).padding(.bottom, 20)
            .teachablyContainer(.reading)
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showFamily) {
            NavigationStack { FamilyView() }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Palette.background)
                .presentationCornerRadius(Radius.xl)
        }
        .onChange(of: store.todayKey) { _, _ in constraints = [] }
    }

    private func activityCard(_ activity: Activity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ActivityArtwork(activity: activity, height: 160)
            VStack(alignment: .leading, spacing: 12) {
                Label(activity.skill.title, systemImage: activity.skill.symbol)
                    .font(.caption.weight(.semibold)).foregroundStyle(Palette.green)
                    .accessibilityIdentifier("today.activity.skill")
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
                        Text(L10n.string("See activity"))
                        Spacer()
                        Image(systemName: "arrow.forward").accessibilityHidden(true)
                    }
                    .padding(.horizontal, 18)
                }
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityIdentifier("today.activity.open")
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
        .teachablyCardSurface(cornerRadius: Radius.xl)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(IdeaConstraint.allCases) { condition in
                    let selected = constraints.contains(condition)
                    Button {
                        if selected { constraints.remove(condition) }
                        else { constraints.insert(condition) }
                    } label: {
                        Text(condition.title).font(.subheadline.weight(.medium))
                            .padding(.horizontal, 14).frame(minHeight: 44)
                            .foregroundStyle(selected ? .white : Palette.green)
                            .background(selected ? Palette.green : Palette.surfaceCard, in: Capsule())
                            .overlay(
                                Capsule()
                                    .strokeBorder(selected ? Palette.green : Palette.line, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Capsule())
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .accessibilityIdentifier("today.filter.\(condition.id)")
                }
            }
        }
    }

    private var anotherIdeaControl: some View {
        let hasMatch = store.nextIdea(matching: constraints) != nil
        return VStack(alignment: .leading, spacing: 6) {
            Button { withAnimation { store.chooseToday(matching: constraints) } } label: {
                Label(L10n.string("Another idea"), systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!hasMatch)
            .accessibilityIdentifier("today.another-idea")
            if !hasMatch {
                Text(L10n.string(constraints.isEmpty
                    ? "See more ideas in Discover."
                    : "No more matches. Try clearing a filter."))
                    .font(.caption).foregroundStyle(Palette.muted)
            }
        }
        .padding(.top, 4)
        .teachablyContainer(.focused)
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
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .tint(Palette.green)
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
