import SwiftUI

struct BolsaDeskView: View {
    let desk: BolsaDesk
    let scale: CGFloat
    let tick: Bool
    let maxLabelWidth: CGFloat

    private var change: Double { desk.asset.changePercent ?? 0 }
    private var tint: Color { desk.isUp ? .green : .red }

    private var accessibilityText: Text {
        let amount = InvestmentFormat.percent(abs(change))
        return desk.isUp
            ? Text("\(desk.asset.symbol), alta de \(amount)")
            : Text("\(desk.asset.symbol), baixa de \(amount)")
    }

    var body: some View {
        VStack(spacing: 2) {
            label
            ZStack(alignment: .topLeading) {
                BolsaSprite(name: desk.isUp ? "bolsaDeskUp" : "bolsaDeskDown", size: CGSize(width: 48, height: 44), scale: scale)
                BolsaSprite(name: "bolsaScreenGlow", size: CGSize(width: 48, height: 44), scale: scale)
                    .opacity(tick ? 0.3 : 0)
                BolsaSprite(name: worker, size: CGSize(width: 16, height: 28), scale: scale)
                    .offset(x: 32 * scale, y: 18 * scale)
            }
            .frame(width: 48 * scale, height: 46 * scale, alignment: .topLeading)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("bolsaDesk")
    }

    private var worker: String {
        switch (desk.isUp, tick) {
        case (true, false): "bolsaWorkerUp"
        case (true, true): "bolsaWorkerUp2"
        case (false, false): "bolsaWorkerDown"
        case (false, true): "bolsaWorkerDown2"
        }
    }

    private var label: some View {
        HStack(spacing: 3) {
            Text(verbatim: desk.asset.symbol)
                .foregroundStyle(.white)
            Text(verbatim: "\(desk.isUp ? "▲" : "▼") \(InvestmentFormat.signedPercent(change))")
                .foregroundStyle(desk.isUp ? Color(red: 0.24, green: 0.86, blue: 0.52) : Color(red: 1, green: 0.42, blue: 0.45))
        }
        .font(.system(size: 11, weight: .heavy, design: .monospaced))
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(Color(red: 0.17, green: 0.17, blue: 0.23), in: RoundedRectangle(cornerRadius: 3))
        .frame(maxWidth: max(maxLabelWidth, 1))
    }
}
