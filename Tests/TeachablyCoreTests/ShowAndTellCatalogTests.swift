import XCTest
@testable import TeachablyCore

final class ShowAndTellCatalogTests: XCTestCase {
    func testEveryStoryHasSixDistinctIllustrationsAndMatchingText() throws {
        let stories = try ShowAndTellCatalog.load()
        XCTAssertEqual(stories.count, 60)
        XCTAssertEqual(Set(stories.map(\.id)).count, stories.count)
        XCTAssertEqual(Set(stories.map(\.title)).count, stories.count)

        for story in stories {
            XCTAssertFalse(story.title.isEmpty, story.id)
            XCTAssertEqual(story.pictures.count, 6, story.id)
            XCTAssertEqual(Set(story.pictures.map(\.text)).count, 6, story.id)
            XCTAssertEqual(Set(story.pictures.map(\.description)).count, 6, story.id)
            let compositions = story.pictures.map { picture in
                [picture.setting.rawValue] + picture.figures.map { "\($0.position.rawValue):\($0.symbol)" }.sorted()
            }
            XCTAssertEqual(Set(compositions).count, 6, story.id)

            for picture in story.pictures {
                XCTAssertFalse(picture.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, story.id)
                XCTAssertFalse(picture.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, story.id)
                XCTAssertFalse(picture.figures.isEmpty, story.id)
                XCTAssertEqual(Set(picture.figures.map(\.position)).count, picture.figures.count, story.id)
                XCTAssertTrue(picture.figures.allSatisfy { $0.symbol.count == 1 }, story.id)
            }
        }
    }
}
