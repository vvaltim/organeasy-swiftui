//
//  MonthTransactionDetailItemView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 22/05/25.
//

import CoreData
import SwiftUI

struct MonthTransactionDetailItemView: View {
    enum ButtonType {
        case tap
        case paid
        case slash
        case delete
    }
    
    var descriptionText: String
    var dueDate: String
    var paymentDate: String?
    var ammount: String
    var isIncome: Bool
    var isSlash: Bool
    var canPay: Bool
    var canSlash: Bool
    var onTap: ((ButtonType) -> Void)
    
    var body: some View {
        VStack {
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
                                .modifier(GlassEffectIfAvailable())
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
            }.onTapGesture {
                onTap(.tap)
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if canPay {
                    Button {
                        onTap(.paid)
                    } label: {
                        Label(
                            "button_pay",
                            systemImage: "checkmark.circle"
                        )
                    }
                    .tint(.green)
                }
                
                if canSlash {
                    Button {
                        onTap(.slash)
                    } label: {
                        Label(
                            isSlash ? "button_strikethrough_off" : "button_strikethrough_on" ,
                            systemImage: isSlash ? "pencil" : "pencil.slash"
                        )
                    }
                    .tint(.gray)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    onTap(.delete)
                } label: {
                    Label(
                        "button_delete",
                        systemImage: "trash.fill"
                    )
                }
            }
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
        isSlash: true,
        canPay: true,
        canSlash: true,
        onTap: { type in
            print("Apertou")
        }
    )
    .padding()
}
