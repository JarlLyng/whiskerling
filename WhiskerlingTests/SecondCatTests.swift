import XCTest
@testable import Whiskerling

/// A second cat (#21): adopted with Pro once the first is grown, cared for without twice the
/// chores, never removed by anything but Start over, and an old save loads as one cat.
@MainActor
final class SecondCatTests: XCTestCase {
    private let suite = "whiskerling.tests.secondcat"
    private var defaults: UserDefaults!
    private let day: TimeInterval = 86_400

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    /// A model with a cat adopted `age` days ago, every need looked after.
    private func makeModel(age: Double = 10, pro: Bool = true) -> GameModel {
        var s = SaveState(name: "Mis", coat: "orange")
        s.born = Date().addingTimeInterval(-age * day)
        s.stage = Catalog.stage(born: s.born, at: Date())
        s.grownUpParty = true
        s.birthdays = SaveState.birthdaysPassed(born: s.born, at: Date())
        s.needs = Needs(food: 80, fun: 90, energy: 90, clean: 90)
        SaveStore.save(s, to: defaults)
        let model = GameModel(defaults: defaults) // never the real cat
        model.sound.enabled = false
        model.world.layout(CGSize(width: 1032, height: 1100))
        if pro { model.store.forcePro() }
        model.proChanged()
        model.world.party = nil
        return model
    }

    private func adoptPip(_ model: GameModel) {
        model.tapAdopt()
        XCTAssertTrue(model.adopting)
        model.adopt(name: "Pip", coat: "tuxedo")
    }

    func testAnOldSaveLoadsAsOneCat() throws {
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(SaveState(name: "Mis", coat: "gray"))) as! [String: Any]
        json.removeValue(forKey: "companion")
        let old = try JSONDecoder().decode(SaveState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(old.companion)
        XCTAssertEqual(old.name, "Mis")
        XCTAssertEqual(old.litterMinutes, 240, "one cat: the litter box as before")
    }

    func testThePlusNeedsAGrownCatAndPro() {
        let kitten = makeModel(age: 1)
        XCTAssertFalse(kitten.hud.canAdopt, "a kitten is too young to look after another")
        kitten.tapAdopt()
        XCTAssertFalse(kitten.adopting)

        let noPro = makeModel(pro: false)
        XCTAssertTrue(noPro.hud.canAdopt)
        noPro.tapAdopt()
        XCTAssertEqual(noPro.adult, .paywall)
        noPro.store.forcePro()
        noPro.proChanged()
        XCTAssertNil(noPro.adult)
        XCTAssertTrue(noPro.adopting, "after buying, the start screen opens for the kitten")

        noPro.adopt(name: "Pip", coat: "tuxedo")
        XCTAssertFalse(noPro.adopting)
        XCTAssertEqual(noPro.hud.name, "Pip", "the kitten is the one shown")
        XCTAssertEqual(noPro.hud.otherName, "Mis")
        XCTAssertFalse(noPro.hud.canAdopt, "two cats at most")
        XCTAssertEqual(noPro.world.save?.stage, 0, "each grows from its own adoption date")
        XCTAssertEqual(noPro.world.save?.companion?.stage, Catalog.stages.count - 1)
    }

    func testSwitchingShowsTheOtherCatAndKeepsTheHousehold() {
        let model = makeModel()
        adoptPip(model)
        let hearts = model.world.save!.hearts
        model.world.save!.needs.fun = 33
        model.switchCats()
        XCTAssertEqual(model.hud.name, "Mis")
        XCTAssertEqual(model.hud.otherName, "Pip")
        XCTAssertEqual(model.world.save?.companion?.needs.fun, 33, "each keeps its own needs")
        XCTAssertEqual(model.world.save!.hearts, hearts, "hearts are the child's, shared")
        XCTAssertEqual(SaveStore.load(from: defaults)?.name, "Mis", "and it is saved")
    }

    func testATouchOnTheOtherCatShowsIt() {
        let model = makeModel()
        adoptPip(model)
        let w = model.world
        w.buddy.activity = .idle; w.buddy.walk = nil
        w.buddy.x = w.W * 0.3; w.buddy.y = w.G.catY
        w.cat.x = w.W * 0.7
        let head = w.buddyHeadPos()
        w.pointerDown(CGPoint(x: head.x, y: head.y + 20))
        w.pointerUp()
        model.sync()
        XCTAssertEqual(model.hud.name, "Mis")
    }

    func testLosingProKeepsBothCats() {
        let model = makeModel()
        adoptPip(model)
        model.store.forcePro(false)
        model.proChanged()
        XCTAssertNotNil(model.world.save?.companion, "a cat is never removed when Pro goes away")
        XCTAssertEqual(model.hud.otherName, "Mis")
    }

