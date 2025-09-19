//
//  ContentView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import FoundationModels
import SwiftUI

enum MainTabs {
    case home, evolution, settings, search
}

struct MainTabBar: View {
    
    @State var selectedTab: MainTabs = .home
    
    var intelligenceIsAvailable: Bool {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            
            if model.isAvailable {
                return true
            }
        }
        
        return false
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Início", systemImage: "house", value: .home) {
                HomeView()
            }
            
            Tab("Evolução", systemImage: "chart.line.uptrend.xyaxis", value: .evolution) {
                EvolutionHomeView()
            }
            
            Tab("Ajustes", systemImage: "gear", value: .settings) {
                SettingView()
            }
            
            if intelligenceIsAvailable {
                Tab("Apple Intelligence", systemImage: "apple.intelligence", value: .search, role: .search) {
                    IntelligenceView()
                }
            }
        }
    }
}

#Preview {
    MainTabBar()
}
