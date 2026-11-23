import StoreKitTest
import XCTest
@testable import Whiskerling

/// Buys Pro against the local StoreKit configuration (no App Store involved).
@MainActor
final class StoreTests: XCTestCase {
    private var session: SKTestSession!

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "Whiskerling")
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
    }

    func testProductLoadsWithAPrice() async {
        let store = await loadedStore()
        XCTAssertNotNil(store.proProduct)
        XCTAssertFalse(store.isPro)
    }

    func testBuyingUnlocksPro() async {
        let store = await loadedStore()
        await store.purchase()
        XCTAssertTrue(store.isPro)
        XCTAssertNil(store.purchaseError)
    }

    func testARefundLocksProAgain() async throws {
        let store = await loadedStore()
        await store.purchase()
        XCTAssertTrue(store.isPro)
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: transaction.identifier)
        // StoreKit Test hands the revocation over a moment later, as the App Store would.
        let unlocked = await waitUntil { await store.refreshEntitlement(); return !store.isPro }
        XCTAssertTrue(unlocked, "Pro should lock again after a refund")
    }

    func testAnApprovedAskToBuyUnlocksProAndIsFinished() async throws {
        session.askToBuyEnabled = true
        let store = await loadedStore()
        await store.purchase()
        XCTAssertFalse(store.isPro, "Pro waits for the parent's approval")
        XCTAssertEqual(store.purchaseError, L10n.purchasePending)

        let pending = try XCTUnwrap(session.allTransactions().first)
        try session.approveAskToBuyTransaction(identifier: pending.identifier)
        // The approval arrives through Transaction.updates, not through purchase().
        let settled = await waitUntil {
            var unfinished = 0
            for await result in Transaction.unfinished {
                if case .verified(let transaction) = result, transaction.productID == Store.proID { unfinished += 1 }
            }
            return store.isPro && unfinished == 0
        }
        XCTAssertTrue(settled, "Pro should unlock after the approval, and the transaction be finished")
    }

    // MARK: - Helpers

    /// A store with the product loaded. A simulator that has just booted can take a moment
    /// before the local StoreKit service answers, so loading is retried briefly.
    private func loadedStore() async -> Store {
        let store = Store()
        await store.load()
        _ = await waitUntil { await store.loadProduct() }
        return store
    }

    /// Checks `condition` every 0.2 s for up to 5 s.
    private func waitUntil(_ condition: () async -> Bool) async -> Bool {
        for _ in 0..<25 {
            if await condition() { return true }
            try? await Task.sleep(for: .milliseconds(200))
        }
        return false
    }
}
