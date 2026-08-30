import Observation
import StoreKit

@MainActor
@Observable
final class StoreManager {
    var products: [Product] = []
    var hasPlus = false
    var lastError: String?

    private let productIDs = ["com.skycircuit.plus.weekly", "com.skycircuit.plus.monthly"]
    private var observerTask: Task<Void, Never>?

    var isBetaUnlocked: Bool { Self.betaUnlocked }

    init() {
        hasPlus = Self.betaUnlocked
        guard !Self.betaUnlocked else { return }
        observerTask = Task { [weak self] in
            await self?.observeTransactions()
        }
    }

    func loadProducts() async {
        guard !Self.betaUnlocked else {
            hasPlus = true
            lastError = nil
            return
        }
        do {
            products = try await Product.products(for: productIDs)
            await refreshEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        guard !Self.betaUnlocked else {
            hasPlus = true
            return
        }
        var plus = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if productIDs.contains(transaction.productID), transaction.revocationDate == nil {
                plus = true
            }
        }
        hasPlus = plus
    }

    private func observeTransactions() async {
        for await result in Transaction.updates {
            guard !Task.isCancelled else { return }
            guard case .verified(let transaction) = result else { continue }
            await transaction.finish()
            await refreshEntitlements()
        }
    }

    private static var betaUnlocked: Bool {
#if SKYCIRCUIT_BETA
        true
#else
        false
#endif
    }
}
