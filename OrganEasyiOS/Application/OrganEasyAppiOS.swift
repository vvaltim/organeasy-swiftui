import SwiftUI
import SwiftData

@main
struct OrganEasyAppiOS: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(OrganEasyModelContainer.shared)
    }
}
