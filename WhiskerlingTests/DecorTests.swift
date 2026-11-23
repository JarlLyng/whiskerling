import XCTest
@testable import Whiskerling

/// Things for the living room (#18): unlocked with hearts after the crown, two free and four with
/// Pro, put up and taken away one by one, and an old save shows the room as it was.
@MainActor
final class DecorTests: XCTestCase {
    private let suite = "whiskerling.tests.decor"
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeModel(hearts: Int) -> GameModel {
        let model = GameModel(defaults: defaults) // never the real cat
        model.sound.enabled = false
        model.world.layout(CGSize(width: 1032, height: 1100))
        model.startNewCat(name: "Mis", coat: "orange")
        model.world.save!.hearts = hearts
        model.proChanged() // StoreKit's first answer: no Pro
        return model
    }

    private func decor(_ id: String) -> Decor { Catalog.decor.first { $0.id == id }! }

    func testTheyComeAfterTheCrownTwoFree() {
        let crown = Catalog.items.map(\.cost).max()!
        let costs = Catalog.decor.map(\.cost)
        XCTAssertTrue(costs.allSatisfy { $0 > crown }, "the goal goes on after the crown")
        XCTAssertEqual(costs, costs.sorted())
        XCTAssertEqual(Catalog.decor.filter(\.isFree).map(\.id), ["plant", "rug"])
        XCTAssertEqual(Set(Catalog.decor.map(\.id)).count, Catalog.decor.count)
        let names = Catalog.decor.map(\.name)
        XCTAssertEqual(Set(names).count, names.count, "each has a name of its own")
    }

    func testAnOldSaveShowsTheRoomAsItWas() throws {
        var old = SaveState(name: "Mis", coat: "orange")
        old.decor = nil
        var json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(old)) as! [String: Any]
        json.removeValue(forKey: "decor")
        let decoded = try JSONDecoder().decode(SaveState.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertNil(decoded.decor)
        let model = makeModel(hearts: 0)
        model.world.loadExisting(decoded)
        for d in Catalog.decor { XCTAssertFalse(model.world.shows(d.id)) }
    }

    func testAFreeOneNeedsItsHeartsThenComesAndGoes() {
        let poor = makeModel(hearts: 199)
        poor.choose(decor: decor("plant"))
        XCTAssertFalse(poor.world.shows("plant"), "not enough hearts yet")
        XCTAssertNil(poor.adult, "and no paywall for a free one")

        let model = makeModel(hearts: 200)
        model.choose(decor: decor("plant"))
        XCTAssertTrue(model.world.shows("plant"))
        XCTAssertEqual(SaveStore.load(from: defaults)?.decor, ["plant"], "and it is saved")
        model.choose(decor: decor("plant"))
        XCTAssertFalse(model.world.shows("plant"), "chosen again, it is taken away")
        XCTAssertEqual(model.world.save?.hearts, 200, "hearts are never spent")
    }

    func testAProOneOpensThePaywallAndIsPutUpAfterBuying() {
        let model = makeModel(hearts: 600)
        model.choose(decor: decor("lights"))
        XCTAssertEqual(model.adult, .paywall)
        XCTAssertFalse(model.world.shows("lights"))

        model.store.forcePro()
        model.proChanged()
        XCTAssertNil(model.adult, "the paywall closes by itself")
        XCTAssertTrue(model.world.shows("lights"), "and the tap is finished")
    }

    func testReachingTheHeartsSaysSoOnlyWhenItCanBeUsed() {
        let model = makeModel(hearts: 195)
        model.world.addHearts(10) // past the plant at 200
        let toasts = model.world.takeEvents().compactMap { if case .toast(let t) = $0 { t } else { nil } }
        XCTAssertTrue(toasts.contains(L10n.decorUnlocked(decor("plant").name)))

        let noPro = makeModel(hearts: 495)
        noPro.world.addHearts(10) // past the lights at 500, which need Pro
        let none = noPro.world.takeEvents().compactMap { if case .toast(let t) = $0 { t } else { nil } }
        XCTAssertFalse(none.contains(L10n.decorUnlocked(decor("lights").name)))
    }

    func testTheCarePlacesStayPut() {
        let plain = makeModel(hearts: 0).world
        let decorated = makeModel(hearts: 600)
        decorated.store.forcePro(); decorated.proChanged()
        for d in Catalog.decor { decorated.choose(decor: d) }
        let w = decorated.world
        XCTAssertEqual(Catalog.decor.filter { w.shows($0.id) }.count, Catalog.decor.count)
        XCTAssertEqual(w.G.bowl, plain.G.bowl)
        XCTAssertEqual(w.G.bed, plain.G.bed)
        XCTAssertEqual(w.G.litter, plain.G.litter)
        XCTAssertLessThan(w.plantSpot.y, w.G.catY, "the plant stands behind the cat")
        XCTAssertLessThan(w.catTreeSpot.y, w.G.catY, "and so does the cat tree")
    }
}
