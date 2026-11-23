import XCTest
@testable import Whiskerling

/// Hide and seek (#20): a whole round through the world in both rooms, with no way to lose, and
/// locked without Pro.
@MainActor
final class HideTests: XCTestCase {
    private let suite = "whiskerling.tests.hide"
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
        model.world.save!.needs = Needs(food: 90, fun: 60, energy: 90, clean: 90)
        if pro { model.store.forcePro() }
        model.proChanged()
        return model
    }

    /// Runs the world until the cat is hidden, then taps where it peeks out.
    private func findOnce(_ world: World, file: StaticString = #filePath, line: UInt = #line) -> String? {
        var t: CGFloat = 0
        while world.hiding?.phase != .hidden && t < 10 { world.update(0.05); t += 0.05 }
        guard let g = world.hiding, g.phase == .hidden, let spot = world.hideSpot(g.spot) else {
            XCTFail("the cat never hid", file: file, line: line); return nil
        }
        XCTAssertTrue(world.catHidden, file: file, line: line)
        world.tapHide(world.hidePoints(spot)[0])
        XCTAssertEqual(world.hiding?.phase, .found, file: file, line: line)
        XCTAssertFalse(world.catHidden, "found, it comes out", file: file, line: line)
        return spot.id
    }

    private func playARound(_ model: GameModel) {
        model.playHide()
        XCTAssertEqual(model.mode, .hide)
        let world = model.world
        let hearts = world.save!.hearts
        var spots: [String] = []
        for _ in 0..<HideGame.finds { if let id = findOnce(world) { spots.append(id) } }
        XCTAssertEqual(spots.count, HideGame.finds)
        for (a, b) in zip(spots, spots.dropFirst()) { XCTAssertNotEqual(a, b, "never the same place twice running") }
        XCTAssertGreaterThan(world.save!.hearts, hearts)
        var t: CGFloat = 0
        while world.mode == .hide && t < 10 { world.update(0.05); t += 0.05 }
        XCTAssertEqual(world.mode, .normal, "the round ends by itself")
        XCTAssertNil(world.hiding)
    }

    func testARoundInTheLivingRoom() {
        let model = makeModel()
        playARound(model)
        XCTAssertEqual(model.world.room, .living)
    }

    func testARoundInTheGarden() {
        let model = makeModel()
        model.tapRoom()
        XCTAssertEqual(model.world.room, .garden)
        playARound(model)
        XCTAssertEqual(model.world.room, .garden, "it's played where the cat is")
    }

    func testTappingElsewhereLosesNothing() {
        let model = makeModel()
        model.playHide()
        let world = model.world
        var t: CGFloat = 0
        while world.hiding?.phase != .hidden && t < 10 { world.update(0.05); t += 0.05 }
        let hearts = world.save!.hearts
        // far from every hiding place
        world.tapHide(CGPoint(x: world.W / 2, y: world.H * 0.3))
        XCTAssertEqual(world.hiding?.phase, .hidden, "the cat is still hiding, nothing else happens")
        XCTAssertEqual(world.save!.hearts, hearts)
        for _ in 0..<200 { world.update(0.05) } // waiting gives a hint, and still no end
        XCTAssertEqual(world.hiding?.phase, .hidden)
        XCTAssertEqual(world.mode, .hide)
    }

    func testStoppingBringsTheCatOut() {
        let model = makeModel()
        model.playHide()
        var t: CGFloat = 0
        while model.world.hiding?.phase != .hidden && t < 10 { model.world.update(0.05); t += 0.05 }
        model.tapDone()
        XCTAssertEqual(model.world.mode, .normal)
        XCTAssertFalse(model.world.catHidden)
        XCTAssertNotEqual(model.world.cat.activity, .hide)
    }

    func testItNeedsProAndIsPlayedAfterBuying() {
        let model = makeModel(pro: false)
        model.playHide()
        XCTAssertEqual(model.adult, .paywall)
        XCTAssertEqual(model.mode, .normal)
        model.store.forcePro()
        model.proChanged()
        XCTAssertNil(model.adult, "the paywall closes by itself")
        XCTAssertEqual(model.mode, .hide, "and the game starts")
    }

    func testEveryPlaceIsOnScreenInBothRoomsAndSizes() {
        let model = makeModel()
        let world = model.world
        for size in [CGSize(width: 1032, height: 1100), CGSize(width: 1376, height: 900), CGSize(width: 500, height: 900)] {
            world.layout(size)
            for room in [Room.living, .garden] {
                world.enterRoom(room)
                let spots = world.hideSpots()
                XCTAssertGreaterThanOrEqual(spots.count, 4)
                for spot in spots {
                    for p in world.hidePoints(spot) {
                        XCTAssertTrue(CGRect(x: 0, y: 0, width: size.width, height: size.height).contains(p),
                                      "\(spot.id) in \(room) at \(size)")
                    }
                }
            }
        }
    }
}
