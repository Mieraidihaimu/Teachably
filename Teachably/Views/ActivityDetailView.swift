import SwiftUI
import TeachablyCore

struct ActivityDetailView: View {
    let activity: Activity
    @EnvironmentObject private var store: FamilyStore
    @State private var packed: Set<String> = []
    @State private var note = ""
    @State private var noteSaved = false
    @State private var showSession = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ActivityArtwork(activity: activity, height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 26))
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: activity.skill.title)
                    Text(activity.title).font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
                    Text(activity.subtitle).foregroundStyle(Palette.muted)
                    Label(L10n.string("30 relaxed minutes · Together, ages 2 & 6"), systemImage: "clock")
                        .font(.caption).foregroundStyle(Palette.green)
                }
                PaperCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: L10n.string("The little discovery"))
                        Text(activity.takeaway).font(.system(.title3, design: .serif, weight: .medium))
                        DisclosureGroup(L10n.string("A quick refresher for you")) {
                            Text(activity.parentPrimer).font(.subheadline).foregroundStyle(Palette.muted)
                                .padding(.top, 8)
                        }.font(.subheadline.weight(.medium))
                    }
                }
                VStack(alignment: .leading, spacing: 13) {
                    SectionTitle(title: L10n.string("Gather a few things"))
                    ForEach(activity.materials, id: \.self) { item in
                        Button {
                            if packed.contains(item) { packed.remove(item) } else { packed.insert(item) }
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: packed.contains(item) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3).foregroundStyle(Palette.green)
                                Text(item).font(.subheadline).foregroundStyle(Palette.ink)
                                Spacer()
                            }.frame(minHeight: 38)
                        }
                        .accessibilityLabel(L10n.format(packed.contains(item) ? "%@, ready" : "%@, not checked", item))
                    }
                    Text(activity.careNote).font(.caption).foregroundStyle(Palette.muted)
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.sage.opacity(0.35), in: RoundedRectangle(cornerRadius: 16))
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: L10n.string("Same adventure, their own way"))
                    AgeCard(name: store.profile.youngerDisplayName, age: 2, prompt: activity.toddler)
                    AgeCard(name: store.profile.olderDisplayName, age: 6, prompt: activity.older)
                }
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(title: L10n.string("Your half hour, loosely planned"))
                    ForEach(Array(activity.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 13) {
                            Text("\(index + 1)").font(.caption.bold()).foregroundStyle(Palette.green)
                                .frame(width: 30, height: 30).background(Palette.sage, in: Circle())
                            VStack(alignment: .leading, spacing: 5) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(step.title).font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(L10n.format("%lld min", step.minutes)).font(.caption).foregroundStyle(Palette.muted)
                                }
                                Text(step.instruction).font(.subheadline).foregroundStyle(Palette.muted)
                            }
                        }
                    }
                    Text(L10n.string("Shorter is lovely too. Follow their energy and pause whenever you need."))
                        .font(.caption).foregroundStyle(Palette.green)
                }
                PaperCard {
                    VStack(alignment: .leading, spacing: 13) {
                        Label(L10n.string("Bring a little of you"), systemImage: "heart.text.square")
                            .font(.system(.title3, design: .serif, weight: .medium))
                        Text(activity.personalPrompt).font(.subheadline).foregroundStyle(Palette.muted)
                        TextField(L10n.string("A story, skill, or memory to share…"), text: $note, axis: .vertical)
                            .lineLimit(3...6).font(.subheadline).padding(13)
                            .background(Palette.background, in: RoundedRectangle(cornerRadius: 13))
                            .accessibilityLabel(L10n.string("Your teaching note"))
                        Button(noteSaved ? L10n.string("Note saved ✓") : L10n.string("Save my note")) {
                            store.setTeachingNote(note, for: activity)
                            noteSaved = true
                        }.font(.subheadline.weight(.semibold))
                    }
                }
            }
            .padding(22)
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                store.setTeachingNote(note, for: activity)
                showSession = true
            } label: {
                Label(L10n.string("Start our little adventure"), systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle()).padding(.horizontal, 22).padding(.vertical, 12)
            .background(Palette.background)
        }
        .fullScreenCover(isPresented: $showSession) { SessionView(activity: activity) }
        .onAppear { note = store.state.teachingNotes[activity.id] ?? "" }
        .onChange(of: note) { _, _ in noteSaved = false }
        .onDisappear { store.setTeachingNote(note, for: activity) }
    }
}
