import SwiftUI

struct SummaryScoreView: View {
    let score: Int

    private enum Constants {
        static let ringSize: CGFloat = 56
        static let lineWidth: CGFloat = 6
    }

    private var title: LocalizedStringKey {
        switch score {
        case 80...: "Ótimo mês"
        case 50..<80: "No caminho certo"
        default: "Vale olhar com calma"
        }
    }

    private var color: Color {
        switch score {
        case 80...: .green
        case 50..<80: .blue
        default: .orange
        }
    }

    var body: some View {
        HStack(spacing: Size.x12.rawValue) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: Constants.lineWidth)
                Circle()
                    .trim(from: .zero, to: Double(score) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: Constants.lineWidth, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(score, format: .number)
                    .font(.headline)
                    .monospacedDigit()
            }
            .frame(width: Constants.ringSize, height: Constants.ringSize)

            VStack(alignment: .leading, spacing: Size.x2.rawValue) {
                Text("Nota do mês")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.headline)
                Text("Contas em dia e saldo do mês")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    List {
        SummaryScoreView(score: 86)
    }
}