    func testOneFeedFeedsBoth() {
        let model = makeModel()
        adoptPip(model)
        let w = model.world
        w.save!.needs.food = 40; w.save!.companion!.needs.food = 40
        w.buddy.activity = .idle; w.buddy.walk = nil
        w.feed(.kibble)
        var t: CGFloat = 0
        while (w.bowl != nil || w.buddy.activity == .eat || w.cat.activity == .eat) && t < 30 { w.update(0.1); t += 0.1 }
        XCTAssertNil(w.bowl, "the bowl is put away once both have eaten")
        XCTAssertGreaterThan(w.save!.needs.food, 60)
        XCTAssertGreaterThan(w.save!.companion!.needs.food, 60, "the other cat ate too")
    }

    func testTimeAwayDoesNotDoubleTheChores() {
        var cal = Calendar.current
        cal.timeZone = .current
        let evening = cal.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        let morning = evening.addingTimeInterval(-8 * 3600) // 10:00, awake all the way
        func away(two: Bool) -> SaveState {
            var s = SaveState(name: "Mis", coat: "orange", now: morning)
            s.needs = Needs(food: 100, fun: 100, energy: 100, clean: 100)
            if two {
                var c = CatRecord(name: "Pip", coat: "tuxedo", born: morning)
                c.needs = s.needs
                s.companion = c
            }
            s.catchUp(to: evening)
            return s
        }
        let one = away(two: false), two = away(two: true)
        XCTAssertGreaterThan(two.needs.fun, one.needs.fun, "company keeps them busy")
        XCTAssertGreaterThan(two.needs.clean, one.needs.clean, "and they groom each other")
        XCTAssertEqual(two.companion!.needs.fun, two.needs.fun, accuracy: 0.001)
        XCTAssertEqual(two.needs.food, one.needs.food, accuracy: 0.001, "food is per cat, but one bowl feeds both")
        XCTAssertLessThan(two.poop, 2 * one.poop, "the box fills faster, not twice as fast")
        XCTAssertGreaterThanOrEqual(two.poop, one.poop)
    }

    func testBothSleepInTheBasket() {
        let model = makeModel()
        adoptPip(model)
        let w = model.world
        w.save!.needs.energy = 30; w.save!.companion!.needs.energy = 30
        w.toggleLights()
        var t: CGFloat = 0
        while (w.cat.activity != .sleep || w.buddy.activity != .sleep) && t < 30 { w.update(0.1); t += 0.1 }
        XCTAssertEqual(w.cat.activity, .sleep)
        XCTAssertEqual(w.buddy.activity, .sleep, "both curl up in the basket")
    }

    func testTheSpongeWashesTheCatItTouches() {
        let model = makeModel()
        adoptPip(model)
        let w = model.world
        w.save!.needs.clean = 100; w.save!.poop = 0
        w.save!.companion!.needs.clean = 30
        XCTAssertTrue(w.startWash(), "a bath, because the other cat is dirty")
        w.buddy.activity = .idle; w.buddy.walk = nil
        w.buddy.x = w.W * 0.25; w.buddy.y = w.G.catY
        let head = w.buddyHeadPos()
        w.pointerDown(head)
        for i in 0..<120 { w.pointerMove(CGPoint(x: head.x + (i % 2 == 0 ? 30 : -30), y: head.y + 40)) }
        w.pointerUp()
        XCTAssertGreaterThan(w.save!.companion!.needs.clean, 60)
    }

    func testContentCatsDoThingsTogether() {
        let model = makeModel()
        adoptPip(model)
        let w = model.world
        var seen: Set<String> = []
        for _ in 0..<2400 {
            w.save!.needs = Needs(food: 95, fun: 95, energy: 95, clean: 95)
            w.save!.companion!.needs = w.save!.needs
            w.update(0.25)
            if let tag = w.buddy.walk?.tag, ["groom", "chase", "window"].contains(tag) { seen.insert(tag) }
        }
        XCTAssertFalse(seen.isEmpty, "now and then the two do something together")
    }

    func testStartOverRemovesBoth() {
        let model = makeModel()
        adoptPip(model)
        model.startOver()
        XCTAssertNil(model.world.save)
        XCTAssertNil(SaveStore.load(from: defaults))
        XCTAssertFalse(model.hasCat)
    }

    func testTheKittenGrowsUpWithAPartyOfItsOwn() {
        let model = makeModel()
        adoptPip(model)
        model.switchCats() // the grown cat shown, the kitten the other one
        let w = model.world
        w.save!.companion!.born = Date().addingTimeInterval(-7 * day)
        w.party = nil
        w.checkBuddyStage()
        XCTAssertEqual(w.save?.companion?.stage, Catalog.stages.count - 1)
        XCTAssertEqual(w.party?.kind, .grownUp)
        XCTAssertEqual(w.save?.companion?.grownUpParty, true)
    }
}
