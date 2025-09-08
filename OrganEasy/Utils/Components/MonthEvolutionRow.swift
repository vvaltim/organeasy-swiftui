//
//  MonthEvolutionRow.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 18/08/25.
//

import SwiftUI

struct MonthEvolutionRow: View {
    let month: String
    let total: Double
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text(month)
            Spacer()
            Text(total.toBRL())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
