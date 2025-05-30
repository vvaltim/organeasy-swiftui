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
            HomeView(
                viewModel: HomeViewModel(
                    repository: TransactionRepository(
                        context: persistenceController.container.viewContext
                    )
                )
            )
            .tabItem {
                Image(systemName: "house")
                Text("tab_home")
            }
            EvolutionHomeView(
                viewModel: EvolutionHomeViewModel(
                    repository: EvolutionRepository(
                        context: persistenceController.container.viewContext
                    )
                )
            )
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("tab_evolution")
            }
            SettingView(viewModel: SettingViewModel())
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
