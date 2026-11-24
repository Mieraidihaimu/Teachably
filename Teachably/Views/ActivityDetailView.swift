import SwiftUI
import TeachablyCore

struct ActivityDetailView: View {
    let activity: Activity
    @EnvironmentObject private var store: FamilyStore
    @State private var packed: Set<String> = []
    @State private var note = ""
    @State private var noteSaved = false
    @State private var showSession = false

    private var isNoteUnchanged: Bool {
        let saved = (store.state.teachingNotes[activity.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return note.trimmingCharacters(in: .whitespacesAndNewlines) == saved
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ActivityArtwork(activity: activity, height: 184)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.xl))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.xl)
                            .strokeBorder(Palette.line, lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: activity.skill.title)
                    Text(activity.title).font(.system(.largeTitle, design: .serif, weight: .medium)).tracking(-1)
                        .accessibilityIdentifier("activity.detail.title")
                    Text(activity.subtitle).foregroundStyle(Palette.muted)
                    Label(L10n.format("%lld min", activity.duration), systemImage: "clock")
                        .font(.caption).foregroundStyle(Palette.green)
                    if activity.sourceWanderLayerID != nil {
                        Text(L10n.string("Generated on this device · Review before sharing"))
                            .font(.caption).foregroundStyle(Palette.muted)
                    }
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
                    if activity.materials.isEmpty {
                        Text(L10n.string("No materials needed")).font(.subheadline).foregroundStyle(Palette.muted)
                    }
                    ForEach(activity.materials, id: \.self) { item in
                        let isPacked = packed.contains(item)
                        Button {
                            if isPacked { packed.remove(item) } else { packed.insert(item) }
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: isPacked ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(isPacked ? Palette.green : Palette.lineStrong)
                                Text(item).font(.subheadline).foregroundStyle(Palette.ink)
                                Spacer()
                            }
                            .frame(minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .accessibilityLabel(L10n.format(isPacked ? "%@, ready" : "%@, not checked", item))
                    }
                    Text(activity.careNote).font(.caption).foregroundStyle(Palette.muted)
                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                        .background(Palette.sage.opacity(0.45), in: RoundedRectangle(cornerRadius: Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.md)
                                .strokeBorder(Palette.sage, lineWidth: 1)
                        )
                }
                VStack(alignment: .leading, spacing: 12) {
                    SectionTitle(title: L10n.string("Same adventure, their own way"))
                    ActivityFamilyPrompts(activity: activity)
                }
                VStack(alignment: .leading, spacing: 16) {
                    SectionTitle(title: L10n.string("Your activity plan"))
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
                            .background(Palette.background, in: RoundedRectangle(cornerRadius: Radius.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.md)
                                    .strokeBorder(Palette.lineStrong, lineWidth: 1)
                            )
                            .accessibilityLabel(L10n.string("Your teaching note"))
                        Button(noteSaved ? L10n.string("Note saved ✓") : L10n.string("Save my note")) {
                            store.setTeachingNote(note, for: activity)
                            noteSaved = true
                        }
                        .buttonStyle(SecondaryButtonStyle(fullWidth: false))
                        .disabled(isNoteUnchanged && !noteSaved)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(16)
            .teachablyContainer(.reading)
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .navigationBarTitleDisplayMode(.inline)
        .teachablyBottomBar {
            Button {
                store.setTeachingNote(note, for: activity)
                showSession = true
            } label: {
                Label(L10n.string("Start activity"), systemImage: "play.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .fullScreenCover(isPresented: $showSession) { SessionView(activity: activity) }
        .onAppear { note = store.state.teachingNotes[activity.id] ?? "" }
        .onChange(of: note) { _, _ in noteSaved = false }
        .onDisappear { store.setTeachingNote(note, for: activity) }
    }
}
