//
//  RecurrenceListViewModel.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 17/06/25.
//

import UIKit

class RecurringBillListViewModel: ObservableObject {
    
    private var repository: RecurringBillRepositoryProtocol?
    
    @Published var recurringBillList: [RecurringBill] = []
    
    func setup(with repository: RecurringBillRepositoryProtocol) {
        self.repository = repository
    }
    
    func fetchAll() {
        recurringBillList = repository?.fetchAll() ?? []
    }
}
