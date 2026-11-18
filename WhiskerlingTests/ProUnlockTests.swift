import XCTest
@testable import Whiskerling

/// Buying Pro from a lock closes the paywall and finishes the tap the child started with (#3),
/// and the parental gate asks the small times table (#2).
@MainActor
final class ProUnlockTests: XCTestCase {
    private let suite = "whiskerling.tests.unlock"
    private var defaults: UserDefaults!

    override func setUp() {
        defaults = UserDefaults(suiteName: suite)
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeModel() -> GameModel {
        let model = GameModel(defaults: defaults) // never the real cat
        model.sound.enabled = false
        model.world.layout(CGSize(width: 820, height: 950))
        model.startNewCat(name: "Mis", coat: "orange")
        model.world.save!.needs = Needs(food: 60, fun: 60, energy: 90, clean: 90)
        model.proChanged() // StoreKit's first answer: no Pro
        return model
    }

    /// What a verified purchase or a restore does: StoreKit says Pro, and the app hears about it.
    private func buyPro(_ model: GameModel) {
        model.store.forcePro()
        model.proChanged()
    }

    private var proCoat: Coat { Catalog.coats.first { !$0.isFree }! }
    private var proItem: Item { Catalog.items.first { !$0.isFree }! }

    func testBuyingFromTheGardenButtonGoesOutside() {
        let model = makeModel()
        model.tapRoom()
        XCTAssertEqual(model.adult, .paywall)
        XCTAssertEqual(model.world.room, .living)

        buyPro(model)
        XCTAssertNil(model.adult, "the paywall closes by itself")
        XCTAssertEqual(model.world.room, .garden, "no second tap needed")
    }

    func testBuyingFromCatchTheFishStartsTheGame() {
        let model = makeModel()
        model.playFish()
        XCTAssertEqual(model.adult, .paywall)

        buyPro(model)
        XCTAssertNil(model.adult)
        XCTAssertEqual(model.mode, .fish)
        XCTAssertEqual(model.world.room, .garden, "the game is at the pond")
    }

    func testBuyingFromALockedCoatPutsItOn() {
        let model = makeModel()
        model.choose(coat: proCoat)
        XCTAssertEqual(model.adult, .paywall)
        XCTAssertEqual(model.world.save?.coat, "orange")

        buyPro(model)
        XCTAssertNil(model.adult)
        XCTAssertEqual(model.world.save?.coat, proCoat.id)
    }

    func testHeartsStillDecideAnAccessory() {
        let model = makeModel()
        model.world.save!.hearts = 0
        model.choose(item: proItem)
        buyPro(model)
        XCTAssertNil(model.adult)
        XCTAssertNotEqual(model.world.save?.wear[proItem.slot], proItem.id, "not enough hearts yet")

        let rich = makeModel()
        rich.world.save!.hearts = proItem.cost
        rich.choose(item: proItem)
        buyPro(rich)
        XCTAssertEqual(rich.world.save?.wear[proItem.slot], proItem.id)
    }

    func testBuyingFromTheStartScreenPicksTheCoat() {
        let model = makeModel()
        model.askForPro(.startCoat(proCoat.id))
        buyPro(model)
        XCTAssertNil(model.adult)
        XCTAssertEqual(model.startCoat, proCoat.id)
    }

    func testCancellingChangesNothing() {
        let model = makeModel()
        model.tapRoom()
        // Cancel at the gate, "Not now" or a swipe: the sheet closes without Pro.
        model.adult = nil
        model.adultClosed()

        buyPro(model) // e.g. bought later from the grown-ups' menu
        XCTAssertNil(model.adult)
        XCTAssertEqual(model.world.room, .living, "the old tap is not finished later")
        XCTAssertEqual(model.mode, .normal)
    }

    func testThePaywallFromTheMenuStaysOpen() {
        let model = makeModel()
        model.adult = .menu
        buyPro(model)
        XCTAssertEqual(model.adult, .menu, "the menu shows the Pro unlocked line instead")
    }

    func testTheGateAsksTheSmallTimesTable() {
        XCTAssertEqual(ParentGateView.factors, 6...9, "a quick sum for a grown-up, with a two-digit answer")
    }
}
