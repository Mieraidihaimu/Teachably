import Foundation

public enum DailyPlanner {
    /// A local calendar date, so the activity changes at the family's midnight.
    public static func dayKey(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year!, parts.month!, parts.day!)
    }

    public static func suggest(
        from activities: [Activity], skills: Set<Skill>, history: [DailyPlan],
        day: String, excluding: Set<String> = []
    ) -> Activity? {
        let matched = activities.filter { skills.contains($0.skill) }
        let deck = matched.isEmpty ? activities : matched
        let available = deck.filter { !excluding.contains($0.id) }
        guard !available.isEmpty else { return nil }
        // Use the most recent deck cycle. An activity is used when offered, even
        // if the family didn't complete it. Skips cannot force yesterday's pick.
        let allIDs = Set(deck.map(\.id))
        var recentIDs: Set<String> = []
        for plan in history.reversed() {
            let offered = Set(plan.offeredIDs).intersection(allIDs)
            if recentIDs.union(offered) == allIDs { break }
            recentIDs.formUnion(offered)
        }
        let fresh = available.filter { !recentIDs.contains($0.id) }
        let pool = fresh.isEmpty ? available : fresh
        // Give each selected interest a turn before offering another from an
        // already explored theme. With the family pack, seven days cover seven
        // interests, while each activity remains new through the whole deck.
        let exploredBySkill = Dictionary(grouping: deck.filter { recentIDs.contains($0.id) }, by: \.skill)
        let fewestExplored = pool.map { exploredBySkill[$0.skill]?.count ?? 0 }.min() ?? 0
        let balanced = pool.filter { (exploredBySkill[$0.skill]?.count ?? 0) == fewestExplored }
        let lastID = history.last?.activityID
        let lastSkill = activities.first { $0.id == lastID }?.skill
        return balanced.max { lhs, rhs in
            func score(_ activity: Activity) -> UInt64 {
                let variety: UInt64 = activity.skill != lastSkill ? 1_000_000 : 0
                return variety + stableHash(day + activity.id) % 1_000_000
            }
            return score(lhs) < score(rhs)
        }
    }

    private static func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(14_695_981_039_346_656_037) { ($0 ^ UInt64($1)) &* 1_099_511_628_211 }
    }
}
