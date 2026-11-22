import Combine
import Foundation
import StoreKit

enum PurchaseProductID {
    static let yearly = "br.com.vanio.walter.app.noads.yearly"
    static let yearlyPromo = "br.com.vanio.walter.app.noads.yearly.promo"

    static let premiumMonthly = "br.com.vanio.walter.app.premium.monthly"
    static let premiumYearly = "br.com.vanio.walter.app.premium.yearly"

    static let premium: Set<String> = [premiumMonthly, premiumYearly]
    static let all: Set<String> = [yearly, yearlyPromo, premiumMonthly, premiumYearly]
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
    @Published private(set) var isPremium = false

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
        guard !ShowcaseMode.isEnabled else { return }
        do {
            let loaded = try await Product.products(for: PurchaseProductID.all)
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            print("Failed to load products: \(error)")
            AppAnalytics.log("products_load_fail", ["error": AppAnalytics.error(error)])
            return
        }
        if products.isEmpty {
            AppAnalytics.log("products_load_fail", ["error": "empty"])
        }
    }

    func purchase(_ product: Product, source: String) async throws -> PurchaseResult {
        let base: [String: Any] = ["product_id": product.id, "source": source]
        AppAnalytics.log("purchase_start", base.merging([
            "price": NSDecimalNumber(decimal: product.price).doubleValue,
            "currency": product.priceFormatStyle.currencyCode
        ]) { $1 })
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified = verification else {
                    AppAnalytics.log("purchase_fail", base.merging(["error": "unverified"]) { $1 })
                    return .cancelled
                }
                await handle(verification)
                AppAnalytics.log("purchase_success", base.merging([
                    "value": NSDecimalNumber(decimal: product.price).doubleValue,
                    "currency": product.priceFormatStyle.currencyCode
                ]) { $1 })
                return .purchased
            case .pending:
                AppAnalytics.log("purchase_pending", base)
                return .pending
            case .userCancelled:
                AppAnalytics.log("purchase_cancel", base)
                return .cancelled
            @unknown default:
                return .cancelled
            }
        } catch {
            AppAnalytics.log("purchase_fail", base.merging(["error": AppAnalytics.error(error)]) { $1 })
            throw error
        }
    }

    func restore() async throws {
        AppAnalytics.log("restore_start")
        do {
            try await AppStore.sync()
        } catch {
            AppAnalytics.log("restore_fail", ["error": AppAnalytics.error(error)])
            throw error
        }
        await refreshEntitlements()
        AppAnalytics.log("restore_success", ["restored": (isAdsRemoved || isPremium) ? 1 : 0])
    }

    func refreshEntitlements() async {
        var hasEntitlement = false
        var hasPremium = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               PurchaseProductID.all.contains(transaction.productID),
               transaction.revocationDate == nil {
                hasEntitlement = true
                hasPremium = hasPremium || PurchaseProductID.premium.contains(transaction.productID)
            }
        }
        isAdsRemoved = hasEntitlement || ShowcaseMode.forcesPremium
        isPremium = hasPremium || ShowcaseMode.forcesPremium
        AppAnalytics.setPremium(isPremium)
    }

    private func handle(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { return }
        await transaction.finish()
        await refreshEntitlements()
    }
}
