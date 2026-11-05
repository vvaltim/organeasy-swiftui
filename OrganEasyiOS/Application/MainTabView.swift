import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        tabs
            .task { LegacyDataImporter.runIfNeeded(into: modelContext) }
        #if DEBUG
            .showcaseContainer()
        #endif
    }

    private var tabs: some View {
        TabView {
            Tab("Home", systemImage: Icon.listBulletRectanglePortrait.rawValue) {
                MonthlyEntryListView()
            }

            Tab("Minha IA", systemImage: SummaryIcon.brain.rawValue) {
                SummaryView()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(OrganEasyModelContainer.preview)
}
