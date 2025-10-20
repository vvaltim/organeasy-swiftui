//
//  IntelligenceService.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 20/09/25.
//

import Foundation
import FoundationModels

typealias InitializeChatCompletion = (Result<String, Error>) -> Void
typealias CheckIntentionsCompletion = (Result<String, Error>) -> Void
typealias ProcessTransactionCompletion = (Result<TransactionDTO, Error>) -> Void
typealias ProcessEvolutionCompletion = (Result<EvolutionDTO, Error>) -> Void

enum IntelligenceServiceError: LocalizedError {
    case unavailable
    case error(String)

    var errorDescription: String? {
        switch self {
        case .error(let reason):
            return reason
        case .unavailable:
            return "Not available"
        }
    }
}

protocol IntelligenceServicing {
    func setupBankList(bankList: [Bank])
    func initializeChat(prompt: String, completion: @escaping InitializeChatCompletion)
    func checkIntentions(prompt: String, completion: @escaping CheckIntentionsCompletion)
    func processTransaction(prompt: String, completion: @escaping ProcessTransactionCompletion)
    func processEvolituon(prompt: String, completion: @escaping ProcessEvolutionCompletion)
}

class IntelligenceService: IntelligenceServicing {
    // MARK:  Private
    private var bankList: [Bank] = []
    
    private func getBankListName() -> String {
        return bankList.map { "\($0.name) (\($0.id?.uuidString ?? ""))" }.joined(separator: ", ")
    }
    
    private func getBankByID(_ id: String) -> Bank {
        for item in bankList {
            if item.id?.uuidString == id {
                return item
            }
        }
        
        return bankList.first!
    }
    
    func setupBankList(bankList: [Bank]) {
        self.bankList = bankList
    }
    
    func processEvolituon(prompt: String, completion: @escaping ProcessEvolutionCompletion) {
        if bankList.isEmpty {
            completion(.failure(IntelligenceServiceError.error("Configure os bancos no app em Ajustes -> Bancos, para usar essa função")))
            return
        }
        
        let model = SystemLanguageModel.default
        if !model.isAvailable {
            completion(.failure(IntelligenceServiceError.unavailable))
            return
        }
        
        let date = Date()
        
        let instructions = "Você é um assistente que extrai informações estruturadas de evolução de patrimônio a partir de um texto em português. - amount (Double) - name (String) - date (Date, formato dd/MM/yyyy). Se algum campo não estiver presente, use null ou false. Tambem existe essa lista de bancos, onde tenho o nome e entre parenteses tenho o id dele \(getBankListName()), se o usuário informar um desses bancos, coloque o bankId no campo, se não deixe nulo. Se a data informada não tiver ano, assuma que o dia de hoje é \(date.formatTo())"
        let session = LanguageModelSession(instructions: instructions)
        
        Task {
            do {
                let options = GenerationOptions(temperature: 0.2)
                let response = try await session.respond(
                    to: prompt,
                    generating: EvolutionGenerable.self,
                    options: options
                )
                
                let dto = EvolutionDTO(
                    id: UUID(),
                    value: response.content.amount,
                    date: response.content.date.stringToDate() ?? Date(),
                    bank: getBankByID(response.content.bankId),
                    addWithIA: true
                )
                
                await MainActor.run {
                    completion(.success(dto))
                }
            } catch {
                await MainActor.run {
                    completion(.failure(IntelligenceServiceError.error("Erro ao processar evolução: \(error)")))
                }
            }
        }
    }
    
