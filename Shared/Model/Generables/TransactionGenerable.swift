//
//  TransactionGenerable.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 19/09/25.
//

import FoundationModels

@available(iOS 26.0, *)
@Generable(description: "Uma transação que a pessoa deseja adicionar")
struct TransactionGenerable {
    @Guide(description: "O nome da transação")
    var name: String
    
    @Guide(description: "O valor da transação")
    var amount: Double
    
    @Guide(description: "A data de vencimento no formato dd/MM/yyyy")
    var dueDate: String
    
    @Guide(description: "Se é uma transactão de entrada ou saída (true para entrada, false para saída), onde por exemplo, pagar uma conta ou cadastrar um débito é saída, e receber um dinheiro ou informar um recebimento é entrada")
    var isIncome: Bool
    
    func getTransaction() -> String {
        return "isIncome: \(isIncome)\name: \(name)\namount: \(amount)\ndueDate: \(dueDate))"
    }
}
