//
//  SettingView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var viewModel: SettingViewModel
    
    var body: some View {
        NavigationView {
            List {
                Toggle(isOn: $viewModel.isDarkMode) {
                    Text("Modo Escuro")
                }
            }
            .navigationTitle(Text("Configurações"))
        }
    }
}

#Preview {
    let mock = SettingViewModel()
    
    SettingView(viewModel: mock)
}
