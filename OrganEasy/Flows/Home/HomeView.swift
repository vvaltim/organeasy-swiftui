//
//  HomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            List {
                Text("Janeiro de 2025")
            }
            .navigationTitle(Text("Início"))
            .toolbar {
                ToolbarItem {
                    Button(
                        action: {
                            viewModel.addButtonTapped()
                        }
                    ) {
                        Image(systemName: "plus")
                    }
                }
            }
            .navigationDestination(isPresented: $viewModel.goToTransactionView) {
                TransactionView()
            }
        }
    }
}

#Preview {
    HomeView()
}
