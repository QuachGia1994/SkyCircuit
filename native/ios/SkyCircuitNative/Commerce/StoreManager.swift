import Observation
import StoreKit

@MainActor
@Observable
final class StoreManager {
    var products: [Product] = []
    var hasPlus = false
    var lastError: String?

    private let productIDs = ["com.skycircuit.plus.monthly", "com.skycircuit.plus.lifetime"]
    private var observerTask: Task<Void, Never>?

    init() {
        observerTask = Task { [weak self] in
            await self?.observeTransactions()
        }
    }

    func loadProducts() async {
        do {
            products = try await Product.products(for: productIDs)
            await refreshEntitlements()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
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
}
