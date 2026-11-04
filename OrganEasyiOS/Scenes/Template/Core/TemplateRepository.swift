//
//  TemplateRepository.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 12/09/26.
//

import SwiftData

class TemplateRepository {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func updateEnabled(data: RecurringEntryTemplate) {
        data.enabled.toggle()
        try? modelContext.save()
    }

}
