import StoreKit
import SwiftUI

/// Tela de assinatura. Mostra preço, período e renovação antes da compra, como a Apple exige.
struct RemoveAdsView: View {
    let promotionEnd: Date?

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = PurchaseStore.shared
    @ObservedObject private var ads = AdsCoordinator.shared

    @State private var isWorking = false
    @State private var message: LocalizedStringKey?

    private enum LegalURL {
        static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
        static let privacy = URL(string: "https://organeasyfinancas.web.app/privacidade")!
    }

    private var isPromotionActive: Bool {
        guard let promotionEnd else { return false }
        return promotionEnd > .now
    }

    private var product: Product? {
        store.products[isPromotionActive ? PurchaseProductID.yearlyPromo : PurchaseProductID.yearly]
    }

    private var introductoryOffer: Product.SubscriptionOffer? {
        isPromotionActive ? product?.subscription?.introductoryOffer : nil
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: Size.x8.rawValue) {
                        Text("Minha IA sem anúncios")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Text("Sem banners e sem vídeos para usar sua IA.")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, Size.x4.rawValue)
                }

                Section {
                    priceView
                    purchaseButton
                } footer: {
                    if let product {
                        renewalText(for: product)
                    }
                }

                Section {
                    Button("Restaurar compras", action: restore)
                        .disabled(isWorking)

                    if ads.requiresPrivacyOptions {
                        Button("Privacidade dos anúncios") {
                            Task { await ads.showPrivacyOptions() }
                        }
                    }

                    Link("Termos de uso", destination: LegalURL.terms)
                    Link("Política de privacidade", destination: LegalURL.privacy)
                }

                if let message {
                    Section {
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Remover anúncios")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: Icon.xmark.rawValue)
                    }
                    .accessibilityLabel("Fechar")
                }
            }
            .task { await store.load() }
        }
    }

    // MARK: - Price

    @ViewBuilder
    private var priceView: some View {
        if let product {
            VStack(alignment: .leading, spacing: Size.x4.rawValue) {
                if let introductoryOffer, let promotionEnd {
                    HStack {
                        Text("80% de desconto")
                            .font(.caption)
                            .fontWeight(.semibold)

                        Spacer()

                        Text(timerInterval: Date.now...max(promotionEnd, .now), countsDown: true)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .foregroundStyle(.teal)

                    Text("\(introductoryOffer.displayPrice) no primeiro ano")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text(product.displayPrice)
                        .font(.subheadline)
                        .strikethrough()
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(product.displayPrice) por ano")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
        } else {
            ProgressView()
                .frame(maxWidth: .infinity)
        }
    }

    private var purchaseButton: some View {
        Button(action: purchase) {
            Text("Assinar")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .disabled(product == nil || isWorking || store.isAdsRemoved)
    }

    private func renewalText(for product: Product) -> Text {
        if let introductoryOffer {
            return Text("Você paga \(introductoryOffer.displayPrice) pelo primeiro ano. Depois, a assinatura renova automaticamente por \(product.displayPrice) ao ano, até ser cancelada nos Ajustes com pelo menos 24 horas de antecedência.")
        }
        return Text("A assinatura renova automaticamente por \(product.displayPrice) ao ano, até ser cancelada nos Ajustes com pelo menos 24 horas de antecedência.")
    }

    // MARK: - Functions

    private func purchase() {
        guard let product else { return }
        isWorking = true
        message = nil
        Task {
            defer { isWorking = false }
            do {
                switch try await store.purchase(product) {
                case .purchased: dismiss()
                case .pending: message = "Sua compra está aguardando aprovação."
                case .cancelled: break
                }
            } catch {
                message = "Não foi possível concluir a compra."
            }
        }
    }

    private func restore() {
        isWorking = true
        message = nil
        Task {
            defer { isWorking = false }
            do {
                try await store.restore()
                if store.isAdsRemoved {
                    dismiss()
                } else {
                    message = "Nenhuma assinatura encontrada."
                }
            } catch {
                message = "Não foi possível restaurar as compras."
            }
        }
    }
}

#Preview {
    RemoveAdsView(promotionEnd: .now.addingTimeInterval(3600))
}
