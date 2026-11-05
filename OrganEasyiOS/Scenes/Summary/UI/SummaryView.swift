import SwiftData
import SwiftUI
import UniformTypeIdentifiers

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
    @State private var isShowingFilePicker = false
    @State private var statement: Statement?
    @State private var importFailure: LocalizedStringKey?
    @State private var didOpenDebugFile = false

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
                if !ShowcaseMode.isEnabled {
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            importButton
                            ExportEntriesButton()
                        } label: {
                            Label("Importar ou exportar dados", systemImage: SummaryIcon.transfer.rawValue)
                        }
                        .accessibilityIdentifier("dataMenu")
                    }
                }

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
        .sheet(item: $statement) { statement in
            StatementImportView(statement: statement)
        }
        .fileImporter(isPresented: $isShowingFilePicker, allowedContentTypes: [.data]) { result in
            handlePickedFile(result)
        }
        .alert(
            importFailure ?? "",
            isPresented: Binding(get: { importFailure != nil }, set: { if !$0 { importFailure = nil } })
        ) {
            Button("OK", role: .cancel) {}
        }
        .task {
            await store.load()
            await ads.prepare()
        }
        .task {
            await runPromotionClock()
        }
        #if DEBUG
        .task {
            if !didOpenDebugFile, let path = ShowcaseMode.importFilePath {
                didOpenDebugFile = true
                handlePickedFile(.success(URL(filePath: path)))
            }
        }
        #endif
    }

    private var importButton: some View {
        Button {
            isShowingFilePicker = true
        } label: {
            Label("Importar extrato", systemImage: SummaryIcon.importFile.rawValue)
        }
        .accessibilityIdentifier("importStatement")
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

            if !ShowcaseMode.isEnabled {
                SummarySavingsSection(entries: entries)
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
        } actions: {
            importButton
                .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Functions

    private func handlePickedFile(_ result: Result<URL, Error>) {
        guard case .success(let url) = result else {
            importFailure = "Não foi possível abrir o arquivo."
            return
        }

        let hasAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasAccess { url.stopAccessingSecurityScopedResource() }
        }

        do {
            statement = try StatementParser.parse(Data(contentsOf: url))
        } catch StatementError.tooLarge {
            importFailure = "O arquivo é grande demais."
        } catch StatementError.legacyExcel {
            importFailure = "Este Excel é antigo (.xls). Salve como .xlsx ou baixe o extrato em OFX ou CSV."
        } catch StatementError.noTransactions {
            importFailure = "Nenhum lançamento encontrado. Tente o extrato em OFX ou CSV."
        } catch {
            importFailure = "Não foi possível ler o arquivo. Tente o extrato em OFX ou CSV."
        }
    }

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
