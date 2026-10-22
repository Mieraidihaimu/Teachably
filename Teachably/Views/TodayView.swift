import SwiftUI
import TeachablyCore

struct TodayView: View {
    @EnvironmentObject private var store: FamilyStore
    @State private var showFamily = false

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
                    .accessibilityLabel("Your family")
                }
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    Text("Little moments.\nBig discoveries.")
                        .font(.system(.largeTitle, design: .serif, weight: .medium))
                        .tracking(-1)
                    Text("A little of what you know. A whole lot of together.")
                        .font(.subheadline).foregroundStyle(Palette.muted)
                }
                if let activity = store.today {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Eyebrow(text: store.completedToday ? "A lovely day of discovery" : "Your idea for today")
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
                                Text(activity.subtitle).font(.subheadline).foregroundStyle(Palette.muted)
                                HStack(spacing: 18) {
                                    Label("30 min", systemImage: "clock")
                                    Label("Ages 2 & 6", systemImage: "person.2")
                                }.font(.caption).foregroundStyle(Palette.muted)
                                NavigationLink {
                                    ActivityDetailView(activity: activity)
                                } label: {
                                    HStack {
                                        Text(store.completedToday ? "Enjoy another moment" : "Let's do this together")
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                    }.padding(.horizontal, 18)
                                }.buttonStyle(PrimaryButtonStyle())
                            }.padding(22)
                        }
                        .background(.white, in: RoundedRectangle(cornerRadius: 27))
                        .clipShape(RoundedRectangle(cornerRadius: 27))
                        if store.hasMoreIdeas {
                            Button { withAnimation { store.chooseToday() } } label: {
                                Label("Another idea for today", systemImage: "arrow.triangle.2.circlepath")
                                    .font(.subheadline.weight(.medium)).frame(maxWidth: .infinity, minHeight: 44)
                            }
                        } else {
                            Text("You've seen today's ideas for your interests. Discover has more to explore.")
                                .font(.caption).foregroundStyle(Palette.muted)
                        }
                    }
                    PaperCard {
                        HStack(alignment: .top, spacing: 15) {
                            Image(systemName: "heart.text.clipboard").font(.title2).foregroundStyle(Palette.green)
                            VStack(alignment: .leading, spacing: 7) {
                                Text("One idea. Two little explorers.").font(.subheadline.weight(.semibold))
                                Text("Play and notice at 2. Wonder and experiment at 6. Let them dip in, wander off, and come back.")
                                    .font(.subheadline).foregroundStyle(Palette.muted)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("Start with what you love", systemImage: "sparkles",
                        description: Text("Choose your interests in My skills to find your first shared adventure."))
                }
                Text("The best thing you bring is you.")
                    .font(.system(.body, design: .serif).italic()).foregroundStyle(Palette.muted)
                    .frame(maxWidth: .infinity).padding(.vertical, 5)
            }
            .padding(.horizontal, 22).padding(.top, 12).padding(.bottom, 24)
        }
        .background(Palette.background).foregroundStyle(Palette.ink)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showFamily) { NavigationStack { FamilyView() } }
    }
}

struct FamilyView: View {
    @EnvironmentObject private var store: FamilyStore
    @Environment(\.dismiss) private var dismiss
    @State private var younger = ""
    @State private var older = ""
    var body: some View {
        Form {
            Section("Your little explorers") {
                TextField("2-year-old's nickname", text: $younger)
                TextField("6-year-old's nickname", text: $older)
            }
            Section {
                Text("One family session, with different invitations for ages 2 and 6. The 30 minutes include playing, chatting, and taking breaks.")
            }
            Section {
                Label("Saved on this device", systemImage: "iphone")
                Text("Your names, interests, teaching notes, and memories stay in the app's local storage. This version has no account or cloud sync.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Your family").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    var profile = store.profile
                    profile.youngerName = younger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Little explorer" : younger
                    profile.olderName = older.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Big explorer" : older
                    store.updateProfile(profile)
                    dismiss()
                }
            }
        }
        .onAppear { younger = store.profile.youngerName; older = store.profile.olderName }
    }
}
