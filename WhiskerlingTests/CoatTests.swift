import XCTest
@testable import Whiskerling

/// The coats (#19): nine of them, two free, each with a name of its own, all named on the paywall.
final class CoatTests: XCTestCase {
    func testThereAreNineCoatsAndTwoAreFree() {
        XCTAssertEqual(Catalog.coats.count, 9)
        XCTAssertEqual(Catalog.coats.filter(\.isFree).map(\.id), ["orange", "gray"])
        XCTAssertEqual(Set(Catalog.coats.map(\.id)).count, Catalog.coats.count)
    }

    func testEveryCoatHasItsOwnName() {
        let names = Catalog.coats.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "a coat without a name falls back to another coat's")
    }

    func testThePaywallNamesEveryCoat() {
        let body = L10n.proCoatsBody.lowercased()
        for coat in Catalog.coats {
            XCTAssertTrue(body.contains(coat.name.lowercased()), "\(coat.name) is missing from the paywall")
        }
    }

    func testThePatternsColourTheTailEarsAndPaws() {
        let siamese = Catalog.coat("siamese"), tuxedo = Catalog.coat("tuxedo"), gray = Catalog.coat("gray")
        XCTAssertEqual(siamese.pattern, .points)
        XCTAssertEqual(siamese.tail, siamese.p2, "a pointed coat has a dark tail")
        XCTAssertEqual(siamese.ear(left: true), siamese.p2)
        XCTAssertEqual(siamese.paw, siamese.p2)
        XCTAssertEqual(tuxedo.pattern, .bicolor)
        XCTAssertEqual(tuxedo.paw, tuxedo.light, "white paws")
        XCTAssertEqual(gray.tail, gray.fur, "a plain coat is unchanged")
        XCTAssertEqual(gray.ear(left: false), gray.fur)
    }
}
