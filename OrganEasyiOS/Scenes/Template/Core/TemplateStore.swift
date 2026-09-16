//
//  TemplateStore.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 12/09/26.
//

import Foundation
import Combine
import SwiftData

@MainActor
class TemplateStore: ObservableObject {
    
    @Published private(set) var state: TemplateState = .idle
    
    private let repository: TemplateRepository
    
    init(repository: TemplateRepository) {
        self.repository = repository
    }
    
    func sent(_ intent: TemplateIntent) {
        let (newState, effect) = TemplateReducer.reduce(state: state, intent: intent)
        state = newState
        guard let effect else { return }
        handle(effect)
    }
    
    // MARK: - Private methods
    
    private func handle(_ effect: TemplateEffect) {
        switch effect {
        case .updateEnabled(let template):
            repository.updateEnabled(data: template)
        }
    }
}

// MARK: - Factory

enum TemplateFactory {
    static func make(modelContext: ModelContext) -> TemplateListView {
        return TemplateListView(store: TemplateStore(repository: TemplateRepository(modelContext: modelContext)))
    }
}

// MARK: - Effect

enum TemplateEffect {
    case updateEnabled(RecurringEntryTemplate)
}

// MARK: - Intent

enum TemplateIntent {
    case toggle(RecurringEntryTemplate)
}

// MARK: - State

enum TemplateState {
    case idle
    case empty
    case list(RecurringEntryTemplate)
}

// MARK: - Reducer

struct TemplateReducer {
    static func reduce(state: TemplateState, intent: TemplateIntent) -> (state: TemplateState, effect: TemplateEffect?){
        let newState = state
        
        switch intent {
        case .toggle(let template):
            return (.idle, .updateEnabled(template))
        }
    }
}
