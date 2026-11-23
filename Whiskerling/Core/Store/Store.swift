import Foundation
import StoreKit

/// The one-time Pro unlock (a non-consumable in-app purchase). Same shape as Walkful's store:
/// Pro is never saved by the app; it is read from StoreKit's entitlements on every launch.
@MainActor
@Observable
final class Store {
    static let proID = "com.iamjarl.whiskerling.pro"

    private(set) var proProduct: Product?
    private(set) var isPro = false
    /// False until StoreKit has been asked once. Until then `isPro` only means "not known yet".
    private(set) var entitlementChecked = false
    private(set) var isPurchasing = false
    private(set) var isLoadingProduct = false
    private(set) var loadFailed = false
    var purchaseError: String?

    @ObservationIgnored private var updates: Task<Void, Never>?

    init() {
        // Purchases that complete later (a parent approving Ask to Buy, a purchase on another
        // device in the family) and refunds arrive here. Each verified one is finished once Pro
        // reflects it, so StoreKit doesn't deliver it again on every launch.
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                await self?.refreshEntitlement()
                if case .verified(let transaction) = result {
                    await transaction.finish()
                }
            }
        }
    }

    func load() async {
        await refreshEntitlement()
        _ = await loadProduct()
    }

    @discardableResult
    func loadProduct() async -> Bool {
        if proProduct != nil { return true }
        guard !isLoadingProduct else { return false }
        isLoadingProduct = true
        defer { isLoadingProduct = false }
        do {
            proProduct = try await Product.products(for: [Store.proID]).first
        } catch {
            proProduct = nil
        }
        loadFailed = proProduct == nil
        return proProduct != nil
    }

    func purchase() async {
        if proProduct == nil { _ = await loadProduct() }
        guard let product = proProduct, !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(.verified(let transaction)):
                await transaction.finish()
                await refreshEntitlement()
            case .success(.unverified):
                purchaseError = L10n.purchaseUnverified
            case .pending:
                purchaseError = L10n.purchasePending
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = L10n.purchaseFailed
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    func refreshEntitlement() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result, transaction.productID == Store.proID, transaction.revocationDate == nil {
                pro = true
            }
        }
        isPro = pro
        entitlementChecked = true
    }

    #if DEBUG
    /// For App Store screenshots and testing only.
    func forcePro(_ on: Bool = true) { isPro = on }
    #endif
}
