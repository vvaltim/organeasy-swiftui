import SwiftData
import SwiftUI

struct MainTabView: View {
    private enum AppTab: Hashable {
        case home
        case assistant
        case investments
    }

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
    @State private var isPresentingNewEntry = false
    @Environment(\.scenePhase) private var scenePhase

    private var indexSignature: Int {
        var hasher = Hasher()
        for entry in entries {
            hasher.combine(entry.id)
            hasher.combine(entry.name)
            hasher.combine(entry.amount)
            hasher.combine(entry.dueDate)
            hasher.combine(entry.paymentDate)
            hasher.combine(entry.type)
            hasher.combine(entry.referenceMonth)
        }
        hasher.combine(Calendar.current.startOfDay(for: .now))
        return hasher.finalize()
    }

    var body: some View {
        tabs
            .task {
                InvestmentFirebase.start()
                LegacyDataImporter.runIfNeeded(into: modelContext)
            }
            .task(id: indexSignature) {
                WidgetSync.update(with: entries)
                await BillStore.reindex(entries)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { WidgetSync.update(with: entries) }
            }
            .onOpenURL { url in
                guard url.scheme == "organeasy" else { return }
                selectedTab = .home
                if url.host() == "nova" {
                    isPresentingNewEntry = true
                    AppAnalytics.log("widget_open", ["action": "new_entry"])
                } else {
                    AppAnalytics.log("widget_open", ["action": url.host() ?? "home"])
                }
            }
            .sheet(isPresented: $isPresentingNewEntry) {
                MonthlyEntryFormView(entryToEdit: nil)
            }
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

#Preview {
    MainTabView()
        .modelContainer(OrganEasyModelContainer.preview)
}
