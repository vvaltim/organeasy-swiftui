//
//  TemplateListView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 30/06/26.
//

import SwiftData
import SwiftUI

struct TemplateListView: View {
    
    // MARK: - Model Container
    
    @Environment(\.modelContext) private var modelContext
    @Query<RecurringEntryTemplate>(
        sort: [
            SortDescriptor(\RecurringEntryTemplate.dueDay, order: .forward)
        ]
    ) private var allTemplates: [RecurringEntryTemplate]
    
    // MARK: - Computed Variables
    
    var enableTemplate: [RecurringEntryTemplate] {
        allTemplates.filter{ $0.enabled }
    }
    
    // MARK: - Main View
    
    var body: some View {
        VStack {
            List {
                enableSection
            }
        }
        .navigationTitle("Modelos")
    }
    
    // MARK: - Not Paid Section
    
    var enableSection: some View {
        Section("Ativos") {
            if enableTemplate.isEmpty {
                Text("Nenhum item pago")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(enableTemplate) { template in
                    TemplateRowView(
                        template: template,
                        onDelete: {
                            print("Deletar essa merda")
                        }
                    )
                }
            }
        }
    }
}

#Preview {
    TemplateListView()
        .modelContainer(OrganEasyModelContainer.preview)
}
