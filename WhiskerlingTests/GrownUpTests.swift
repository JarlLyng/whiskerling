import XCTest
@testable import Whiskerling

/// The grown-up cat (#17): a party when it grows up and on each birthday, and its habits.
@MainActor
final class GrownUpTests: XCTestCase {
    private var defaults: UserDefaults!
    private let day: TimeInterval = 86_400

    override func setUp() {
        defaults = UserDefaults(suiteName: "whiskerling.tests.grownup")
        defaults.removePersistentDomain(forName: "whiskerling.tests.grownup")
    }

    private func makeWorld() -> World {
        let sound = SoundEngine()
        sound.enabled = false
        let world = World(sound: sound)
        world.defaults = defaults // never the real cat
        world.layout(CGSize(width: 1032, height: 1100))
        return world
    }

    /// A cat adopted `age` days ago, last seen now, with every need well looked after.
    private func cat(age days: Double, stage: Int, birthdays: Int? = nil) -> SaveState {
        var s = SaveState(name: "Mis", coat: "orange")
        s.born = Date().addingTimeInterval(-days * day)
        s.stage = stage
        s.birthdays = birthdays
        s.needs = Needs(food: 95, fun: 95, energy: 95, clean: 95)
        return s
    }

    // MARK: Birthdays

    func testBirthdaysAreCountedOnTheAdoptionDate() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        func d(_ y: Int, _ m: Int, _ dd: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: dd, hour: 12))! }
        let born = d(2027, 3, 10)
        XCTAssertEqual(SaveState.birthdaysPassed(born: born, at: d(2028, 3, 9), calendar: cal), 0)
        XCTAssertEqual(SaveState.birthdaysPassed(born: born, at: d(2028, 3, 10), calendar: cal), 1)
        XCTAssertEqual(SaveState.birthdaysPassed(born: born, at: d(2030, 6, 1), calendar: cal), 3)
    }

    func testTheTwentyNinthOfFebruaryCountsAsTheTwentyEighth() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        func d(_ y: Int, _ m: Int, _ dd: Int) -> Date { cal.date(from: DateComponents(year: y, month: m, day: dd, hour: 12))! }
        let born = d(2028, 2, 29)
        XCTAssertEqual(SaveState.birthdaysPassed(born: born, at: d(2029, 2, 27), calendar: cal), 0)
        XCTAssertEqual(SaveState.birthdaysPassed(born: born, at: d(2029, 2, 28), calendar: cal), 1)
        XCTAssertEqual(SaveState.birthdaysPassed(born: born, at: d(2032, 2, 28), calendar: cal), 3)
        XCTAssertEqual(SaveState.birthdaysPassed(born: born, at: d(2032, 2, 29), calendar: cal), 4, "a leap year has the real day")
    }

    // MARK: Parties

    func testGrowingUpThrowsAPartyOnTheNextVisitOnce() {
        let world = makeWorld()
        world.loadExisting(cat(age: 8, stage: 1)) // grew up while nobody was there
        XCTAssertEqual(world.save?.stage, Catalog.stages.count - 1)
        XCTAssertEqual(world.party?.kind, .grownUp, "the party waits for the next visit")
        XCTAssertEqual(world.save?.hearts, 5)

        world.party = nil
        world.loadExisting(world.save!)
        XCTAssertNil(world.party, "and only happens once")
    }

    func testABirthdayIsCelebratedOnceAlsoWhenLate() {
        let world = makeWorld()
        world.loadExisting(cat(age: 368, stage: 2)) // the birthday was three days ago
        XCTAssertEqual(world.party?.kind, .birthday(1))
        XCTAssertEqual(world.save?.birthdays, 1)
        XCTAssertEqual(world.bubble?.text, L10n.birthdayAge(1))

        world.party = nil
        world.loadExisting(world.save!)
        XCTAssertNil(world.party, "one party per birthday")
        XCTAssertEqual(world.save?.birthdays, 1)
    }

    func testAYoungCatHasNoBirthdayYet() {
        let world = makeWorld()
        world.loadExisting(cat(age: 30, stage: 2, birthdays: nil))
        XCTAssertNil(world.party)
        XCTAssertNil(world.save?.birthdays)
    }

    // MARK: Habits

    func testOnlyAGrownCatHasHabits() {
        let kitten = makeWorld()
        kitten.loadExisting(cat(age: 0.5, stage: 0))
        kitten.habitT = 0
        for _ in 0..<(4 * 300) {
            kitten.update(0.25)
            XCTAssertNotEqual(kitten.cat.activity, .nap)
            XCTAssertNotEqual(kitten.cat.activity, .stretch)
            XCTAssertNil(kitten.toy)
        }

        let grown = makeWorld()
        grown.loadExisting(cat(age: 10, stage: 2))
        grown.party = nil
        grown.habitT = 0
        var habit = false
        for _ in 0..<(4 * 300) where !habit {
            grown.update(0.25)
            habit = grown.cat.activity == .nap || grown.cat.activity == .stretch || grown.toy != nil
        }
        XCTAssertTrue(habit, "a content grown-up cat does something of its own now and then")
    }

    func testATapWakesANappingCat() {
        let world = makeWorld()
        world.loadExisting(cat(age: 10, stage: 2))
        world.cat.activity = .nap; world.cat.timer = 20
        world.tapCat()
        XCTAssertEqual(world.cat.activity, .idle)
        XCTAssertEqual(world.bubble?.text, L10n.napWake)
    }

    func testTheToyIsDroppedWhenTheErrandIsInterrupted() {
        let world = makeWorld()
        world.loadExisting(cat(age: 10, stage: 2))
        world.fetchToy()
        var t: CGFloat = 0
        while world.toy?.carried != true && t < 20 { world.update(0.1); t += 0.1 }
        XCTAssertEqual(world.toy?.carried, true, "the cat picks the yarn up")
        world.feed(.kibble) // off to the bowl instead
        world.update(0.1)
        XCTAssertEqual(world.toy?.carried, false, "it drops the yarn rather than carry it forever")
    }
}
