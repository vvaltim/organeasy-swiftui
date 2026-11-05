import SwiftData
import SwiftUI

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [MonthlyEntry]

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
            .task { LegacyDataImporter.runIfNeeded(into: modelContext) }
            .task(id: indexSignature) { await BillStore.reindex(entries) }
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
