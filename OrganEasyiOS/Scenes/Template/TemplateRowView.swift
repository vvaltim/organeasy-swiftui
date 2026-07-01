//
//  TemplateRowView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 01/07/26.
//

import SwiftUI

struct TemplateRowView: View {
    var template: RecurringEntryTemplate
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            ZStack {
                Text(String(template.dueDay))
                    .font(.title3)
                    .monospacedDigit()
                    .frame(width: Size.x36.rawValue, alignment: .leading)
            }

            Text(template.name)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDelete()
            }
        }
    }
}

#Preview {
    TemplateRowView(
        template: RecurringEntryTemplate(
            dueDay: 3,
            enabled: true,
            name: "Nubank",
            type: .expense
        ),
        onDelete: {
            
        }
    )
}
