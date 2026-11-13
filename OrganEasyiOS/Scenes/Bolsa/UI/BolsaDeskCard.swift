import SwiftUI

struct BolsaDeskCard: View {
    let desk: BolsaDesk
    let onOpenInvestments: () -> Void

    private var asset: InvestmentAsset { desk.asset }
    private var tint: Color { desk.isUp ? .green : .red }

    var body: some View {
        VStack(spacing: Size.x16.rawValue) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Size.x4.rawValue) {
                    Text(verbatim: asset.symbol)
                        .font(.title.bold())
                    Text(verbatim: asset.name)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                BolsaSprite(name: desk.isUp ? "bolsaWorkerUp" : "bolsaWorkerDown", size: CGSize(width: 16, height: 28), scale: 2.5)
                    .accessibilityHidden(true)
            }

            HStack {
                metric("Preço", InvestmentFormat.money(asset.price))
                metric("Variação no dia", InvestmentFormat.signedPercent(asset.changePercent), tint: tint)
                metric("Volume", InvestmentFormat.compact(asset.volume))
            }

            Spacer(minLength: 0)

            Button(action: onOpenInvestments) {
                Label("Ver em Investimentos", systemImage: "chart.line.uptrend.xyaxis")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(Size.x24.rawValue)
    }

    private func metric(_ title: LocalizedStringKey, _ value: String, tint: Color = .primary) -> some View {
        VStack(alignment: .leading, spacing: Size.x4.rawValue) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(verbatim: value)
                .font(.headline)
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
