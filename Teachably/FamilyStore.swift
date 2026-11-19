import SwiftUI
import TeachablyCore

@MainActor
final class FamilyStore: ObservableObject {
    @Published private(set) var state: FamilyState
    private var curatedActivities: [Activity] = []
    @Published private(set) var starredDrawingIDs: Set<String>
    @Published var errorMessage: String?
    @Published private(set) var todayKey = DailyPlanner.dayKey(for: Date())
    private let defaults: UserDefaults
    private let storageKey = "teachably.family.v1"
    private let starredDrawingsKey = "teachably.drawings.starred"

    init(defaults: UserDefaults? = nil) {
        var storage = defaults ?? .standard
        #if DEBUG
        if let suite = ProcessInfo.processInfo.environment["TEACHABLY_TEST_SUITE"],
           let testStorage = UserDefaults(suiteName: suite) {
            storage = testStorage
        }
        #endif
        self.defaults = storage
        self.starredDrawingIDs = Set(storage.stringArray(forKey: starredDrawingsKey) ?? [])
        var restored = FamilyState()
        var problem: String?
        if let data = storage.data(forKey: storageKey) {
            do { restored = try FamilyState.decode(data) }
            catch { problem = L10n.string("Your saved family data could not be opened. It has been kept on this device. Please close the app and try again.") }
        }
        self.state = restored
        do { self.curatedActivities = try ActivityCatalog.load() }
        catch { problem = L10n.string("The activity library could not be opened. Please close the app and try again.") }
        self.errorMessage = problem
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--demo"), problem == nil {
            self.state.profile.skills = Skill.familyInterests
            self.state.profile.hasChosenSkills = true
        }
        #endif
    }

    var profile: FamilyProfile { state.profile }
    var stages: FamilyStages { profile.stages() }
    var activities: [Activity] { curatedActivities + (state.customActivities ?? []) }
    var today: Activity? {
        guard let plan = state.plans.first(where: { $0.day == todayKey }),
              let activity = activity(plan.activityID) else { return nil }
        return plan.isQuick == true ? activity.quickVersion ?? activity : activity
    }
    var completedToday: Bool {
        state.memories.contains { DailyPlanner.dayKey(for: $0.date) == todayKey }
    }
    func activity(_ id: String) -> Activity? { activities.first { $0.id == id } }

    func addCustomActivity(_ activity: Activity) throws {
        guard errorMessage == nil else { throw CocoaError(.fileWriteUnknown) }
        guard self.activity(activity.id) == nil else { return }
        var next = state
        var saved = next.customActivities ?? []
        saved.insert(activity, at: 0)
        next.customActivities = saved
        defaults.set(try next.encoded(), forKey: storageKey)
        state = next
    }

    func toggleDrawingStar(_ id: String) {
        if starredDrawingIDs.contains(id) {
            starredDrawingIDs.remove(id)
        } else {
            starredDrawingIDs.insert(id)
        }
        defaults.set(starredDrawingIDs.sorted(), forKey: starredDrawingsKey)
    }

    func refreshToday() {
        guard errorMessage == nil else { return }
        todayKey = DailyPlanner.dayKey(for: Date())
        guard profile.hasChosenSkills, today == nil else { return }
        chooseToday()
    }

    func updateProfile(_ profile: FamilyProfile) {
        guard errorMessage == nil else { return }
        state.profile = profile
        save()
        refreshToday()
    }

    func saveInterests(_ skills: Set<Skill>) {
        var profile = self.profile
        profile.skills = skills
        profile.hasChosenSkills = true
        updateProfile(profile)
    }

    func nextIdea(matching constraints: Set<IdeaConstraint>) -> Activity? {
        let offered = state.plans.first { $0.day == todayKey }?.offeredIDs ?? []
        return DailyPlanner.suggest(from: activities, skills: profile.skills,
            history: state.plans, day: todayKey, excluding: Set(offered), constraints: constraints)
    }

    func chooseToday(matching constraints: Set<IdeaConstraint> = []) {
        guard errorMessage == nil, let next = nextIdea(matching: constraints) else { return }
        let current = state.plans.first { $0.day == todayKey }
        var plan = current ?? DailyPlan(day: todayKey, activityID: next.id, offeredIDs: [])
        plan.activityID = next.id
        plan.offeredIDs.append(next.id)
        plan.isQuick = next.duration != activity(next.id)?.duration ? true : nil
        if let index = state.plans.firstIndex(where: { $0.day == todayKey }) {
            state.plans[index] = plan
        } else {
            state.plans.append(plan)
        }
        save()
    }

    func setTeachingNote(_ note: String, for activity: Activity) {
        state.teachingNotes[activity.id] = note.trimmingCharacters(in: .whitespacesAndNewlines)
        save()
    }

    func remember(activity: Activity, note: String, favourite: Bool) {
        state.memories.insert(Memory(activityID: activity.id,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines), favourite: favourite), at: 0)
        save()
    }

    private func save() {
        // Never overwrite an unreadable saved record with an empty state.
        guard errorMessage == nil else { return }
        do { defaults.set(try state.encoded(), forKey: storageKey) }
        catch { errorMessage = L10n.string("Your latest change could not be saved. Please try reopening the app.") }
    }
}
