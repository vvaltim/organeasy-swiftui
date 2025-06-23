//
//  RecurrenceListViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 17/06/25.
//

import UIKit

class RecurrenceListViewModel: ObservableObject {
    
    private var repository: RecurringBillRepositoryProtocol?
    
    @Published var recurrenceList: [String] = ["Teste 1", "Teste 2", "Teste 3"]
    
    func setup(with repository: RecurringBillRepositoryProtocol) {
        self.repository = repository
    }
}
