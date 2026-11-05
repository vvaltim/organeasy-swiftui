import SwiftUI

/// Cartão da IA pessoal. Só aparece em aparelhos com o modelo disponível,
/// para ninguém assistir a um vídeo sem poder usar o recurso.
struct SummaryAICardView: View {
    let snapshot: SummarySnapshot
    let entries: [SummaryEntry]

    @ObservedObject private var access = SummaryAIAccess.shared
    @ObservedObject private var store = PurchaseStore.shared

    @State private var insights: MonthInsights?
    @State private var isAnalyzing = false
    @State private var hasFailed = false
    @State private var isChatOpen = false

    private var hasAccess: Bool {
        store.isAdsRemoved || access.isUnlocked
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Size.x12.rawValue) {
            Label("Sua IA pessoal", systemImage: SummaryIcon.brain.rawValue)
                .font(.headline)

            Text("Analise o mês e converse sobre suas contas. Tudo roda no seu aparelho.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            actions

            if isAnalyzing {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if hasFailed {
                Text("Não consegui analisar agora. Tente novamente.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if let insights {
                insightsView(insights)
            }
        }
        .padding(.vertical, Size.x4.rawValue)
        .navigationDestination(isPresented: $isChatOpen) {
            SummaryChatView(entries: entries)
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(alignment: .leading, spacing: Size.x8.rawValue) {
            HStack(spacing: Size.x8.rawValue) {
                Button {
                    access.perform(hasAccess: hasAccess) { analyze() }
                } label: {
                    Text("Analisar meu mês")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isAnalyzing || access.isLoadingVideo)
                .accessibilityIdentifier("analyzeMonth")

                Button {
                    access.perform(hasAccess: hasAccess) { isChatOpen = true }
                } label: {
                    Text("Conversar")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(access.isLoadingVideo)
                .accessibilityIdentifier("openChat")
            }

            SummaryVideoNotice(hasAccess: hasAccess)
        }
    }

    private func insightsView(_ insights: MonthInsights) -> some View {
        VStack(alignment: .leading, spacing: Size.x8.rawValue) {
            Text(insights.headline)
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(insights.tips, id: \.self) { tip in
                Text(tip)
                    .font(.subheadline)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("insights")
    }

    // MARK: - Functions

    private func analyze() {
        isAnalyzing = true
        hasFailed = false
        let prompt = SummaryCardPrompt.make(from: snapshot)
        let fallback = SummaryCardPrompt.calculatedInsights(from: snapshot)

        Task {
            defer { isAnalyzing = false }
            #if DEBUG
            if SummarySampleReplies.isActive {
                try? await Task.sleep(for: .seconds(1))
                insights = fallback
                return
            }
            #endif
            do {
                let generated = try await SummaryAssistant.insights(for: prompt)
                // O título vem do cálculo do app: o modelo às vezes erra o sentido do mês.
                insights = SummaryCardPrompt.isFreeOfNumbers(generated)
                    ? MonthInsights(headline: fallback.headline, tips: generated.tips)
                    : fallback
            } catch {
                insights = fallback
            }
        }
    }
}

// MARK: - Prompt

enum SummaryCardPrompt {
    static func make(from snapshot: SummarySnapshot) -> String {
        let forecast = snapshot.forecast
        let share = forecast.income > .zero ? Int(forecast.expense / forecast.income * 100) : 100

        var lines = [
            "Expenses are \(share) percent of income this month.",
            forecast.projectedBalance >= .zero ? "The month should end positive." : "The month should end negative.",
            "Bills left to pay: \(snapshot.upcoming.count).",
            "Largest expense: \(snapshot.topExpenses.first?.name ?? "none")."
        ]
        if let comparison = snapshot.comparison, comparison.difference != .zero {
            lines.append("Compared to last month, expenses went \(comparison.difference > .zero ? "up" : "down").")
        }
        return lines.joined(separator: "\n")
    }

    static func isFreeOfNumbers(_ insights: MonthInsights) -> Bool {
        !([insights.headline] + insights.tips).contains { $0.contains(where: \.isNumber) }
    }

    /// Observações calculadas pelo app, usadas quando o modelo escreve números ou falha.
    static func calculatedInsights(from snapshot: SummarySnapshot) -> MonthInsights {
        let forecast = snapshot.forecast
        let headline = forecast.projectedBalance >= .zero
            ? String(localized: "Seu mês está no azul.")
            : String(localized: "As saídas previstas estão acima das entradas neste mês.")

        var tips = [String(localized: "Ainda falta pagar \(forecast.pendingExpense.getLocalCurrency()) neste mês.")]

        if let top = snapshot.topExpenses.first {
            tips.append(String(localized: "\(top.name) é o maior gasto do mês, com \(top.amount.getLocalCurrency())."))
        }

        if let comparison = snapshot.comparison, comparison.difference != .zero {
            let amount = abs(comparison.difference).getLocalCurrency()
            tips.append(comparison.difference > .zero
                ? String(localized: "As saídas subiram \(amount) em relação ao mês anterior.")
                : String(localized: "As saídas caíram \(amount) em relação ao mês anterior."))
        }

        return MonthInsights(headline: headline, tips: tips)
    }
}
