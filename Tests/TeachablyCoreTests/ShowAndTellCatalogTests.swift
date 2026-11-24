import XCTest
@testable import TeachablyCore

final class ShowAndTellCatalogTests: XCTestCase {
    func testEveryStoryHasSixDistinctIllustrationsAndMatchingText() throws {
        let stories = try ShowAndTellCatalog.load()
        XCTAssertEqual(stories.count, 6)
        XCTAssertEqual(Set(stories.map(\.id)).count, stories.count)
        XCTAssertEqual(Set(stories.map(\.title)).count, stories.count)

        for story in stories {
            XCTAssertFalse(story.title.isEmpty, story.id)
            XCTAssertEqual(story.pictures.count, 6, story.id)
            XCTAssertEqual(Set(story.pictures.map(\.text)).count, 6, story.id)
            XCTAssertEqual(Set(story.pictures.map(\.description)).count, 6, story.id)
            for (index, picture) in story.pictures.enumerated() {
                XCTAssertEqual(picture.artwork, .illustration("story-\(story.id)-\(index + 1)"))
                XCTAssertFalse(picture.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, story.id)
                XCTAssertFalse(picture.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, story.id)
            }
        }
    }

    func testOriginalStoriesRetainRecordingIDsAndPictureSequences() throws {
        let classics = try ShowAndTellCatalog.load()
        let originals = try ShowAndTellCatalog.loadOriginals()
        let originalIDs = Set(originals.map(\.id))
        XCTAssertEqual(originals.count, 60)
        XCTAssertEqual(originalIDs.count, originals.count)
        XCTAssertTrue(originalIDs.contains("kite-in-the-tree"))
        XCTAssertTrue(originalIDs.isDisjoint(with: classics.map(\.id)))

        for story in originals {
            XCTAssertEqual(story.pictures.count, 6, story.id)
            for picture in story.pictures {
                guard case .symbols(_, let figures) = picture.artwork else {
                    XCTFail("Missing original artwork for \(story.id)")
                    continue
                }
                XCTAssertFalse(figures.isEmpty, story.id)
            }
        }
    }
}
