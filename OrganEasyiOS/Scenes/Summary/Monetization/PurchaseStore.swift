import Combine
import Foundation
import StoreKit

enum PurchaseProductID {
    /// Assinatura anual sem desconto.
    static let yearly = "br.com.vanio.walter.app.noads.yearly"
    /// Mesmo preço anual, com oferta de introdução de 80% no primeiro ano.
    static let yearlyPromo = "br.com.vanio.walter.app.noads.yearly.promo"

    static let all: Set<String> = [yearly, yearlyPromo]
}

@MainActor
final class PurchaseStore: ObservableObject {

    enum PurchaseResult {
        case purchased
        case pending
        case cancelled
    }

    static let shared = PurchaseStore()

    @Published private(set) var products: [String: Product] = [:]
    @Published private(set) var isAdsRemoved = false

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handle(update)
            }
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func load() async {
        await refreshEntitlements()
        do {
            let loaded = try await Product.products(for: PurchaseProductID.all)
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async throws -> PurchaseResult {
        switch try await product.purchase() {
        case .success(let verification):
            await handle(verification)
            return .purchased
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    func restore() async throws {
        try await AppStore.sync()
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               PurchaseProductID.all.contains(transaction.productID),
               transaction.revocationDate == nil {
                hasEntitlement = true
            }
        }
        isAdsRemoved = hasEntitlement
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refreshEntitlements()
    }
}
