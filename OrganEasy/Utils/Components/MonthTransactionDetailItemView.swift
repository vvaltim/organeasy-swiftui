//
//  MonthTransactionDetailItemView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import CoreData
import SwiftUI

struct MonthTransactionDetailItemView: View {
    var descriptionText: String
    var dueDate: String
    var paymentDate: String?
    var ammount: String
    var isIncome: Bool
    var isSlash: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isIncome ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isIncome ? "chevron.up.forward.dotted.2" : "chevron.up.forward.dotted.2")
                    .foregroundColor(isIncome ? .green : .red)
                    .font(.system(size: 22))
                    .rotationEffect(isIncome ? .degrees(0) : .degrees(180))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(descriptionText)
                        .font(.body)
                    
                    Spacer()
                    
                    if let paymentDate = paymentDate {
                        Text(paymentDate)
                            .font(.subheadline)
                            .bold()
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassEffect()
                    }
                }
                
                Text(ammount)
                    .strikethrough(isSlash)
                    .font(.headline)
                
                Text(dueDate)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    return MonthTransactionDetailItemView(
        descriptionText: "Spothirth",
        dueDate: "10/11",
        paymentDate: "25/11",
        ammount: "R$ 666,66",
        isIncome: true,
        isSlash: true
    )
    .padding()
}
