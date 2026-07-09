//
//  TemplateRowView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 01/07/26.
//

import SwiftUI

struct TemplateRowView: View {
    var template: RecurringEntryTemplate
    let onToggleEnabled: () -> Void
    
    var isStrike: Bool {
        !template.enabled
    }
    
    var body: some View {
        HStack {
            ZStack {
                Text(String(template.dueDay))
                    .font(.title3)
                    .monospacedDigit()
                    .frame(width: Size.x36.rawValue, alignment: .leading)
                    .strikethrough(isStrike)
            }

            Text(template.name)
                .font(.headline)
                .foregroundStyle(.primary)
                .strikethrough(isStrike)
            
            Spacer()
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(template.enabled ? OrganEasyStrings.Template.deactivate  : OrganEasyStrings.Template.activate) {
                onToggleEnabled()
            }.tint(.blue)
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
        onToggleEnabled: {
            
        }
    )
}
