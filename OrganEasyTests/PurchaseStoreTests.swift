import StoreKit
import StoreKitTest
import XCTest
@testable import OrganEasy

@MainActor
final class PurchaseStoreTests: XCTestCase {
    private var session: SKTestSession!

    override func setUp() async throws {
        session = try SKTestSession(configurationFileNamed: "OrganEasy")
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        try await Task.sleep(for: .seconds(1))
    }

    func testProductsHaveEightyPercentOffOnlyInPromo() async throws {
        let products = try await Product.products(for: PurchaseProductID.all)
        let byID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
        let full = try XCTUnwrap(byID[PurchaseProductID.yearly])
        let promo = try XCTUnwrap(byID[PurchaseProductID.yearlyPromo])
        let offer = try XCTUnwrap(promo.subscription?.introductoryOffer)

        XCTAssertNil(full.subscription?.introductoryOffer)
        XCTAssertEqual(full.price, 49.90)
        XCTAssertEqual(promo.price, 49.90)
        XCTAssertEqual(offer.price, 9.90)
    }

    func testPurchaseRemovesAdsAndCancellationBringsThemBack() async throws {
        let store = PurchaseStore()
        await store.load()
        XCTAssertFalse(store.isAdsRemoved)

        let product = try XCTUnwrap(store.products[PurchaseProductID.yearlyPromo])
        let result = try await store.purchase(product)
        guard case .purchased = result else { return XCTFail("compra não concluída") }
        XCTAssertTrue(store.isAdsRemoved)

        session.clearTransactions()
        await store.refreshEntitlements()
        XCTAssertFalse(store.isAdsRemoved)
    }
}
