//
//  FinanceSummaryCard.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct FinanceSummaryCard: View {
    var input: Double
    var output: Double
    
    var total: Double {
        input - output
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 16){
            VStack{
                HStack {
                    Text("finance_summary_card_input")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(input.toBRL())
                        .font(.headline)
                        .foregroundColor(.green)
                }
                
                HStack{
                    Text("finance_summary_card_output")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(output.toBRL())
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            Divider()
            HStack{
                Text("finance_summary_card_balance")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(total.toBRL())
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(total > 0 ? .green : .red)
            }
        }
        .padding()
        .modifier(GlassEffectIfAvailable())
        .padding(.vertical)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    FinanceSummaryCard(
        input: 300.36,
        output: 121.40
    ).padding()
}
