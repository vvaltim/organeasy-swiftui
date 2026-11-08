import SwiftData
import SwiftUI

struct MainTabView: View {
    private enum AppTab: Hashable {
        case home
        case assistant
        case investments
    }

    /// Quem instala agora começa em Investimentos. Quem já usava continua na Home.
    private enum FirstLaunch {
        static let key = "didOpenAppTabs"

        static func initialTab() -> AppTab {
            let isFirst = !UserDefaults.standard.bool(forKey: key)
            UserDefaults.standard.set(true, forKey: key)
            let hasLegacyData = FileManager.default.fileExists(
                atPath: LegacyDataImporter.defaultStoreURL.path(percentEncoded: false)
            )
            return isFirst && !hasLegacyData && !ShowcaseMode.isEnabled ? .investments : .home
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [MonthlyEntry]
    @State private var selectedTab = FirstLaunch.initialTab()

    /// Muda quando um lançamento entra, sai, é editado ou pago.
    private var indexSignature: Int {
        var hasher = Hasher()
        for entry in entries {
            hasher.combine(entry.id)
            hasher.combine(entry.name)
            hasher.combine(entry.amount)
            hasher.combine(entry.dueDate)
            hasher.combine(entry.paymentDate)
        }
        return hasher.finalize()
    }

    var body: some View {
        tabs
            .task {
                InvestmentFirebase.start()
                LegacyDataImporter.runIfNeeded(into: modelContext)
            }
            .task(id: indexSignature) { await BillStore.reindex(entries) }
        #if DEBUG
            .showcaseContainer()
        #endif
    }

    private var tabs: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: Icon.listBulletRectanglePortrait.rawValue, value: AppTab.home) {
                MonthlyEntryListView()
            }

            Tab("Minha IA", systemImage: SummaryIcon.brain.rawValue, value: AppTab.assistant) {
                SummaryView()
            }

            Tab("Investimentos", systemImage: "chart.line.uptrend.xyaxis", value: AppTab.investments) {
                InvestmentsView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(OrganEasyModelContainer.preview)
}
