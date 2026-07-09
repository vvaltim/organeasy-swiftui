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
    
    // MARK: - Main View
    
    var body: some View {
        VStack {
            if allTemplates.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    enableSection
                }
            }
        }
        .navigationTitle(OrganEasyStrings.Home.recurrenceMenuTitle)
    }
    
    // MARK: - Not Paid Section
    
    var enableSection: some View {
        Section {
            ForEach(allTemplates) { template in
                TemplateRowView(
                    template: template,
                    onToggleEnabled: {
                        toggleEnabled(template: template)
                    }
                )
            }
        }
    }
    
    var emptyState: some View {
        ContentUnavailableView(
            "Sem recorrencias",
            systemImage: Icon.listBulletRectanglePortrait.rawValue,
            description: Text("Suas recorrencias aparecerão aqui.").font(.caption)
        )
    }
    
    // MARK: Functions
    
    private func toggleEnabled(template: RecurringEntryTemplate) {
        template.enabled.toggle()
        
        try? modelContext.save()
    }
}

#Preview {
    TemplateListView()
        .modelContainer(OrganEasyModelContainer.preview)
}
