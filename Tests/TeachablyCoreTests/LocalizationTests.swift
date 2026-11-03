import Foundation
import XCTest
@testable import TeachablyCore

final class LocalizationTests: XCTestCase {
    private var resources: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().appendingPathComponent("Sources/TeachablyCore/Resources")
    }

    func testLanguagePreferencesRespectChineseScriptsRegionsAndFallbacks() {
        let cases: [([String], AppLanguage)] = [
            (["zh-CN"], .simplifiedChinese), (["zh-SG"], .simplifiedChinese),
            (["zh-TW"], .traditionalChinese), (["zh_HK"], .traditionalChinese),
            (["zh-MO"], .traditionalChinese), (["zh-Hans-TW"], .simplifiedChinese),
            (["zh-Hant-CN"], .traditionalChinese), (["ja-JP"], .japanese),
            (["es-MX"], .spanish), (["id-ID"], .indonesian), (["in-ID"], .indonesian),
            (["fr-FR", "es-ES", "en"], .spanish), (["de-DE"], .english), ([], .english)
        ]
        for (preferences, expected) in cases {
            XCTAssertEqual(AppLanguage.resolve(preferences), expected, "\(preferences)")
        }
    }

    func testEveryTranslationHasAllInterfaceKeysAndCompatibleFormatArguments() throws {
        func strings(_ language: AppLanguage) throws -> [String: String] {
            let url = resources.appendingPathComponent("\(language.rawValue).lproj/Localizable.strings")
            let value = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
            return try XCTUnwrap(value as? [String: String])
        }
        func placeholders(_ text: String) -> [String] {
            let regex = try! NSRegularExpression(pattern: #"%(?:\d+\$)?(?:lld|@)"#)
            return regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).map {
                String(text[Range($0.range, in: text)!]).replacingOccurrences(of: #"\d+\$"#, with: "", options: .regularExpression)
            }.sorted()
        }
        let english = try strings(.english)
        XCTAssertGreaterThan(english.count, 250)
        for language in AppLanguage.allCases {
            let translated = try strings(language)
            XCTAssertEqual(Set(translated.keys), Set(english.keys), language.rawValue)
            for (key, value) in translated {
                XCTAssertFalse(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(language): \(key)")
                XCTAssertEqual(placeholders(key), placeholders(value), "\(language): \(key)")
                XCTAssertEqual(L10n.string(key, language: language), value, "Bundle lookup: \(language): \(key)")
            }
        }
        XCTAssertEqual(L10n.string("An unknown future key", language: .japanese), "An unknown future key")
        XCTAssertFalse(L10n.format("Step %lld of %lld", 2, 4, language: .japanese).contains("%"))
        XCTAssertFalse(L10n.format("Found: %@", "自分のメモ", language: .japanese).contains("%@"))
    }

    func testAllActivityTranslationsPreserveIdentityTimingAndSavedReferences() throws {
        let english = try ActivityCatalog.load(language: .english)
        XCTAssertEqual(english.count, 67)
        for language in AppLanguage.allCases where language != .english {
            let file = resources.appendingPathComponent("\(language.rawValue).lproj/activities.json")
            let onDisk = try JSONDecoder().decode([Activity].self, from: Data(contentsOf: file))
            let activities = try ActivityCatalog.load(language: language)
            XCTAssertEqual(activities, onDisk, "Must load the actual \(language.rawValue) bundle resource")
            XCTAssertEqual(activities.map(\.id), english.map(\.id))
            for (source, translated) in zip(english, activities) {
                XCTAssertEqual(translated.skill, source.skill)
                XCTAssertEqual(translated.symbol, source.symbol)
                XCTAssertEqual(translated.steps.map(\.minutes), source.steps.map(\.minutes))
                XCTAssertEqual(translated.materials.count, source.materials.count)
                XCTAssertNotEqual(translated.title, source.title, "\(language): \(source.id)")
                let text = [translated.title, translated.subtitle, translated.takeaway, translated.parentPrimer,
                    translated.toddler.action, translated.toddler.question, translated.older.action, translated.older.question,
                    translated.personalPrompt, translated.careNote] + translated.materials
                    + translated.steps.flatMap { [$0.title, $0.instruction] }
                XCTAssertTrue(text.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
            }
            let pick = DailyPlanner.suggest(from: activities, skills: Skill.familyInterests, history: [], day: "2026-10-24")
            let originalPick = DailyPlanner.suggest(from: english, skills: Skill.familyInterests, history: [], day: "2026-10-24")
            XCTAssertEqual(pick?.id, originalPick?.id)
        }
        var state = FamilyState()
        state.profile.youngerName = "小明"
        state.teachingNotes[english[0].id] = "Our note stays exactly as written."
        state.memories = [Memory(activityID: english[0].id, note: "大好き", favourite: true)]
        let restored = try FamilyState.decode(state.encoded())
        XCTAssertEqual(restored, state)
        XCTAssertEqual(restored.profile.youngerDisplayName, "小明")
    }

    func testTranslatedWanderCatalogsSearchAndGenerateInTheirOwnLanguage() throws {
        var identities = Set<String>()
        for language in AppLanguage.allCases {
            let catalog = WanderCatalog(activities: try ActivityCatalog.load(language: language), interests: [.numbers], language: language)
            identities.insert(catalog.identity)
            var engine = WanderEngine(catalog: catalog)
            let root = try engine.explore(WanderRequest(action: .root))
            let bubble = try XCTUnwrap(root.bubbles.first)
            XCTAssertEqual(bubble.label, Skill.numbers.title(language: language))
            let map = try engine.explore(WanderRequest(action: .expand, parentID: root.id, bubbleID: bubble.id))
            let activity = try XCTUnwrap(map.bubbles.first)
            let hits = try engine.search(activity.label)
            XCTAssertTrue(hits.contains { $0.bubbleID == activity.id && $0.isExact })
            XCTAssertEqual(try catalog.resolve(activity.label, near: map.nodeID), activity.targetID)
            let plan = try engine.prepareGeneration(WanderRequest(action: .explain, parentID: map.id), providerID: "test/\(language.rawValue)")
            let context = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(plan.contextJSON.utf8)) as? [String: Any])
            XCTAssertEqual(context["outputLanguage"] as? String, language.generationLanguage)
        }
        XCTAssertEqual(identities.count, AppLanguage.allCases.count)
        let emptyEnglish = WanderCatalog(activities: [], interests: [], language: .english)
        let emptySpanish = WanderCatalog(activities: [], interests: [], language: .spanish)
        XCTAssertNotEqual(emptyEnglish.identity, emptySpanish.identity)
    }

    func testWanderCommandsRecognizeAllSupportedLanguages() {
        for query in ["解释影子", "請解釋影子", "影子是什么？", "影子是什麼？", "なぜ影ができる", "説明して", "影を説明して", "影について教えて", "影とは何ですか", "Explícame las sombras", "¿Qué es la gravedad?", "Que es la gravedad", "Jelaskan bayangan", "Apa itu gravitasi"] {
            XCTAssertTrue(WanderEngine.requestsExplanation(query), query)
        }
        for (query, expected) in [("find shadows", "shadows"), ("查找：影子", "影子"), ("搜尋 影子", "影子"),
                                  ("検索：影", "影"), ("Buscar sombras", "sombras"), ("cari bayangan", "bayangan")] {
            XCTAssertEqual(WanderQuery.recallQuery(in: query), expected)
        }
        XCTAssertNil(WanderQuery.recallQuery(in: "finding shadows"))
        XCTAssertNil(WanderQuery.recallQuery(in: "cari "))
    }

    func testMultilingualQuestionWordsDoNotResolveUnrelatedLibraryTopics() throws {
        let catalog = WanderCatalog(activities: try ActivityCatalog.load(language: .english), interests: [])
        var engine = WanderEngine(catalog: catalog)
        let root = try engine.explore(WanderRequest(action: .root))
        let state = engine.state
        for query in ["¿Qué es la zzzunknownthing?", "Apa itu zzzunknownthing", "请解释 zzzunknownthing", "zzzunknownthing とは何ですか"] {
            XCTAssertThrowsError(try engine.explore(WanderRequest(action: .refine, parentID: root.id, query: query))) {
                XCTAssertEqual($0 as? WanderError, .unknownTopic, query)
            }
            XCTAssertEqual(engine.state, state)
        }
    }

    func testLocalSearchAliasesFindTheIntendedInterest() throws {
        let examples: [(AppLanguage, Skill, String)] = [
            (.simplifiedChinese, .reading, "读书"), (.traditionalChinese, .reading, "讀書"),
            (.japanese, .reading, "読書"), (.japanese, .movement, "運動"),
            (.spanish, .reading, "lectura"), (.spanish, .movement, "gimnasia"),
            (.indonesian, .reading, "bacaan"), (.indonesian, .movement, "senam")
        ]
        for (language, skill, query) in examples {
            let catalog = WanderCatalog(activities: try ActivityCatalog.load(language: language), interests: [], language: language)
            let result = try catalog.resolve(query, near: "root")
            XCTAssertEqual(try catalog.node(result).skill, skill, "\(language): \(query)")
        }
    }
}
