import Foundation

public enum AppLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"
    case japanese = "ja"
    case spanish = "es"
    case indonesian = "id"

    public var locale: Locale { Locale(identifier: rawValue) }

    /// Script takes precedence over region; unsupported preferences fall through
    /// to the next preferred language before using English.
    public static func resolve(_ preferences: [String]) -> Self {
        for preference in preferences {
            let parts = preference.replacingOccurrences(of: "_", with: "-").lowercased().split(separator: "-")
            guard let language = parts.first else { continue }
            switch language {
            case "en": return .english
            case "ja": return .japanese
            case "es": return .spanish
            case "id", "in": return .indonesian
            case "zh":
                if parts.contains("hant") { return .traditionalChinese }
                if parts.contains("hans") { return .simplifiedChinese }
                return parts.contains(where: { ["tw", "hk", "mo"].contains($0) }) ? .traditionalChinese : .simplifiedChinese
            default: continue
            }
        }
        return .english
    }

    /// Used as a model instruction, rather than translated interface copy.
    public var generationLanguage: String {
        switch self {
        case .english: "British English"
        case .simplifiedChinese: "Simplified Chinese (简体中文); use simplified characters"
        case .traditionalChinese: "Traditional Chinese (繁體中文); use traditional characters"
        case .japanese: "Japanese (日本語)"
        case .spanish: "Spanish (español)"
        case .indonesian: "Indonesian (Bahasa Indonesia)"
        }
    }
}

/// Shared by the SwiftUI app and its package so dynamic labels, errors, and
/// exports use the same language as literal interface text.
public enum L10n {
    public static var language: AppLanguage {
        AppLanguage.resolve(Bundle.main.preferredLocalizations + Locale.preferredLanguages)
    }

    private static let bundles: [AppLanguage: Bundle] = Dictionary(uniqueKeysWithValues: AppLanguage.allCases.compactMap {
        guard let url = Bundle.module.url(forResource: $0.rawValue, withExtension: "lproj"),
              let bundle = Bundle(url: url) else { return nil }
        return ($0, bundle)
    })

    public static func string(_ key: String, language: AppLanguage = language) -> String {
        let fallback = bundles[.english]?.localizedString(forKey: key, value: key, table: "Localizable") ?? key
        return bundles[language]?.localizedString(forKey: key, value: fallback, table: "Localizable") ?? fallback
    }

    /// Use positional placeholders in translations when arguments need reordering.
    public static func format(_ key: String, _ arguments: CVarArg..., language: AppLanguage = language) -> String {
        String(format: string(key, language: language), locale: language.locale, arguments: arguments)
    }

    static func resourceURL(_ name: String, extension ext: String, language: AppLanguage) -> URL? {
        bundles[language]?.url(forResource: name, withExtension: ext)
    }
}
