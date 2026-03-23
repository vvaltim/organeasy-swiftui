//
//  ContentView.swift
//  OrganEasy MacOS
//
//  Created by Walter Vânio dos Reis Júnior on 18/03/26.
//

import SwiftUI

enum MainTabs: String, CaseIterable, Identifiable {
    case home = "Início"
    case evolution = "Evolução"
    case settings = "Ajustes"
    case search = "Apple Intelligence"

    var id: String { self.rawValue }
    var icon: String {
        switch self {
        case .home: return "house"
        case .evolution: return "chart.line.uptrend.xyaxis"
        case .settings: return "gear"
        case .search: return "apple.intelligence"
        }
    }
}

struct MainSidebar: View {
    @State private var selectedTab: MainTabs? = .home

    var intelligenceIsAvailable: Bool {
        // Adapte sua lógica aqui
        true
    }

    var tabs: [MainTabs] {
        var base: [MainTabs] = [.home, .evolution, .settings]
        if intelligenceIsAvailable {
            base.append(.search)
        }
        return base
    }

    var body: some View {
        NavigationSplitView {
            List(tabs, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .listStyle(SidebarListStyle())
        } detail: {
            switch selectedTab {
            case .home:
                HomeView()
            case .evolution:
                EvolutionHomeView()
            case .settings:
                SettingView()
            case .search:
                IntelligenceView()
            case .none:
                Text("Selecione uma opção")
            }
        }
    }
}

#Preview {
    MainSidebar()
}
