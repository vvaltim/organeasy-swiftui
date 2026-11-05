import SwiftData
import SwiftUI

struct MainTabView: View {
    var body: some View {
        tabs
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
