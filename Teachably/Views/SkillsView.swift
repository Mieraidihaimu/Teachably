import SwiftUI
import TeachablyCore

struct SkillsView: View {
    var onFinish: (() -> Void)? = nil
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var selected: Set<Skill> = []
    @State private var saved = false

    private var isOnboarding: Bool { onFinish != nil }
    private var columns: [GridItem] {
        [dynamicTypeSize.isAccessibilitySize
            ? GridItem(.flexible())
            : GridItem(.adaptive(minimum: 155), spacing: 10, alignment: .top)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.string("Pick what you’d like to share."))
                    .foregroundStyle(Palette.muted)

                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(Skill.allCases) { skill in
                        skillButton(skill)
                    }
                }

                if !isOnboarding {
                    Button(L10n.string("Use defaults")) {
                        selected = Skill.familyInterests
                        saved = false
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(minHeight: 44)
                    .disabled(selected == Skill.familyInterests)
                }
            }
            .padding(22)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
        }
        .background(Palette.background)
        .foregroundStyle(Palette.ink)
        .navigationTitle(L10n.string(isOnboarding ? "Choose interests" : "My skills"))
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                store.saveInterests(selected)
                saved = store.errorMessage == nil
                onFinish?()
            } label: {
                Text(L10n.string(isOnboarding ? "See today’s activity" : (saved ? "Saved" : "Save")))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selected.isEmpty)
            .accessibilityIdentifier("skills.save")
            .opacity(selected.isEmpty ? 0.5 : 1)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            .frame(maxWidth: 620)
            .frame(maxWidth: .infinity)
            .background(Palette.background)
        }
        .onAppear { selected = isOnboarding ? [] : store.profile.skills }
    }

    private func skillButton(_ skill: Skill) -> some View {
        let isSelected = selected.contains(skill)
        return Button {
            if isSelected { selected.remove(skill) }
            else { selected.insert(skill) }
            saved = false
        } label: {
            HStack(spacing: 8) {
                Image(systemName: skill.symbol)
                    .foregroundStyle(Palette.green)
                    .accessibilityHidden(true)
                Text(skill.title)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Palette.green : Palette.muted)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 62)
            .background(isSelected ? Palette.sage : .white, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("skills.interest.\(skill.id)")
    }
}
