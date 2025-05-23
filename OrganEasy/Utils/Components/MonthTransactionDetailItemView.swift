//
//  MonthTransactionDetailItemView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import CoreData
import SwiftUI

struct MonthTransactionDetailItemView: View {
    let transaction: Transaction
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.descriptionText)
                    .font(.headline)
                
                Text("Vencimento: \(transaction.dueDate, formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let paymentDate = transaction.paymentDate {
                    Text("Pago em: \(paymentDate, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Text(transaction.amount, format: .currency(code: "BRL"))
                    .font(.title3)
                    .foregroundColor(transaction.isIncome ? .green : .red)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }
}

#Preview {
    var context = PersistenceController.preview.container.viewContext
    
    let transaction = Transaction(context: context)
    transaction.id = UUID()
    transaction.descriptionText = "Teste"
    transaction.dueDate = Date()
    transaction.amount = 100
    transaction.isIncome = false
    
    return MonthTransactionDetailItemView(transaction: transaction)
}
