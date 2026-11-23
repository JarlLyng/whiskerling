import XCTest
@testable import Whiskerling

/// The kitchen (#38): a third room with Pro, where a batch of fish cookies is baked from start to
/// end with no way to fail, and the cookies are given to the cat from Feed.
@MainActor
final class KitchenTests: XCTestCase {
    private let suite = "whiskerling.tests.kitchen"
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeModel(pro: Bool = true) -> GameModel {
        let model = GameModel(defaults: defaults) // never the real cat
        model.sound.enabled = false
        model.world.layout(CGSize(width: 1032, height: 1100))
        model.startNewCat(name: "Mis", coat: "orange")
        model.world.save!.needs = Needs(food: 60, fun: 70, energy: 90, clean: 90)
        if pro { model.store.forcePro() }
        model.proChanged()
        return model
    }

    /// Bakes a whole batch with plain taps, and waits for it to go into the jar.
    private func bakeABatch(_ model: GameModel) {
        let w = model.world
        XCTAssertTrue(w.startBake())
        // every tap moves it on: the middle of the board will do for every step
        let mid = CGPoint(x: w.bakeBoard.midX, y: w.bakeBoard.midY)
        var taps = 0
        while w.baking?.step != .baking && taps < 40 { w.tapBake(mid); taps += 1 }
        XCTAssertEqual(w.baking?.step, .baking, "fish, flour, a stir, six fish and the oven, all by tapping")
        var t: CGFloat = 0
        while w.mode == .bake && t < 20 { w.update(0.1); t += 0.1 }
        XCTAssertEqual(w.mode, .normal, "the baking ends by itself")
    }

    func testTheKitchenNeedsProAndIsReachedAfterBuying() {
        let model = makeModel(pro: false)
        model.tapRoom()
        XCTAssertEqual(model.overlay, .rooms)
        model.go(to: .kitchen)
        XCTAssertEqual(model.adult, .paywall)
        XCTAssertEqual(model.world.room, .living)
        model.store.forcePro()
        model.proChanged()
        XCTAssertNil(model.adult)
        XCTAssertEqual(model.world.room, .kitchen, "the move is finished after buying")
    }

    func testABatchGoesIntoTheJarAndFeedsTheCat() {
        let model = makeModel()
        model.go(to: .kitchen)
        let w = model.world
        XCTAssertEqual(w.cookieJar, 0)
        let hearts = w.save!.hearts
        bakeABatch(model)
        XCTAssertGreaterThanOrEqual(w.cookieJar, BakeGame.batch - 1, "six, or five if the cat took one")
        XCTAssertGreaterThan(w.save!.hearts, hearts)
        XCTAssertEqual(w.cat.activity, .idle, "down from the counter")
        XCTAssertEqual(w.cat.y, w.G.catY)

        model.sync()
        let jar = w.cookieJar, food = w.save!.needs.food
        model.feed(.cookie)
        XCTAssertEqual(w.room, .living, "Feed brings the cat to the bowl in the living room")
        XCTAssertEqual(w.cookieJar, jar - 1, "one out of the jar")
        var t: CGFloat = 0
        while w.bowl != nil && t < 20 { w.update(0.1); t += 0.1 }
        XCTAssertGreaterThan(w.save!.needs.food, food)
        XCTAssertEqual(SaveStore.load(from: defaults)?.cookies, w.cookieJar, "the jar is saved")
    }

    func testCookiesAreTreatsAndOnlyOfferedWhenThereAreSome() {
        let model = makeModel()
        model.sync()
        XCTAssertEqual(model.hud.cookies, 0)
        let w = model.world
        w.feed(.cookie)
        XCTAssertNil(w.bowl, "no cookies, no cookie")
        w.save!.cookies = 10
        w.save!.needs.food = 50
        for _ in 0..<3 { w.feed(.cookie); w.bowl = nil }
        XCTAssertEqual(w.cookieJar, 7)
        w.feed(.cookie)
        XCTAssertEqual(w.cookieJar, 7, "the treat limit holds for cookies too")
    }

    func testAnOldSaveLoadsWithAnEmptyJar() throws {
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(SaveState(name: "Mis", coat: "gray"))) as! [String: Any]
        json.removeValue(forKey: "cookies")
        let old = try JSONDecoder().decode(SaveState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(old.cookies)
        XCTAssertNil(old.room, "the living room")
    }

    func testTheKitchenStaysOnScreenAndAwayFromTheCareThings() {
        let model = makeModel()
        let w = model.world
        for size in [CGSize(width: 1032, height: 1100), CGSize(width: 1376, height: 900), CGSize(width: 500, height: 900)] {
            w.layout(size)
            let screen = CGRect(origin: .zero, size: size)
            XCTAssertTrue(screen.contains(w.kFridge), "the fridge at \(size)")
            XCTAssertTrue(screen.contains(w.kCounter), "the counter at \(size)")
            XCTAssertTrue(screen.contains(w.bakeBoard), "the baking board at \(size)")
            XCTAssertLessThanOrEqual(w.kCounter.maxX, w.kFridge.minX, "the fridge stands beside the counter at \(size)")
        }
    }

    func testBothCatsComeToTheKitchenAndSleepBringsThemBack() {
        let model = makeModel()
        let w = model.world
        w.save!.stage = Catalog.stages.count - 1
        w.adopt(name: "Pip", coat: "tuxedo")
        model.go(to: .kitchen)
        XCTAssertEqual(w.room, .kitchen)
        XCTAssertNotNil(w.save?.companion, "the other cat comes along")
        model.tapSleep()
        XCTAssertEqual(w.room, .living, "the basket is in the living room")
    }
}
