import XCTest
@testable import Whiskerling

final class LocalizationTests: XCTestCase {
    private var danish: Bundle? {
        let app = Bundle(for: GameModel.self)
        return app.path(forResource: "da", ofType: "lproj").flatMap(Bundle.init(path:))
    }

    func testDanishIsInTheAppBundle() throws {
        let da = try XCTUnwrap(danish, "da.lproj is missing, so the App Store won't list Danish")
        XCTAssertEqual(da.localizedString(forKey: "action.feed", value: nil, table: nil), "Mad")
        XCTAssertEqual(da.localizedString(forKey: "pro.restore", value: nil, table: nil), "Gendan køb")
    }

    func testDanishFormatsKeepTheirPlaceholders() throws {
        let da = try XCTUnwrap(danish)
        let format = da.localizedString(forKey: "menu.info", value: nil, table: nil)
        XCTAssertEqual(String(format: format, "Mis", 3, 42), "Mis er på dag 3 og har 42 ❤️.")
    }

    func testNoEmDashesInPlayerText() throws {
        // House style: no em-dashes in anything a player reads.
        let da = try XCTUnwrap(danish)
        for key in ["hint.play", "hint.washLitter", "pro.subtitle", "pro.private.body", "food.shrimp.note"] {
            XCTAssertFalse(da.localizedString(forKey: key, value: nil, table: nil).contains("—"), key)
            XCTAssertFalse(Bundle(for: GameModel.self).localizedString(forKey: key, value: nil, table: nil).contains("—"), key)
        }
    }
}
