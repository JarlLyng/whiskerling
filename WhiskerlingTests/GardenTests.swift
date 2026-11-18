import XCTest
@testable import Whiskerling

/// The garden and Catch the fish, played through the world without drawing anything.
@MainActor
final class GardenTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "whiskerling.tests.garden")
        defaults.removePersistentDomain(forName: "whiskerling.tests.garden")
    }

    private func makeWorld(pro: Bool) -> World {
        let sound = SoundEngine()
        sound.enabled = false
        let world = World(sound: sound)
        world.defaults = defaults // never the real cat
        world.layout(CGSize(width: 820, height: 950))
        var s = SaveState(name: "Mis", coat: "orange")
        s.needs = Needs(food: 60, fun: 60, energy: 90, clean: 90)
        world.save = s
        world.isPro = pro
        return world
    }

    func testTheGardenNeedsPro() {
        let free = makeWorld(pro: false)
        XCTAssertFalse(free.goOutside())
        XCTAssertEqual(free.room, .living)
        XCTAssertFalse(free.startFishing())

        let pro = makeWorld(pro: true)
        XCTAssertTrue(pro.goOutside())
        XCTAssertEqual(pro.room, .garden)
        XCTAssertEqual(pro.save?.room, "garden", "the room is saved")
    }

    func testFoodAndBedAreIndoors() {
        let world = makeWorld(pro: true)
        world.goOutside()
        world.feed(.kibble)
        XCTAssertEqual(world.room, .living, "the bowl is indoors")

        world.goOutside()
        world.toggleLights()
        XCTAssertEqual(world.room, .living, "the basket is indoors")
        XCTAssertEqual(world.save?.lightsOff, true)
    }

    func testCatchingEveryFishGivesHeartsAndEndsTheRound() {
        let world = makeWorld(pro: true)
        XCTAssertTrue(world.startFishing())
        XCTAssertEqual(world.room, .garden, "the game is at the garden pond")
        XCTAssertEqual(world.mode, .fish)

        var t: CGFloat = 0
        while world.mode == .fish && t < 60 {
            world.update(0.05)
            t += 0.05
            if let f = world.fishing?.fish.first(where: { $0.catchable && $0.progress > 0.3 }) {
                world.tapFish(world.fishPoint(f))
            }
        }
        XCTAssertEqual(world.mode, .normal, "the round ends by itself")
        XCTAssertNil(world.fishing)
        // one heart for every third fish, and one more for catching all of them
        XCTAssertEqual(world.save?.hearts, FishGame.leaps / 3 + 1)
        XCTAssertGreaterThan(world.save!.needs.fun, 60)
    }

    func testMissedFishAreFine() {
        let world = makeWorld(pro: true)
        world.startFishing()
        var t: CGFloat = 0
        while world.mode == .fish && t < 60 { world.update(0.05); t += 0.05 }
        XCTAssertEqual(world.mode, .normal, "nobody loses: the round just ends")
        XCTAssertEqual(world.save?.hearts, 0)
    }

    /// The cat follows the leaping fish in one smooth walk, without stepping and stopping (#4).
    /// A fish drifts slowly, so a cat that only moves once it is a few points behind walks in
    /// jerks: stand, step, stand. That showed as a stutter on a real iPad at 120 frames a second.
    func testTheCatGlidesAfterTheFish() {
        let world = makeWorld(pro: true)
        world.startFishing()
        let dt: CGFloat = 1 / 120
        var starts = 0, frames = 0, wasMoving = false
        var lastX = world.cat.x, lastStep: CGFloat = 0, maxJerk: CGFloat = 0
        while world.mode == .fish && frames < 120 * 60 {
            world.update(dt)
            frames += 1
            let step = world.cat.x - lastX
            lastX = world.cat.x
            guard world.cat.jump == nil else { wasMoving = false; lastStep = step; continue }
            if world.cat.moving && !wasMoving { starts += 1 }
            wasMoving = world.cat.moving
            maxJerk = max(maxJerk, abs(step - lastStep) / world.U)
            lastStep = step
        }
        XCTAssertEqual(world.mode, .normal, "the round ended")
        XCTAssertLessThanOrEqual(starts, FishGame.leaps * 2, "the cat starts walking about once per fish, not in steps")
        XCTAssertLessThan(maxJerk, 0.5, "the cat's speed changes gradually from frame to frame")
    }

    func testATapNextToAFishIsAMiss() {
        let world = makeWorld(pro: true)
        world.startFishing()
        var t: CGFloat = 0
        while world.fishing?.fish.first(where: { $0.catchable && $0.progress > 0.3 }) == nil && t < 10 {
            world.update(0.05); t += 0.05
        }
        let f = world.fishing!.fish.first { $0.catchable }!
        let p = world.fishPoint(f)
        world.tapFish(CGPoint(x: p.x + 300, y: p.y))
        XCTAssertEqual(world.fishing?.caught, 0)
        world.tapFish(p)
        XCTAssertEqual(world.fishing?.caught, 1)
    }

    func testLosingProBringsTheCatInside() {
        let world = makeWorld(pro: true)
        world.startFishing()
        world.isPro = false
        world.proLost()
        XCTAssertEqual(world.room, .living)
        XCTAssertEqual(world.mode, .normal)
    }

    func testSavesFromBeforeTheGardenStillLoad() throws {
        let s = SaveState(name: "Mis", coat: "gray")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as? [String: Any])
        json.removeValue(forKey: "room")
        let old = try JSONSerialization.data(withJSONObject: json)
        let loaded = try JSONDecoder().decode(SaveState.self, from: old)
        XCTAssertEqual(loaded.name, "Mis")
        XCTAssertNil(loaded.room)
    }
}
