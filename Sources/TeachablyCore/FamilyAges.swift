import Foundation

public enum DevelopmentalBand: String, Codable, Sendable {
    case toddler, earlyYears, primary

    public init(age: Int) {
        switch age {
        case ..<4: self = .toddler
        case 4...6: self = .earlyYears
        default: self = .primary
        }
    }

    public func title(language: AppLanguage = L10n.language) -> String {
        switch self {
        case .toddler: L10n.string("Toddler", language: language)
        case .earlyYears: L10n.string("Early years", language: language)
        case .primary: L10n.string("Primary", language: language)
        }
    }
}

public struct BirthMonth: Codable, Equatable, Sendable {
    public let year: Int
    public let month: Int

    public init?(year: Int, month: Int) {
        guard (1...9999).contains(year), (1...12).contains(month) else { return nil }
        self.year = year
        self.month = month
    }

    public static func containing(_ date: Date, timeZone: TimeZone = .current) -> Self {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month], from: date)
        return Self(year: components.year!, month: components.month!)!
    }

    public func age(on date: Date = .now, timeZone: TimeZone = .current) -> Int? {
        let current = Self.containing(date, timeZone: timeZone)
        guard (1...9999).contains(year), (1...12).contains(month),
              (year, month) <= (current.year, current.month) else { return nil }
        return current.year - year - (current.month < month ? 1 : 0)
    }
}

public struct ChildStage: Encodable, Equatable, Sendable {
    public let age: Int?
    public let band: DevelopmentalBand

    init(age: Int?, defaultBand: DevelopmentalBand) {
        self.age = age
        self.band = age.map(DevelopmentalBand.init(age:)) ?? defaultBand
    }

    public var label: String {
        age.map { L10n.format("Age %lld", $0) } ?? band.title()
    }
}

public struct FamilyStages: Encodable, Equatable, Sendable {
    public let younger: ChildStage
    public let older: ChildStage
}

public extension FamilyProfile {
    func stages(on date: Date = .now, timeZone: TimeZone = .current) -> FamilyStages {
        FamilyStages(
            younger: ChildStage(age: youngerBirthMonth?.age(on: date, timeZone: timeZone), defaultBand: .toddler),
            older: ChildStage(age: olderBirthMonth?.age(on: date, timeZone: timeZone), defaultBand: .earlyYears)
        )
    }
}
