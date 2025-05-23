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
                Text("Início")
            }
            SettingView(viewModel: SettingViewModel())
                .tabItem {
                    Image(systemName: "gear")
                    Text("Ajustes")
                }
        }
    }
}

#Preview {
    MainTabBar()
}
