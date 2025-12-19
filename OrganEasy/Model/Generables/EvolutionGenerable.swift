//
//  EvolutionGenerable.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 08/10/25.
//

import FoundationModels

@Generable(description: "Uma Evolução que a pessoa deseja adicionar")
struct EvolutionGenerable {
    @Guide(description: "A data que esse valor foi verificado por ultimo no formato dd/MM/yyyy")
    var date: String
    
    @Guide(description: "O valor da evolução")
    var amount: Double
    
    @Guide(description: "O id do banco, com base no nome informado")
    var bankId: String
}
