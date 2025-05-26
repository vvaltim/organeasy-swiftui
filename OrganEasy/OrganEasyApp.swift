//
//  OrganEasyApp.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

@main
struct OrganEasyApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabBar()
                .accentColor(.indigo)
                .environment(\.locale, Locale(identifier: "pt_BR"))
        }
    }
}
