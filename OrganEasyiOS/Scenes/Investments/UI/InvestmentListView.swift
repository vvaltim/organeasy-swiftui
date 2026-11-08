import Combine
import SwiftUI

@MainActor
final class InvestmentListModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded
        case failed
    }

    @Published private(set) var state = State.loading
    @Published private(set) var ranked: [RankedAsset] = []
    @Published private(set) var indicators = MarketIndicators()

    func load(risk: RiskProfile, sector: InvestmentSector) async {
        state = ranked.isEmpty ? .loading : .loaded
        async let indicators = MarketDataService.shared.indicators()
        do {
            let assets = try await MarketDataService.shared.assets(for: sector)
            ranked = InvestmentRanking.rank(assets, risk: risk)
            state = .loaded
            InvestmentEvent.listViewed(sector, ranked.count).log()
        } catch {
            state = ranked.isEmpty ? .failed : .loaded
        }
        self.indicators = await indicators
    }
}

struct InvestmentListView: View {
    private enum Constants {
        static let freeLimit = 3
        static let lockedPreview = 5
    }

    let risk: RiskProfile
    let sector: InvestmentSector

    @ObservedObject private var profile = InvestorProfileStore.shared
    @ObservedObject private var store = PurchaseStore.shared
    @ObservedObject private var ads = AdsCoordinator.shared
    @StateObject private var model = InvestmentListModel()

    @State private var filters = InvestmentFilters()
    @State private var selected: RankedAsset?
    @State private var paywallSource: PaywallSource?
    @State private var isShowingFilters = false
    @State private var isConfirmingReset = false

    private var isBannerVisible: Bool {
        ads.canShowAds && !store.isAdsRemoved && !ShowcaseMode.isEnabled
    }

    private var items: [RankedAsset] {
        store.isPremium ? InvestmentRanking.apply(filters, to: model.ranked) : model.ranked
    }

    private var visible: [RankedAsset] {
        store.isPremium ? items : Array(items.prefix(Constants.freeLimit))
    }

