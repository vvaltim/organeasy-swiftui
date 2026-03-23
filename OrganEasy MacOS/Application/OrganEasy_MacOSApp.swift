//
//  OrganEasy_MacOSApp.swift
//  OrganEasy MacOS
//
//  Created by Walter Vânio dos Reis Júnior on 18/03/26.
//

import FirebaseCore
import SwiftUI

@main
struct OrganEasy_MacOSApp: App {
    let repositoryProvider = RepositoryProvider(context: PersistenceController.shared.container.viewContext)
    @StateObject var remoteConfig = RemoteConfigManager()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            MainSidebar()
                .environmentObject(repositoryProvider)
                .environmentObject(remoteConfig)
                .accentColor(.indigo)
        }
    }
}
