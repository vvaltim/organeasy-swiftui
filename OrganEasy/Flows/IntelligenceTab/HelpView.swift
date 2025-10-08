//
//  HelpView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 08/10/25.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Descrição geral
            Text("O chat do app permite que você adicione transações de forma rápida e prática usando comandos de texto.")
                .font(.body)
            
            // Funcionalidades atuais
            VStack(alignment: .leading, spacing: 8) {
                Text("Funcionalidades atuais:")
                    .font(.headline)
                Text("• Adicionar uma transação na aba Home.")
                    .font(.body)
            }
            
            // Exemplo de comando
            VStack(alignment: .leading, spacing: 8) {
                Text("Como usar:")
                    .font(.headline)
                Text("Para adicionar uma transação, siga o padrão abaixo:")
                    .font(.body)
                Text("“Adicione uma transação de entrada chamada Netflix, no valor de trinta e três reais, com vencimento no dia 10 de janeiro.”")
                    .italic()
                    .padding(.leading)
            }
            
            // Espaço para futuras funcionalidades
            VStack(alignment: .trailing, spacing: 8) {
                Text("Em breve:")
                    .font(.headline)
                Text("Novas funcionalidades serão adicionadas ao chat. Fique atento às atualizações!")
                    .font(.body)
            }
            
            Spacer()
        }
        .navigationTitle("Ajuda do Chat")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
        .padding()
    }
}

#Preview {
    HelpView()
}
