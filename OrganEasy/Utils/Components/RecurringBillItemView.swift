//
//  RecurringBillItemView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 24/06/25.
//

import SwiftUI

struct RecurringBillItemView: View {
    let name: String
    let amount: Double
    let dueDay: Date

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("Todo dia \(dueDay.formatTo(dateFormat: "d"))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(amount.toBRL())
                .font(.title3)
                .bold()
                .foregroundColor(.green)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    RecurringBillItemView(
        name: "Electricity Bill",
        amount: 120.50,
        dueDay: Date()
    )
}
