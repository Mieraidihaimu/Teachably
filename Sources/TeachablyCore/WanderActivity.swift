import Foundation

public enum WanderActivityError: LocalizedError {
    case invalidOutput

    public var errorDescription: String? {
        L10n.string("Apple Intelligence returned an incomplete activity. Try saving this idea again.")
    }
}

public extension WanderPin {
    var libraryActivityID: String { "wander-\(snapshot.layer.id)" }

    func makeLibraryActivity(title: String, subtitle: String, skill: String, takeaway: String,
                             parentPrimer: String, materials: [String], toddler: AgePrompt, earlyYears: AgePrompt,
                             primary: AgePrompt, siblingRole: String, steps: [(title: String, instruction: String)],
                             personalPrompt: String, careNote: String) throws -> Activity {
        let identifier = skill.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let skill = Skill.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(identifier) == .orderedSame }),
              steps.count == 4, materials.count <= 8 else { throw WanderActivityError.invalidOutput }

        func checked(_ value: String, max: Int) throws -> String {
            let text = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, text.count <= max else { throw WanderActivityError.invalidOutput }
            return text
        }
        func prompt(_ value: AgePrompt) throws -> AgePrompt {
            try AgePrompt(action: checked(value.action, max: 450), question: checked(value.question, max: 200))
        }
        let items = try materials.map { try checked($0, max: 120) }
        var seen: Set<String> = []
        let uniqueItems = items.filter { seen.insert($0).inserted }
        let timedSteps = try zip(steps, [3, 5, 17, 5]).map { step, minutes in
            try ActivityStep(title: checked(step.title, max: 90), minutes: minutes,
                             instruction: checked(step.instruction, max: 600))
        }
        return try Activity(id: libraryActivityID, title: checked(title, max: 90),
                            subtitle: checked(subtitle, max: 240), skill: skill, symbol: skill.symbol,
                            takeaway: checked(takeaway, max: 260), parentPrimer: checked(parentPrimer, max: 800),
                            materials: uniqueItems, toddler: prompt(toddler), older: prompt(earlyYears), steps: timedSteps,
                            personalPrompt: checked(personalPrompt, max: 350), careNote: checked(careNote, max: 400),
                            primary: prompt(primary), siblingRole: checked(siblingRole, max: 350),
                            sourceWanderLayerID: snapshot.layer.id)
    }
}
