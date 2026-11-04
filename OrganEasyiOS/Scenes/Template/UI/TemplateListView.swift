//
//  TemplateListView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 30/06/26.
//

import SwiftData
import SwiftUI

struct TemplateListView: View {
    
    private let store: TemplateStore
    
    @Environment(\.modelContext) private var modelContext
    @Query<RecurringEntryTemplate>(
        sort: [
            SortDescriptor(\RecurringEntryTemplate.dueDay, order: .forward)
        ]
    ) private var allTemplates: [RecurringEntryTemplate]
    
    init(store: TemplateStore) {
        self.store = store
    }
    
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
        .navigationTitle("Recorrências")
    }
    
    // MARK: - Not Paid Section
    
    var enableSection: some View {
        Section {
            ForEach(allTemplates) { template in
                TemplateRowView(
                    template: template,
                    onToggleEnabled: {
                        store.sent(.toggle(template))
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
}

#Preview {
    let modelContext = OrganEasyModelContainer.preview
    TemplateListView(store: TemplateStore(repository: TemplateRepository(modelContext: modelContext.mainContext)))
        .modelContainer(modelContext)
}
