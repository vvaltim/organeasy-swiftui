//
//  TransactionView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 21/05/25.
//

import SwiftUI

struct TransactionView: View {
    
    @State private var dueDate: Date = Date()
    @State private var isIncome: Bool = true
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Transação")){
                    TextField("Descrição", text: .constant(""))
                    DatePicker("Data de Vencimento", selection: $dueDate, displayedComponents: .date)
                    TextField("Valor", text: .constant("R$ 0,00")).keyboardType(.decimalPad)
                    Picker("Tipo de movimentação", selection: $isIncome) {
                        Text("Entrada").tag(true)
                        Text("Saída").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section {
                    Button("Salvar") {
                        
                        print("Validar form, salvar e fechar a tela")
                    }
                }
                
                .navigationBarTitle("Lançamento", displayMode: .inline)
            }
        }
    }
}

#Preview {
    TransactionView()
}
