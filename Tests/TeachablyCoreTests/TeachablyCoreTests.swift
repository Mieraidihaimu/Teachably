import XCTest
@testable import TeachablyCore

final class TeachablyCoreTests: XCTestCase {
    func testCatalogHasCompleteHalfHourActivitiesForBothChildren() throws {
        let activities = try ActivityCatalog.load()
        XCTAssertEqual(activities.count, 31)
        XCTAssertEqual(Set(activities.map(\.id)).count, activities.count)
        XCTAssertEqual(Set(activities.map(\.skill)), Set(Skill.allCases))
        for activity in activities {
            XCTAssertEqual(activity.duration, 30, activity.id)
            XCTAssertFalse(activity.toddler.action.isEmpty, activity.id)
            XCTAssertFalse(activity.older.action.isEmpty, activity.id)
            XCTAssertFalse(activity.personalPrompt.isEmpty, activity.id)
            XCTAssertFalse(activity.careNote.isEmpty, activity.id)
        }
    }

    func testNewFamilyStartsWithTheParentsSevenInterests() {
        let profile = FamilyProfile()
        XCTAssertEqual(profile.skills, [.numbers, .reading, .movement, .science, .journaling, .coding, .criticalThinking])
        XCTAssertFalse(profile.hasChosenSkills, "The parent should still be able to review the choices.")
    }

    func testPersonalPackBalancesSevenInterestsAcrossThreeWeeksWithoutRepeats() throws {
        let activities = try ActivityCatalog.load()
        let interests = Skill.familyInterests
        let deck = activities.filter { interests.contains($0.skill) }
        XCTAssertEqual(deck.count, 21)
        for skill in interests { XCTAssertEqual(deck.filter { $0.skill == skill }.count, 3, skill.rawValue) }

        var plans: [DailyPlan] = []
        var picks: [Activity] = []
        for day in 1...42 {
            let key = "family-day-\(day)"
            let pick = try XCTUnwrap(DailyPlanner.suggest(from: activities, skills: interests, history: plans, day: key))
            XCTAssertTrue(interests.contains(pick.skill))
            picks.append(pick)
            plans.append(DailyPlan(day: key, activityID: pick.id, offeredIDs: [pick.id]))
        }
        for start in stride(from: 0, to: 42, by: 7) {
            XCTAssertEqual(Set(picks[start..<(start + 7)].map(\.skill)), interests)
        }
        XCTAssertEqual(Set(picks.prefix(21).map(\.id)).count, 21)
        XCTAssertEqual(Set(picks.suffix(21).map(\.id)).count, 21)
    }

    func testExistingProfilesKeepTheirSavedChoicesAfterInterestLabelsChange() throws {
        let legacy = Data(#"{"youngerName":"Little explorer","olderName":"Big explorer","skills":["numbers","science","movement"],"hasChosenSkills":true}"#.utf8)
        let profile = try JSONDecoder().decode(FamilyProfile.self, from: legacy)
        XCTAssertEqual(profile.skills, [.numbers, .science, .movement])
        XCTAssertTrue(profile.hasChosenSkills)
    }

    func testDailyPicksAreStableAndStartWithParentsInterests() throws {
        let activities = try ActivityCatalog.load()
        let first = DailyPlanner.suggest(from: activities, skills: [.music], history: [], day: "2026-10-22")
        XCTAssertEqual(first?.skill, .music)
        XCTAssertEqual(first?.id, DailyPlanner.suggest(from: activities, skills: [.music], history: [], day: "2026-10-22")?.id)
    }

    func testNoRepeatsBeforeTheMatchedDeckIsExploredEvenWithoutCompletions() throws {
        let activities = try ActivityCatalog.load()
        let skills: Set<Skill> = [.music, .nature]
        let deckSize = activities.filter { skills.contains($0.skill) }.count
        var plans: [DailyPlan] = []
        var picks: [String] = []
        for day in 1...deckSize * 2 {
            let key = "day-\(day)"
            let pick = try XCTUnwrap(DailyPlanner.suggest(from: activities, skills: skills, history: plans, day: key))
            XCTAssertTrue(skills.contains(pick.skill))
            if let previous = picks.last { XCTAssertNotEqual(previous, pick.id) }
            picks.append(pick.id)
            plans.append(DailyPlan(day: key, activityID: pick.id, offeredIDs: [pick.id]))
        }
        XCTAssertEqual(Set(picks.prefix(deckSize)).count, deckSize)
        XCTAssertEqual(Set(picks.suffix(deckSize)).count, deckSize)
    }

    func testAnotherIdeaExcludesEverythingAlreadyOfferedToday() throws {
        let activities = try ActivityCatalog.load()
        var offered: Set<String> = []
        for _ in activities.indices {
            let pick = try XCTUnwrap(DailyPlanner.suggest(from: activities, skills: [], history: [], day: "today", excluding: offered))
            XCTAssertTrue(offered.insert(pick.id).inserted)
        }
        XCTAssertNil(DailyPlanner.suggest(from: activities, skills: [], history: [], day: "today", excluding: offered))
    }

    func testStateRoundTripKeepsSkillsPlansNotesAndMemories() throws {
        var state = FamilyState()
        state.profile.youngerName = "Younger"
        state.profile.skills = [.making, .music]
        state.profile.hasChosenSkills = true
        state.plans = [DailyPlan(day: "2026-10-22", activityID: "paper-bridges", offeredIDs: ["paper-bridges"])]
        state.teachingNotes["paper-bridges"] = "Tell them about fixing our garden bench."
        state.memories = [Memory(activityID: "paper-bridges", note: "He folded a zigzag!", favourite: true)]
        XCTAssertEqual(try FamilyState.decode(state.encoded()), state)
    }

    func testInvalidSavedDataThrowsRatherThanSilentlyErasingIt() {
        XCTAssertThrowsError(try FamilyState.decode(Data("not json".utf8)))
    }

    func testDayChangesAtLocalMidnightIncludingDaylightSaving() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Europe/London"))
        let formatter = ISO8601DateFormatter()
        let before = try XCTUnwrap(formatter.date(from: "2026-10-22T22:59:00Z"))
        let after = try XCTUnwrap(formatter.date(from: "2026-10-22T23:01:00Z"))
        XCTAssertEqual(DailyPlanner.dayKey(for: before, calendar: calendar), "2026-10-22")
        XCTAssertEqual(DailyPlanner.dayKey(for: after, calendar: calendar), "2026-10-23")
    }
}
