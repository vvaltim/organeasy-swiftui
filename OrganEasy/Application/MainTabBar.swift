//
//  ContentView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct MainTabBar: View {
    
    let persistenceController = PersistenceController.shared
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house")
                    Text("tab_home")
                }
            EvolutionHomeView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("tab_evolution")
                }
            SettingView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("tab_settings")
                }
        }
    }
}

#Preview {
    MainTabBar()
}
