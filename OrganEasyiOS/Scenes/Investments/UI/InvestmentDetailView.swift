import SwiftUI

struct InvestmentDetailView: View {
    let item: RankedAsset
    let isPremium: Bool
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var asset: InvestmentAsset { item.asset }
    private var fundamentals: AssetFundamentals? { asset.fundamentals }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Size.x16.rawValue) {
                    header
                    scoreCard

                    switch asset.kind {
                    case .treasury: treasurySection
                    case .stock: stockSections
                    case .fund, .crypto: marketSection
                    }

                    Text("Ranking informativo com dados públicos. Não é recomendação de investimento. Rentabilidade passada não garante rentabilidade futura.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(asset.symbol)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: Size.x12.rawValue) {
            InvestmentTile(asset: asset, tint: .blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(asset.name)
                    .font(.headline)
                Text(asset.kind == .treasury ? InvestmentFormat.treasuryRate(asset) : InvestmentFormat.money(asset.price))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
            Spacer()
            InvestmentTrendChip(trend: item.trend)
        }
    }

    private var scoreCard: some View {
        HStack(spacing: Size.x16.rawValue) {
            ZStack {
                Circle().stroke(Color(.tertiarySystemFill), lineWidth: 8)
                Circle()
                    .trim(from: .zero, to: Double(item.score) / 100)
                    .stroke(.blue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text("\(item.score)")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: Size.x4.rawValue) {
                Text("Posição \(item.position) no setor")
                    .font(.headline)
                Text("A nota compara este ativo com os outros do setor, de acordo com o seu perfil.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var marketSection: some View {
        grid("Mercado", [
            Metric("Valor de mercado", InvestmentFormat.compactMoney(asset.marketCap)),
            Metric("Volume", InvestmentFormat.compact(asset.volume)),
            Metric("Variação", InvestmentFormat.signedPercent(asset.changePercent))
        ])
    }

    @ViewBuilder
    private var stockSections: some View {
        marketSection

        if fundamentals != nil {
            grid("Fundamentos", [
                Metric("P/L", asset.priceEarnings.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "–"),
                Metric("ROE", fundamentals?.roe.map(InvestmentFormat.percent) ?? "–")
            ])

            ZStack {
                grid("Balanço", [
                    Metric("Margem líquida", fundamentals?.netMargin.map(InvestmentFormat.percent) ?? "–"),
                    Metric("Dívida sobre ativos", fundamentals?.debtToAssets.map(InvestmentFormat.percent) ?? "–"),
                    Metric("Receita", InvestmentFormat.compactMoney(fundamentals?.revenue)),
                    Metric("Lucro", InvestmentFormat.compactMoney(fundamentals?.netIncome)),
                    Metric("Patrimônio", InvestmentFormat.compactMoney(fundamentals?.equity))
                ])
                .blur(radius: isPremium ? 0 : 6)
                .allowsHitTesting(isPremium)

                if !isPremium {
                    Button(action: onUnlock) {
                        Label("Ver balanço completo", systemImage: "lock.fill")
                            .fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("unlockFundamentals")
                }
            }

            if let year = fundamentals?.year {
                Text("Balanço de \(String(year)) da CVM. Cotações da B3 via brapi.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Fundamentos indisponíveis para este ativo.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var treasurySection: some View {
        grid("Título", [
            Metric("Taxa de compra", InvestmentFormat.treasuryRate(asset)),
            Metric("Preço do título", InvestmentFormat.money(asset.price)),
            Metric("Vencimento", asset.maturity?.formatted(date: .abbreviated, time: .omitted) ?? "–")
        ])
    }

    private struct Metric: Identifiable {
        let id = UUID()
        let title: LocalizedStringKey
        let value: String

        init(_ title: LocalizedStringKey, _ value: String) {
            self.title = title
            self.value = value
        }
    }

    private func grid(_ title: LocalizedStringKey, _ metrics: [Metric]) -> some View {
        VStack(alignment: .leading, spacing: Size.x8.rawValue) {
            Text(title)
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Size.x8.rawValue) {
                ForEach(metrics) { metric in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.title)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(metric.value)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Size.x12.rawValue)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }
}