    func processTransaction(prompt: String, completion: @escaping ProcessTransactionCompletion) {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if !model.isAvailable {
                completion(.failure(IntelligenceServiceError.unavailable))
                return
            }
            
            let date = Date()
            
            let instructions = "Você é um assistente que extrai informações estruturadas de despesas a partir de um texto em português. - amount (Double) - descriptionText (String) - dueDate (Date, formato dd/MM/yyyy) - isIncome (Bool) Se algum campo não estiver presente, use null ou false. Se a data informada não tiver ano, assuma que o dia de hoje é \(date.formatTo())"
            let session = LanguageModelSession(instructions: instructions)
            
            Task {
                do {
                    let options = GenerationOptions(temperature: 0.2)
                    let response = try await session.respond(
                        to: prompt,
                        generating: TransactionGenerable.self,
                        options: options
                    )
                    
                    let dto = TransactionDTO(
                        isIncome: response.content.isIncome,
                        descriptionText: response.content.name,
                        amount: response.content.amount,
                        dueDate: response.content.dueDate.stringToDate() ?? Date(),
                        isSlash: false,
                        addWithIA: true
                    )
                    
                    await MainActor.run {
                        completion(.success(dto))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(IntelligenceServiceError.error("Erro ao processar transação: \(error)")))
                    }
                }
            }
        } else {
            completion(.failure(IntelligenceServiceError.unavailable))
        }
    }
    
    func checkIntentions(prompt: String, completion: @escaping CheckIntentionsCompletion) {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if !model.isAvailable {
                completion(.failure(IntelligenceServiceError.unavailable))
                return
            }
            
            let instructions = """
            Você é um assistente que entende textos em português. 
            Classifique a intenção do texto do usuário como uma das opções abaixo:
            - cadastrar_transacao
            - cadastrar_evolucao
            - cadastrar_banco
            - outra
            
            Responda apenas com o nome da intenção.
            """
            let session = LanguageModelSession(instructions: instructions)
            
            Task {
                do {
                    let options = GenerationOptions(temperature: 0.2)
                    let response = try await session.respond(to: prompt, options: options)
                    let userIntent = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    await MainActor.run {
                        completion(.success(userIntent))
                    }
                } catch let error as LanguageModelSession.GenerationError {
                    let mainMessage: String
                    switch error {
                    case .guardrailViolation(let context):
                        mainMessage = context.debugDescription
                    case .decodingFailure(let context):
                        mainMessage = context.debugDescription
                    case .rateLimited(let context):
                        mainMessage = context.debugDescription
                    default:
                        mainMessage = "Não sei o que fazer sobre a sua pergunta."
                    }
                    let failureReason = error.failureReason
                    let recoverySuggestion = error.recoverySuggestion
                    let errorMessage = [mainMessage, failureReason, recoverySuggestion].compactMap { $0 }.joined(separator: "\n")
                    
                    await MainActor.run {
                        completion(.failure(IntelligenceServiceError.error(errorMessage)))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(IntelligenceServiceError.error("Erro ao classificar intenção: \(error)")))
                    }
                }
            }
        } else {
            completion(.failure(IntelligenceServiceError.unavailable))
        }
    }
    
    func initializeChat(prompt: String, completion: @escaping InitializeChatCompletion) {
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            if !model.isAvailable {
                completion(.failure(IntelligenceServiceError.unavailable))
                return
            }
            
            let instructions = "Voçê é um assistente pessoal chamada Easynhe, que ajuda as pessoas a gerenciar suas financas. Você fala de forma bastante descontraida, mas de forma sucinta, no maximo umas 20 palavras. Suas principais funcionalidades são cadastrar transações de entrada ou saida, cadastrar evoluções do dinheiro guardado, para que a lista de evoluções fique mais detalhada."
            let session = LanguageModelSession(instructions: instructions)
            
            Task {
                do {
                    let options = GenerationOptions(temperature: 0.2)
                    let response = try await session.respond(to: prompt, options: options)
                    let userIntent = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    await MainActor.run {
                        completion(.success(userIntent))
                    }
                } catch {
                    await MainActor.run {
                        completion(.failure(IntelligenceServiceError.error("Erro ao inicializar chat: \(error)")))
                    }
                }
            }
        } else {
            completion(.failure(IntelligenceServiceError.unavailable))
        }
    }
}

