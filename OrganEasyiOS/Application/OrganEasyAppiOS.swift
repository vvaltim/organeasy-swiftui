import SwiftUI
import SwiftData

@main
struct OrganEasyAppiOS: App {
    var body: some Scene {
        WindowGroup {
            HomePage()
        }
        .modelContainer(OrganEasyModelContainer.shared)
    }
}
