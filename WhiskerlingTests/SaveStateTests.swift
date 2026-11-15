import XCTest
@testable import Whiskerling

final class SaveStateTests: XCTestCase {
    private func date(hour: Int, day: Int = 10) -> Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour))!
    }

    func testDaytimeAwayMakesTheCatHungryAndBored() {
        var s = SaveState(name: "Mis", coat: "orange", now: date(hour: 9))
        s.needs = Needs(food: 90, fun: 90, energy: 90, clean: 90)
        let away = s.catchUp(to: date(hour: 18))
        XCTAssertEqual(away, 9 * 3600, accuracy: 1)
        XCTAssertEqual(s.needs.food, 36, accuracy: 0.5)
        XCTAssertEqual(s.needs.fun, 36, accuracy: 0.5)
        XCTAssertEqual(s.needs.energy, 45, accuracy: 0.5)
        XCTAssertEqual(s.poop, 2, "a visit to the litter box every 4 awake hours")
        XCTAssertLessThan(s.needs.clean, 60)
    }

    func testTheCatSleepsAtNightAndWakesRested() {
        var s = SaveState(name: "Mis", coat: "orange", now: date(hour: 21))
        s.needs = Needs(food: 80, fun: 80, energy: 20, clean: 80)
        s.catchUp(to: date(hour: 7, day: 11))
        XCTAssertEqual(s.needs.energy, 100, accuracy: 0.01)
        XCTAssertEqual(s.needs.food, 60, accuracy: 0.5, "only 2 per hour while asleep")
        XCTAssertEqual(s.poop, 0)
    }

    func testNeedsNeverLeaveZeroToHundred() {
        var s = SaveState(name: "Mis", coat: "orange", now: date(hour: 8))
        s.catchUp(to: date(hour: 8).addingTimeInterval(10 * 86_400))
        for v in [s.needs.food, s.needs.fun, s.needs.energy, s.needs.clean] {
            XCTAssertGreaterThanOrEqual(v, 0)
            XCTAssertLessThanOrEqual(v, 100)
        }
        XCTAssertLessThanOrEqual(s.poop, 3)
    }

    func testAClockGoingBackwardsChangesNothing() {
        var s = SaveState(name: "Mis", coat: "orange", now: date(hour: 12))
        let before = s.needs
        let away = s.catchUp(to: date(hour: 10))
        XCTAssertEqual(away, 0)
        XCTAssertEqual(s.needs, before)
    }

    func testStagesGrowWithAge() {
        let born = date(hour: 12)
        XCTAssertEqual(Catalog.stage(born: born, at: born.addingTimeInterval(86_400)), 0)
        XCTAssertEqual(Catalog.stage(born: born, at: born.addingTimeInterval(3 * 86_400)), 1)
        XCTAssertEqual(Catalog.stage(born: born, at: born.addingTimeInterval(7 * 86_400)), 2)
    }

    func testSaveRoundTrip() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "whiskerling.tests"))
        defaults.removePersistentDomain(forName: "whiskerling.tests")
        var s = SaveState(name: "Pjuske", coat: "calico")
        s.hearts = 42
        s.wear.neck = "bell"
        SaveStore.save(s, to: defaults)
        XCTAssertEqual(SaveStore.load(from: defaults), s)
        SaveStore.save(nil, to: defaults)
        XCTAssertNil(SaveStore.load(from: defaults))
    }

    func testOnlyTwoCoatsAndTwoItemsAreFree() {
        XCTAssertEqual(Catalog.coats.filter(\.isFree).map(\.id), ["orange", "gray"])
        XCTAssertEqual(Catalog.items.filter(\.isFree).map(\.id), ["bow", "bell"])
    }
}
