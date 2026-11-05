import SwiftUI

/// Oferta de 80% válida por 24 horas a partir do primeiro acesso ao Resumo.
struct SummaryPromotionBanner: View {
    let endDate: Date
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Size.x12.rawValue) {
                VStack(alignment: .leading, spacing: Size.x2.rawValue) {
                    Text("Remova os anúncios com 80% de desconto")
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                    Text("Oferta do primeiro ano, só por 24 horas")
                        .font(.caption)
                        .opacity(0.9)
                }

                Spacer(minLength: Size.x8.rawValue)

                Text(timerInterval: Date.now...max(endDate, .now), countsDown: true)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .monospacedDigit()
                    .fixedSize()
            }
            .foregroundStyle(.white)
            .padding(.vertical, Size.x4.rawValue)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.55, blue: 0.45), Color(red: 0.05, green: 0.38, blue: 0.62)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .accessibilityIdentifier("promotionBanner")
    }
}

#Preview {
    List {
        SummaryPromotionBanner(endDate: .now.addingTimeInterval(80_000)) {}
    }
}
