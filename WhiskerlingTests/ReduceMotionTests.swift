import XCTest
@testable import Whiskerling

/// With Reduce Motion on (#14), nothing bursts or leaps, and the games play and reward the same.
@MainActor
final class ReduceMotionTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "whiskerling.tests.motion")
        defaults.removePersistentDomain(forName: "whiskerling.tests.motion")
    }

    private func makeWorld(reduceMotion: Bool) -> World {
        let sound = SoundEngine()
        sound.enabled = false
        let world = World(sound: sound)
        world.defaults = defaults // never the real cat
        world.layout(CGSize(width: 820, height: 950))
        var s = SaveState(name: "Mis", coat: "orange")
        s.needs = Needs(food: 60, fun: 60, energy: 90, clean: 90)
        world.save = s
        world.isPro = true
        world.reduceMotion = reduceMotion
        return world
    }

    func testSparklesAndHeartsFadeInPlace() {
        let world = makeWorld(reduceMotion: true)
        world.burst(.sparkle, 400, 400, count: 20, speed: 200, life: 1, size: 9)
        XCTAssertLessThanOrEqual(world.parts.count, 5, "a few sparkles, not a burst")
        XCTAssertTrue(world.parts.allSatisfy { $0.vx == 0 && $0.vy == 0 }, "they stay where they appear")

        world.parts.removeAll()
        world.addHearts(1)
        let heart = world.parts.first { $0.kind == .heart }
        XCTAssertNotNil(heart)
        XCTAssertEqual(heart?.vx, 0, "a heart doesn't fly sideways")
        XCTAssertLessThan(abs(heart?.vy ?? 0), 25, "it only drifts up a little")
        XCTAssertEqual(world.save?.hearts, 1, "and still counts")
    }

    func testCatchTheFishPlaysTheSameWithoutLeaps() {
        let world = makeWorld(reduceMotion: true)
        XCTAssertTrue(world.startFishing())
        var t: CGFloat = 0, highest: CGFloat = 0, leaped = false
        while world.mode == .fish && t < 80 {
            world.update(0.05)
            t += 0.05
            if world.cat.jump != nil { leaped = true }
            for f in world.fishing?.fish ?? [] where f.caughtAt == nil {
                highest = max(highest, (world.G.pond.y - world.fishPoint(f).y) / world.U)
            }
            if let f = world.fishing?.fish.first(where: { $0.catchable && $0.progress > 0.3 }) {
                world.tapFish(world.fishPoint(f))
            }
        }
        XCTAssertEqual(world.mode, .normal, "the round ends by itself")
        XCTAssertEqual(world.save?.hearts, FishGame.leaps / 3 + 1, "the same hearts as with motion")
        XCTAssertFalse(leaped, "the cat hops where it stands instead of leaping after the fish")
        XCTAssertLessThan(highest, 115, "the fish rise low")
    }

    func testTheFeatherIsStillCaughtWithSmallHops() {
        let world = makeWorld(reduceMotion: true)
        XCTAssertTrue(world.startPlay())
        var highestHop: CGFloat = 0
        for _ in 0..<(60 * 30) {
            // a child holding the feather high above the cat
            let p = CGPoint(x: world.cat.x + 20, y: world.G.catY - 400 * world.U)
            world.pointerDown(p)
            world.pointerUp()
            world.update(1 / 60)
            if let j = world.cat.jump { highestHop = max(highestHop, j.h / world.U) }
        }
        XCTAssertGreaterThanOrEqual(world.feather.catches, 5, "the cat still catches the feather")
        XCTAssertLessThanOrEqual(highestHop, 36.001, "with small hops only")
    }
}
