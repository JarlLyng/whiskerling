import XCTest
@testable import Whiskerling

/// The room and the games at any window size, and a window resized mid-game (#15).
@MainActor
final class WindowSizeTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: "whiskerling.tests.window")
        defaults.removePersistentDomain(forName: "whiskerling.tests.window")
    }

    private func makeWorld(_ size: CGSize = CGSize(width: 1032, height: 1200)) -> World {
        let sound = SoundEngine()
        sound.enabled = false
        let world = World(sound: sound)
        world.defaults = defaults // never the real cat
        world.layout(size)
        var s = SaveState(name: "Mis", coat: "orange")
        s.needs = Needs(food: 60, fun: 60, energy: 90, clean: 90)
        world.save = s
        world.isPro = true
        return world
    }

    /// Room sizes from a narrow or short window up to a large iPad on its side.
    private let sizes: [CGSize] = {
        var out: [CGSize] = []
        for w in [320, 375, 500, 600, 700, 820, 1032, 1366] as [CGFloat] {
            for h in [260, 380, 500, 700, 1024, 1300] as [CGFloat] { out.append(CGSize(width: w, height: h)) }
        }
        return out
    }()

    func testTheRoomFitsAnyWindow() {
        let world = makeWorld()
        for size in sizes {
            world.layout(size)
            let G = world.G, W = size.width, at = "\(Int(size.width))×\(Int(size.height))"
            XCTAssertLessThan(G.minX, G.maxX, "the cat has room to walk at \(at)")
            // The litter box, the bowl and the basket stay on screen and in this order, and the
            // places you tap don't overlap.
            let sL = world.objScale(G.litter.y), sB = world.objScale(G.bowl.y), sBed = world.objScale(G.bed.y)
            XCTAssertGreaterThanOrEqual(G.litter.x - 88 * sL, 0, "litter box on screen at \(at)")
            XCTAssertLessThanOrEqual(G.litter.x + 88 * sL, G.bowl.x - 60 * sB, "litter box and bowl apart at \(at)")
            XCTAssertLessThan(G.bowl.x, G.bed.x, "bowl before the basket at \(at)")
            XCTAssertLessThanOrEqual(G.bed.x + 110 * sBed, W, "basket on screen at \(at)")
            XCTAssertGreaterThanOrEqual(G.win.minX, 0, "window on screen at \(at)")
            XCTAssertLessThanOrEqual(G.clock.x + G.clockR, W, "clock on screen at \(at)")
            XCTAssertLessThan(G.win.maxX, G.clock.x - G.clockR, "window and clock apart at \(at)")
            if let pic = G.pic { XCTAssertLessThan(pic.maxX, G.clock.x - G.clockR, "picture before the clock at \(at)") }
            XCTAssertGreaterThanOrEqual(G.pond.x - G.pondRX, 0, "pond on screen at \(at)")
            XCTAssertLessThanOrEqual(G.pond.x + G.pondRX, W, "pond on screen at \(at)")
            XCTAssertLessThanOrEqual(G.tree.x, W, "tree on screen at \(at)")
        }
    }

    func testCatchTheFishCarriesOnAfterAResize() {
        let world = makeWorld()
        XCTAssertTrue(world.startFishing())
        var t: CGFloat = 0
        while world.fishing?.fish.first(where: { $0.catchable && $0.progress > 0.3 }) == nil && t < 10 {
            world.update(0.05); t += 0.05
        }
        world.layout(CGSize(width: 375, height: 500)) // the window gets small mid-leap
        let f = world.fishing!.fish.first { $0.catchable }!
        let p = world.fishPoint(f)
        XCTAssertEqual(p.x, world.G.pond.x, accuracy: world.G.pondRX, "the fish is over the pond, where it now is")
        XCTAssertLessThan(p.y, world.G.pond.y, "and above the water")
        world.tapFish(p)
        XCTAssertEqual(world.fishing?.caught, 1, "a tap where it is drawn still catches it")

        // the rest of the round plays out as usual
        while world.mode == .fish && t < 80 {
            world.update(0.05); t += 0.05
            if let f = world.fishing?.fish.first(where: { $0.catchable && $0.progress > 0.3 }) {
                world.tapFish(world.fishPoint(f))
            }
        }
        XCTAssertEqual(world.mode, .normal, "the round ends by itself")
        XCTAssertEqual(world.save?.hearts, FishGame.leaps / 3 + 1)
    }

    func testTheFeatherAndTheCatStayInsideAfterAResize() {
        let world = makeWorld()
        XCTAssertTrue(world.startPlay())
        world.pointerDown(CGPoint(x: 1000, y: 300))
        for _ in 0..<60 { world.update(1 / 60) }
        world.layout(CGSize(width: 320, height: 500))
        XCTAssertLessThanOrEqual(world.feather.x, 320 - 50, "the feather is pulled back into the room")
        XCTAssertLessThanOrEqual(world.feather.tx, 320 - 50)
        XCTAssertLessThanOrEqual(world.cat.x, world.G.maxX, "and so is the cat")
        XCTAssertEqual(world.mode, .play, "the game goes on")
        XCTAssertEqual(world.save?.name, "Mis", "the cat is the same")
    }
}
