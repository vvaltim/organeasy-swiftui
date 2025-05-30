//
//  BankListView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct BankListView: View {
    
    @StateObject var viewModel: BankListViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.banks, id: \.self) { bank in
                Text(bank.name ?? "")
                    .opacity(bank.isHidden ? 0.3 : 1.0)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button {
                            viewModel.changeVisibility(bank)
                        } label: {
                            Label(
                                bank.isHidden ? "button_show" : "button_hide",
                                systemImage: bank.isHidden ? "eye" : "eye.slash"
                            )
                            
                        }
                        .tint(.indigo)
                    }
            }
            .navigationTitle("navigation_bank_list")
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
                    viewModel: CreateBankViewModel(
                        repository: viewModel.repository,
                        onClose: {
                            viewModel.goToCreateBankView = false
                            viewModel.fetchAll()
                        }
                    )
                )
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let repository = BankRepository(context: context)
    
    BankListView(
        viewModel: BankListViewModel(
            repository: repository
        )
    )
}
