import XCTest
@testable import TeachablyCore

final class PoemCatalogTests: XCTestCase {
    func testBundledPoemsAreCompleteUniqueAndProgressByLength() throws {
        let poems = try PoemCatalog.load()
        XCTAssertEqual(poems.count, 200)
        XCTAssertEqual(Set(poems.map(\.id)).count, poems.count)
        XCTAssertEqual(Set(poems.map(\.text)).count, poems.count)
        XCTAssertTrue(poems.allSatisfy { !$0.title.isEmpty && !$0.text.isEmpty })

        let levels = Dictionary(grouping: poems, by: \.level)
        XCTAssertEqual(Set(levels.keys), Set(PoemLevel.allCases))
        let medianLengths = try PoemLevel.allCases.map { level in
            let entries = try XCTUnwrap(levels[level])
            let words = entries.map { $0.text.split(whereSeparator: \.isWhitespace).count }.sorted()
            return words[words.count / 2]
        }
        XCTAssertTrue(zip(medianLengths, medianLengths.dropFirst()).allSatisfy(<))
        XCTAssertTrue(try XCTUnwrap(levels[.zero]).allSatisfy { $0.text.split(separator: "\n").count <= 4 })

        let owl = try XCTUnwrap(poems.first { $0.id == "the-owl-and-the-pussy-cat" })
        XCTAssertEqual(owl.level, .five)
        XCTAssertEqual(owl.source, .lear)
        XCTAssertEqual(owl.text.components(separatedBy: "\n\n").count, 3)
    }

    func testSearchMatchesTitlesAndAuthorNames() throws {
        let poems = try PoemCatalog.load()
        XCTAssertEqual(PoemCatalog.search(" the SWING ", in: poems).map(\.id), ["the-swing"])
        XCTAssertEqual(PoemCatalog.search("o'clock", in: poems).map(\.id), ["eight-oclock"])
        let robert = PoemCatalog.search("robert stevenson", in: poems)
        XCTAssertFalse(robert.isEmpty)
        XCTAssertTrue(robert.allSatisfy { $0.source == .stevenson })
    }
}
