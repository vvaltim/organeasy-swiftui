//
//  CreateEvolutionView.swift
//  OrganEasy
//
//  Created by Walter Vanio dos Reis Junior on 29/05/25.
//

import SwiftUI

struct CreateEvolutionView: View {
    
    @EnvironmentObject var provider: RepositoryProvider
    @StateObject var viewModel: CreateEvolutionViewModel = CreateEvolutionViewModel()
    
    let onClose: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section(
                    header: Text("section_details")
                ){
                    CurrencyTextField(
                        value: $viewModel.amount
                    )
                    
                    DatePicker(
                        "date_picker_date",
                        selection: $viewModel.date, displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    
                    Picker(
                        "textfield_name",
                        selection: $viewModel.selectedBank) {
                            ForEach(0..<viewModel.bankList.count, id: \.self) { index in
                                Text(viewModel.bankList[index].name ?? "Desconhecido")
                            }
                        }
                        .pickerStyle(.wheel)
                }
            }
            
            .navigationTitle(Text("navigation_transaction_title"))
            .toolbar {
                ToolbarItem {
                    Button(
                        action: {
                            viewModel.saveEvolution()
                            
                            onClose()
                        }
                    ) {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .onAppear {
                viewModel.setupProvider(with: provider)
                
                viewModel.fetchBanks()
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let provider = RepositoryProvider(context: context)
    
    CreateEvolutionView(
        onClose: { }
    ).environmentObject(provider)
}
