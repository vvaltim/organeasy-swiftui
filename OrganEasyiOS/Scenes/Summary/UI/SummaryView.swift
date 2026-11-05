import SwiftData
import SwiftUI

struct SummaryView: View {

    // MARK: - Model Container

    @Environment(\.modelContext) private var modelContext
    @Query<MonthlyEntry> private var allEntries: [MonthlyEntry]

    // MARK: - Monetization

    @ObservedObject private var ads = AdsCoordinator.shared
    @ObservedObject private var store = PurchaseStore.shared

    // MARK: - States

    @State private var promotionEnd: Date?
    @State private var isShowingRemoveAds = false

    // MARK: - Computed Variables

    private var entries: [SummaryEntry] {
        allEntries.map(SummaryEntry.init(entry:))
    }

    private var isPromotionVisible: Bool {
        guard let promotionEnd, !store.isAdsRemoved, !ShowcaseMode.isEnabled else { return false }
        return promotionEnd > .now
    }

    private var isBannerVisible: Bool {
        ads.canShowAds && !store.isAdsRemoved && !ShowcaseMode.isEnabled
    }

    // MARK: - Main View

    var body: some View {
        NavigationStack {
            Group {
                if allEntries.isEmpty {
                    emptyView
                } else {
                    content(entries: entries)
                }
            }
            .navigationTitle("Minha IA")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !store.isAdsRemoved && !ShowcaseMode.isEnabled {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Remover anúncios") {
                            isShowingRemoveAds = true
                        }
                        .font(.subheadline)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isBannerVisible {
                    BannerAdView()
                }
            }
        }
        .sheet(isPresented: $isShowingRemoveAds) {
            RemoveAdsView(promotionEnd: promotionEnd)
        }
        .task {
            await store.load()
            await ads.prepare()
        }
        .task {
            await runPromotionClock()
        }
    }

    // MARK: - Content

    private func content(entries: [SummaryEntry]) -> some View {
        let snapshot = SummarySnapshot(entries: entries)

        return List {
            if isPromotionVisible, let promotionEnd {
                Section {
                    SummaryPromotionBanner(endDate: promotionEnd) {
                        isShowingRemoveAds = true
                    }
                }
            }

            Section {
                SummaryForecastView(
                    forecast: snapshot.forecast,
                    expensesWithoutAmount: snapshot.expensesWithoutAmount
                )
            }

            if let score = snapshot.score {
                Section {
                    SummaryScoreView(score: score)
                }
            }

            if SummaryAssistantAvailability.isAvailable {
                Section {
                    SummaryAICardView(snapshot: snapshot, entries: entries)
                }
            }

            if !snapshot.upcoming.isEmpty {
                Section("Próximos vencimentos") {
                    ForEach(snapshot.upcoming.prefix(SummarySnapshot.Constants.upcomingVisibleLimit)) { entry in
                        SummaryUpcomingRowView(entry: entry) {
                            markAsPaid(entry)
                        }
                    }

                    let hiddenCount = snapshot.upcoming.count - SummarySnapshot.Constants.upcomingVisibleLimit
                    if hiddenCount > .zero {
                        Text("E mais ^[\(hiddenCount) conta](inflect: true)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Últimos 6 meses") {
                SummaryEvolutionChartView(months: snapshot.evolution)

                if let comparison = snapshot.comparison {
                    comparisonRow(comparison)
                }
            }

            if !snapshot.topExpenses.isEmpty {
                Section("Maiores gastos do mês") {
                    ForEach(snapshot.topExpenses) { entry in
                        LabeledContent(entry.name, value: entry.amount.getLocalCurrency())
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func comparisonRow(_ comparison: SummarySnapshot.Comparison) -> some View {
        let month = comparison.previousMonth.formatted(.dateTime.month(.wide))
        let difference = abs(comparison.difference).getLocalCurrency()

        return Group {
            if comparison.difference == .zero {
                Text("Mesmo gasto de \(month)")
            } else if comparison.difference < .zero {
                Text("\(difference) a menos que em \(month)")
            } else {
                Text("\(difference) a mais que em \(month)")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    // MARK: - Empty View

    private var emptyView: some View {
        ContentUnavailableView {
            Label("Sem dados ainda", systemImage: SummaryIcon.chartBar.rawValue)
        } description: {
            Text("Adicione seus lançamentos para ver o resumo do mês.")
        }
    }

    // MARK: - Functions

    private func markAsPaid(_ entry: SummaryEntry) {
        guard let model = allEntries.first(where: { $0.id == entry.id }) else { return }
        model.paymentDate = Date()
        try? modelContext.save()
    }

    /// Inicia o prazo no primeiro acesso e tira a oferta da tela quando ele termina.
    private func runPromotionClock() async {
        if ShowcaseMode.resetsPromotion {
            PromotionClock.reset()
        }

        let end = PromotionClock.startIfNeeded().addingTimeInterval(PromotionClock.duration)
        promotionEnd = end

        guard end > .now else { return }
        try? await Task.sleep(for: .seconds(end.timeIntervalSinceNow))
        guard !Task.isCancelled else { return }
        promotionEnd = nil
        promotionEnd = end
    }
}

// MARK: - Preview

#Preview {
    SummaryView()
        .modelContainer(OrganEasyModelContainer.preview)
}
