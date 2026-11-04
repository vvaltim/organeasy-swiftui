import SwiftUI
import SwiftData

@main
struct OrganEasyAppiOS: App {
    var body: some Scene {
        WindowGroup {
            MonthlyEntryListView()
        }
        .modelContainer(OrganEasyModelContainer.shared)
    }
}
