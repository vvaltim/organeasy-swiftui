import StoreKit
import SwiftUI

enum PaywallSource: String, Identifiable {
    case banner
    case lockedRow
    case filters
    case sector
    case watchlist
    case fundamentals

    var id: String { rawValue }
}

struct InvestmentPaywallView: View {
    let source: PaywallSource
    let lockedCount: Int

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var store = PurchaseStore.shared

    @State private var selectedID = PurchaseProductID.premiumYearly
    @State private var isWorking = false
    @State private var message: LocalizedStringKey?

    private enum LegalURL {
        static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
        static let privacy = URL(string: "https://organeasyfinancas.web.app/privacidade")!
    }

    private var selected: Product? { store.products[selectedID] }

    private func displayPrice(_ id: String) -> String? {
        if let product = store.products[id] { return product.displayPrice }
        #if DEBUG
        if ShowcaseMode.isEnabled { return id == PurchaseProductID.premiumYearly ? "R$ 149,90" : "R$ 19,90" }
        #endif
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Size.x16.rawValue) {
                    header
                    benefits
                    plans
                    subscribeButton
                    legal
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK", role: .cancel) {}
            }
        }
        .task {
            InvestmentEvent.paywallViewed(source.rawValue).log()
            await store.load()
        }
    }

    private var header: some View {
        VStack(spacing: Size.x8.rawValue) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text("OrganEasy Premium")
                .font(.title)
                .fontWeight(.bold)
            Text("Compare o mercado inteiro, não só os 3 primeiros.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: Size.x12.rawValue) {
            benefit("list.number", "Ranking completo de todos os setores")
            benefit("slider.horizontal.3", "Filtros por lucro, ROE, P/L e tendência")
            benefit("doc.text.magnifyingglass", "Balanço completo de cada empresa")
            benefit("bookmark.fill", "Lista pessoal de ativos salvos")
            benefit("nosign", "Sem anúncios e sem vídeos na Minha IA")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private func benefit(_ icon: String, _ text: LocalizedStringKey) -> some View {
        Label {
            Text(text)
                .font(.subheadline)
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.blue)
        }
    }

    @ViewBuilder
    private var plans: some View {
        if displayPrice(PurchaseProductID.premiumYearly) == nil, displayPrice(PurchaseProductID.premiumMonthly) == nil {
            ProgressView()
        } else {
            VStack(spacing: Size.x8.rawValue) {
                plan(PurchaseProductID.premiumYearly, "Anual", isHighlighted: true)
                plan(PurchaseProductID.premiumMonthly, "Mensal", isHighlighted: false)
            }
        }
    }

    @ViewBuilder
    private func plan(_ id: String, _ title: LocalizedStringKey, isHighlighted: Bool) -> some View {
        if let price = displayPrice(id) {
            let isSelected = selectedID == id

            Button {
                selectedID = id
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: Size.x8.rawValue) {
                            Text(title)
                                .font(.headline)
                            if isHighlighted {
                                Text("Melhor valor")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, Size.x8.rawValue)
                                    .padding(.vertical, 2)
                                    .background(.green, in: Capsule())
                            }
                        }
                        Text(price)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? .blue : .secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14).stroke(isSelected ? .blue : .clear, lineWidth: 2)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var subscribeButton: some View {
        Button(action: subscribe) {
            Group {
                if isWorking {
                    ProgressView()
                } else {
                    Text("Assinar")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 34)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled((selected == nil && displayPrice(selectedID) == nil) || isWorking)
        .accessibilityIdentifier("premiumSubscribe")
    }

    private var legal: some View {
        VStack(spacing: Size.x8.rawValue) {
            if let price = displayPrice(selectedID) {
                let period: LocalizedStringKey = selectedID == PurchaseProductID.premiumYearly ? "ano" : "mês"
                Text("\(price) por \(Text(period)). A assinatura renova automaticamente até ser cancelada nos Ajustes, com pelo menos 24 horas de antecedência.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: Size.x16.rawValue) {
                Button("Restaurar compras", action: restore)
                Link("Termos de uso", destination: LegalURL.terms)
                Link("Política de privacidade", destination: LegalURL.privacy)
            }
            .font(.caption)
        }
    }

    private func subscribe() {
        guard let selected else { return }
        isWorking = true
        InvestmentEvent.purchaseStarted(selected.id).log()

        Task {
            defer { isWorking = false }
            do {
                if case .purchased = try await store.purchase(selected) {
                    InvestmentEvent.purchaseCompleted(selected.id).log()
                    dismiss()
                }
            } catch {
                message = "Não foi possível concluir a compra."
            }
        }
    }

    private func restore() {
        isWorking = true
        Task {
            defer { isWorking = false }
            try? await store.restore()
            if store.isPremium {
                dismiss()
            } else {
                message = "Nenhuma assinatura Premium encontrada."
            }
        }
    }
}
