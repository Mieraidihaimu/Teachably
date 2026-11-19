import Foundation

public enum IdeaConstraint: String, Codable, CaseIterable, Identifiable, Sendable {
    case zeroPrep, fifteenMinutes, outdoors, lowEnergy

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .zeroPrep: L10n.string("Zero prep")
        case .fifteenMinutes: L10n.format("%lld min", 15)
        case .outdoors: L10n.string("Outdoors")
        case .lowEnergy: L10n.string("Low energy")
        }
    }
}

extension AgePrompt {
    func extending(_ skill: Skill?, language: AppLanguage) -> AgePrompt {
        let extensionKey: String
        switch skill {
        case .numbers: extensionKey = "Make a new example with a bigger number and explain what stays the same."
        case .reading: extensionKey = "Find a second example and explain what in the words or pictures supports your idea."
        case .movement: extensionKey = "Invent a seated or gentler version and explain how you made it easier to follow."
        case .science: extensionKey = "Predict what might change in a different example, then say what you would look for to check."
        case .journaling: extensionKey = "Add details that would help someone who wasn't there picture or understand it."
        case .coding: extensionKey = "Test your instructions with a different starting choice and explain any fix you make."
        case .criticalThinking: extensionKey = "Try to find an example that challenges your first answer and decide if you would revise it."
        case .making: extensionKey = "Change one part of your design and compare how well the two versions work."
        case .nature: extensionKey = "Compare two observations and explain what evidence would help answer a new question."
        case .cooking: extensionKey = "Imagine changing the quantity or order and explain what you would need to adjust."
        case .music: extensionKey = "Make a second version with one change and ask someone to identify what you changed."
        case .storytelling: extensionKey = "Change one detail and explain how it changes what happens later."
        case nil: extensionKey = "Try a different example and explain what changed and what stayed the same."
        }
        return AgePrompt(action: action + "\n\n" + L10n.string(extensionKey, language: language), question: question)
    }
}
