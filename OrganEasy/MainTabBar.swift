//
//  ContentView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct MainTabBar: View {
    var body: some View {
        TabView {
            HomeView()
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
