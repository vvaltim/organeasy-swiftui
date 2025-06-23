//
//  BankListView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct BankListView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    
    @StateObject var viewModel: BankListViewModel = BankListViewModel()
    
    var body: some View {
        Group {
            if viewModel.banks.isEmpty {
                EmptyStateView(
                    imageName: "tray",
                    title: "label_empty_data",
                    message: "",
                    actionTitle: nil,
                    action: { }
                )
            } else {
                List(viewModel.banks, id: \.self) { bank in
                    Text(bank.name ?? "")
                        .opacity(bank.isHidden ? 0.3 : 1.0)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                viewModel.changeVisibility(bank)
                            } label: {
                                Label(
                                    bank.isHidden ? "button_show" : "button_hide",
                                    systemImage: bank.isHidden ? "eye" : "eye.slash"
                                )
                                
                            }
                            .tint(.orange)
                        }
                }
            }
        }
        .navigationTitle(Text("navigation_bank_list"))
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
        .sheet(isPresented: $viewModel.goToCreateBankView) {
            CreateBankView(
                onClose: {
                    viewModel.goToCreateBankView = false
                    viewModel.fetchAll()
                }
            )
        }
        .onAppear {
            viewModel.setup(with: provider)
            viewModel.fetchAll()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    
    BankListView()
        .environmentObject(provider)
}
