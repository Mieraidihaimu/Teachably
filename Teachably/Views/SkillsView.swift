import SwiftUI
import TeachablyCore

struct SkillsView: View {
    var isOnboarding = false
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<Skill> = []
    @State private var saved = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isOnboarding {
                    Label("teachably", systemImage: "leaf.circle.fill")
                        .font(.system(.title2, design: .rounded, weight: .semibold)).foregroundStyle(Palette.green)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "Your everyday superpowers")
                    Text("You already have\nso much to share.")
                        .font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
                    Text("What do you know or enjoy? Choose a few things, and we'll find little ways to share them with your sons.")
                        .foregroundStyle(Palette.muted)
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("\(selected.count) interests · \(store.activities.filter { selected.contains($0.skill) }.count) adventures")
                        .font(.caption.weight(.semibold)).foregroundStyle(Palette.green)
                    Spacer()
                    if selected != Skill.familyInterests {
                        Button("Use my seven interests") {
                            selected = Skill.familyInterests
                            saved = false
                        }.font(.caption.weight(.semibold))
                    }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                    ForEach(Skill.allCases) { skill in
                        Button {
                            if selected.contains(skill) { selected.remove(skill) }
                            else { selected.insert(skill) }
                            saved = false
                        } label: {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Image(systemName: skill.symbol).font(.title2)
                                    Spacer()
                                    Image(systemName: selected.contains(skill) ? "checkmark.circle.fill" : "circle")
                                        .font(.body)
                                }
                                Text(skill.title).font(.subheadline.weight(.semibold))
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
                            .padding(16)
                            .foregroundStyle(selected.contains(skill) ? Palette.green : Palette.ink)
                            .background(selected.contains(skill) ? Palette.sage.opacity(0.7) : .white,
                                        in: RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22)
                                .stroke(selected.contains(skill) ? Palette.green : .clear, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected.contains(skill) ? .isSelected : [])
                    }
                }
                PaperCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You don't have to be an expert.")
                            .font(.system(.title3, design: .serif, weight: .medium))
                        Text("A way you solve a maths problem, a favourite book, a line from your diary. Each activity leaves space for your own experience.")
                            .font(.subheadline).foregroundStyle(Palette.muted)
                    }
                }
                if !isOnboarding {
                    Text("New suggestions use your saved interests. Today's idea stays put until you choose another.")
                        .font(.caption).foregroundStyle(Palette.muted)
                }
            }
            .padding(22).padding(.bottom, 20)
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .navigationTitle(isOnboarding ? "" : "My skills")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                var profile = store.profile
                profile.skills = selected
                profile.hasChosenSkills = true
                store.updateProfile(profile)
                saved = true
                if isOnboarding { dismiss() }
            } label: {
                Text(isOnboarding ? "Find our first adventure" : (saved ? "Toolkit saved ✓" : "Save my toolkit"))
            }
            .buttonStyle(PrimaryButtonStyle()).disabled(selected.isEmpty)
            .opacity(selected.isEmpty ? 0.5 : 1)
            .padding(.horizontal, 22).padding(.vertical, 12).background(Palette.background)
        }
        .onAppear { selected = store.profile.skills }
    }
}