    private var lockedCount: Int {
        store.isPremium ? 0 : max(0, items.count - Constants.freeLimit)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Size.x12.rawValue) {
                    heroCard
                    indicatorsRow
                    sectorSelector
                    filterBar

                    switch model.state {
                    case .loading:
                        ForEach(0..<Constants.freeLimit, id: \.self) { _ in
                            InvestmentPlaceholderRow()
                        }
                    case .failed:
                        failureView
                    case .loaded:
                        list
                    }

                    disclaimer
                }
                .padding(.horizontal)
                .padding(.bottom, lockedCount > .zero ? 120 : Size.x16.rawValue)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Investimentos")
            .toolbar { toolbar }
            .overlay(alignment: .bottom) {
                if lockedCount > .zero, model.state == .loaded {
                    InvestmentUnlockBanner(lockedCount: lockedCount) {
                        openPaywall(.banner)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, Size.x8.rawValue)
                }
            }
            .refreshable { await model.load(risk: risk, sector: sector) }
            .safeAreaInset(edge: .bottom) {
                if isBannerVisible {
                    BannerAdView()
                }
            }
        }
        .task(id: "\(risk.rawValue)-\(sector.rawValue)") {
            await store.load()
            await model.load(risk: risk, sector: sector)
        }
        .task { await ads.prepare() }
        .sheet(item: $selected) { item in
            InvestmentDetailView(item: item, isPremium: store.isPremium) {
                selected = nil
                openPaywall(.fundamentals)
            }
        }
        .sheet(item: $paywallSource) { source in
            InvestmentPaywallView(source: source, lockedCount: lockedCount)
        }
        .sheet(isPresented: $isShowingFilters) {
            InvestmentFiltersView(filters: $filters)
        }
        .confirmationDialog("Refazer seu perfil?", isPresented: $isConfirmingReset, titleVisibility: .visible) {
            Button("Refazer perfil") { profile.reset() }
            Button("Cancelar", role: .cancel) {}
        }
    }

    // MARK: - Topo

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                store.isPremium ? (isShowingFilters = true) : openPaywall(.filters)
            } label: {
                Label("Filtros", systemImage: filters.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
            }
            .accessibilityIdentifier("investFilters")

            Button {
                isConfirmingReset = true
            } label: {
                Label("Refazer perfil", systemImage: "person.crop.circle")
            }
        }
    }

    private var heroCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: Size.x4.rawValue) {
                Text("Seu perfil")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                Text(risk.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text("\(model.ranked.count) ativos analisados em \(Text(sector.title))")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.9))
            }
            Spacer()
            Image(systemName: risk.icon)
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.9))
        }
        .padding()
        .background(
            LinearGradient(colors: [risk.tint, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }

    private var indicatorsRow: some View {
        HStack(spacing: Size.x8.rawValue) {
            indicator("Selic", model.indicators.selic)
            indicator("CDI", model.indicators.cdi)
            indicator("IPCA 12m", model.indicators.inflation)
        }
    }

    private func indicator(_ title: LocalizedStringKey, _ value: Double?) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value.map(InvestmentFormat.percent) ?? "–")
                .font(.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Size.x8.rawValue)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var sectorSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Size.x8.rawValue) {
                ForEach(InvestmentSector.allCases) { option in
                    Button {
                        guard option != sector else { return }
                        if store.isPremium {
                            profile.changeSector(option)
                        } else {
                            openPaywall(.sector)
                        }
                    } label: {
                        HStack(spacing: Size.x4.rawValue) {
                            Image(systemName: option == sector || store.isPremium ? option.icon : "lock.fill")
                                .font(.caption2)
                            Text(option.title)
                                .font(.footnote)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, Size.x12.rawValue)
                        .padding(.vertical, Size.x8.rawValue)
                        .foregroundStyle(option == sector ? .white : .primary)
                        .background(option == sector ? option.tint : Color(.secondarySystemGroupedBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .scrollClipDisabled()
    }

    // MARK: - Filtros

    /// Visível para todos; no plano grátis cada chip leva à assinatura.
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Size.x8.rawValue) {
                if store.isPremium {
                    Menu {
                        Picker("Ordenar por", selection: $filters.sort) {
                            ForEach(InvestmentFilters.Sort.allCases) { sort in
                                Text(sort.title).tag(sort)
                            }
                        }
                    } label: {
                        filterChip(icon: "arrow.up.arrow.down", isOn: filters.sort != .score) {
                            Text(filters.sort.title)
                        }
                    }
                    .accessibilityIdentifier("sortMenu")
                } else {
                    Button { openPaywall(.filters) } label: {
                        filterChip(icon: "arrow.up.arrow.down", isOn: false) {
                            Text("Ordenar por")
                        }
                    }
                    .accessibilityIdentifier("sortMenu")
                }

                toggleChip("Só com lucro", icon: "checkmark.seal", isOn: filters.onlyProfitable) {
                    filters.onlyProfitable.toggle()
                }
                toggleChip("Em alta hoje", icon: "arrow.up.right", isOn: filters.onlyRising) {
                    filters.onlyRising.toggle()
                }
                toggleChip("ROE acima de 15%", icon: "percent", isOn: filters.minimumROE >= 15) {
                    filters.minimumROE = filters.minimumROE >= 15 ? .zero : 15
                }

                if store.isPremium && filters.isActive {
                    Button("Limpar") { filters = InvestmentFilters() }
                        .font(.footnote)
                }
            }
        }
        .scrollClipDisabled()
        .onChange(of: filters) { _, value in
            InvestmentEvent.filterChanged(value.sort.rawValue).log()
        }
    }

    private func toggleChip(_ title: LocalizedStringKey, icon: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button {
            store.isPremium ? withAnimation { action() } : openPaywall(.filters)
        } label: {
            filterChip(icon: icon, isOn: isOn) { Text(title) }
        }
        .accessibilityIdentifier("filterChip")
    }

    private func filterChip<Content: View>(icon: String, isOn: Bool, @ViewBuilder title: () -> Content) -> some View {
        HStack(spacing: Size.x4.rawValue) {
            Image(systemName: store.isPremium ? icon : "lock.fill")
                .font(.caption2)
            title()
                .font(.footnote)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Size.x12.rawValue)
        .padding(.vertical, Size.x8.rawValue)
        .foregroundStyle(isOn ? .white : (store.isPremium ? .primary : .secondary))
        .background(isOn ? Color.blue : Color(.secondarySystemGroupedBackground), in: Capsule())
        .overlay { Capsule().stroke(Color(.separator).opacity(isOn ? 0 : 0.6), lineWidth: 1) }
    }

    // MARK: - Lista

    @ViewBuilder
    private var list: some View {
        if visible.isEmpty {
            ContentUnavailableView("Nenhum ativo encontrado", systemImage: "magnifyingglass", description: Text("Ajuste os filtros para ver mais opções."))
        }

        ForEach(visible) { item in
            InvestmentRow(
                item: item,
                isSaved: profile.watchlist.contains(item.asset.symbol),
                tint: sector.tint
            ) {
                InvestmentEvent.assetOpened(item.asset.symbol, item.position).log()
                selected = item
            } onSave: {
                if store.isPremium {
                    profile.toggleWatchlist(item.asset.symbol)
                } else {
                    openPaywall(.watchlist)
                }
            }
        }

        ForEach(0..<min(lockedCount, Constants.lockedPreview), id: \.self) { index in
            Button {
                openPaywall(.lockedRow)
            } label: {
                InvestmentLockedRow(position: Constants.freeLimit + index + 1, tint: sector.tint)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("lockedRow")
        }
    }

    private var failureView: some View {
        ContentUnavailableView {
            Label("Não foi possível carregar", systemImage: "wifi.exclamationmark")
        } description: {
            Text("Verifique sua conexão e tente de novo.")
        } actions: {
            Button("Tentar novamente") {
                Task { await model.load(risk: risk, sector: sector) }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var disclaimer: some View {
        Text("Ranking informativo com dados públicos. Não é recomendação de investimento. Rentabilidade passada não garante rentabilidade futura.")
            .font(.caption2)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, Size.x4.rawValue)
    }

    private func openPaywall(_ source: PaywallSource) {
        InvestmentEvent.lockedTapped(source.rawValue).log()
        paywallSource = source
    }
}
