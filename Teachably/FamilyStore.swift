import SwiftUI
import TeachablyCore

@MainActor
final class FamilyStore: ObservableObject {
    @Published private(set) var state: FamilyState
    @Published private(set) var activities: [Activity] = []
    @Published var errorMessage: String?
    @Published private(set) var todayKey = DailyPlanner.dayKey(for: Date())
    private let defaults: UserDefaults
    private let storageKey = "teachably.family.v1"

    init(defaults: UserDefaults? = nil) {
        var storage = defaults ?? .standard
        #if DEBUG
        if let suite = ProcessInfo.processInfo.environment["TEACHABLY_TEST_SUITE"],
           let testStorage = UserDefaults(suiteName: suite) {
            storage = testStorage
        }
        #endif
        self.defaults = storage
        var restored = FamilyState()
        var problem: String?
        if let data = storage.data(forKey: storageKey) {
            do { restored = try FamilyState.decode(data) }
            catch { problem = "Your saved family data could not be opened. It has been kept on this device. Please close the app and try again." }
        }
        self.state = restored
        do { self.activities = try ActivityCatalog.load() }
        catch { problem = "The activity library could not be opened. Please close the app and try again." }
        self.errorMessage = problem
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--demo"), problem == nil {
            self.state.profile.skills = Skill.familyInterests
            self.state.profile.hasChosenSkills = true
        }
        #endif
    }

    var profile: FamilyProfile { state.profile }
    var today: Activity? {
        guard let plan = state.plans.first(where: { $0.day == todayKey }) else { return nil }
        return activity(plan.activityID)
    }
    var completedToday: Bool {
        state.memories.contains { DailyPlanner.dayKey(for: $0.date) == todayKey }
    }
    var hasMoreIdeas: Bool {
        let offered = state.plans.first { $0.day == todayKey }?.offeredIDs ?? []
        return activities.contains {
            (profile.skills.isEmpty || profile.skills.contains($0.skill)) && !offered.contains($0.id)
        }
    }
    func activity(_ id: String) -> Activity? { activities.first { $0.id == id } }

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

    func chooseToday() {
        guard errorMessage == nil else { return }
        let current = state.plans.first { $0.day == todayKey }
        let excluded = Set(current?.offeredIDs ?? [])
        guard let next = DailyPlanner.suggest(from: activities, skills: profile.skills,
            history: state.plans, day: todayKey, excluding: excluded) else { return }
        var plan = current ?? DailyPlan(day: todayKey, activityID: next.id, offeredIDs: [])
        plan.activityID = next.id
        plan.offeredIDs.append(next.id)
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
        catch { errorMessage = "Your latest change could not be saved. Please try reopening the app." }
    }
}
