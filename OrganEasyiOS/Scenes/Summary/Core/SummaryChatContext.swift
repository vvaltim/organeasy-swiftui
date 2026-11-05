import Foundation

/// Dados do mês que a IA recebe em toda conversa. Assim ela não depende de decidir
/// consultar a ferramenta para saber dos gastos do usuário.
struct SummaryChatContext {
    private enum Constants {
        static let largestLimit = 5
    }

    /// Texto em inglês para o modelo, com os valores já calculados.
    let facts: String
    /// Resposta pronta para o usuário quando o modelo não usar os dados.
    let brief: String

    private let entries: [SummaryEntry]
    private let now: Date

    init(entries: [SummaryEntry], now: Date = .now) {
        self.entries = entries
        self.now = now
        let snapshot = SummarySnapshot(entries: entries, now: now)
        let forecast = snapshot.forecast
        let expense = forecast.expense.getLocalCurrency()
        let income = forecast.income.getLocalCurrency()
        let paid = forecast.paidExpense.getLocalCurrency()
        let pending = forecast.pendingExpense.getLocalCurrency()
        let balance = forecast.projectedBalance.getLocalCurrency()
        let largest = snapshot.topExpenses
            .prefix(Constants.largestLimit)
            .map { "\($0.name): \($0.amount.getLocalCurrency())" }
            .joined(separator: "; ")

        var lines = [
            "Facts for the current month, calculated by the app and already correct.",
            "Total expenses: \(expense). Already paid: \(paid). Still to pay: \(pending).",
            "Income: \(income). Projected balance: \(balance)."
        ]
        if !largest.isEmpty {
            lines.append("Largest expenses: \(largest).")
        }
        if let comparison = snapshot.comparison {
            lines.append("Expenses last month: \(comparison.previousExpense.getLocalCurrency()).")
        }
        facts = lines.joined(separator: "\n")

        var answer = String(localized: "Neste mês: \(expense) de saídas, \(income) de entradas e \(pending) ainda a pagar.")
        if !largest.isEmpty {
            answer += " " + String(localized: "Maiores: \(largest).")
        }
        brief = answer
    }

    /// Escolhe o que mostrar. O modelo só pode citar números que existem nos dados,
    /// e uma pergunta de valor nunca termina em "não sei".
    func answer(for reply: String, question: String, toolReports: [String]) -> String {
        if Self.asksHowToSave(question), let tips = savingsTips {
            return tips
        }

        if Self.asksWhatIsDue(question), let next = nextBill {
            return next
        }

        let scope = SummaryQuestionScope(question: question, entries: entries, now: now)
        if scope.isUnknownBill {
            return String(localized: "Nenhum lançamento encontrado.")
        }

        let fallback = toolReports.last ?? calculatedReport(for: question)
        // Com a consulta feita, só os números dela valem: o resumo do mês responde outra pergunta.
        let trusted = toolReports.isEmpty ? [facts, calculatedReport(for: question)] : toolReports
        guard let text = SummaryAnswerGuard.verified(reply, question: question, reports: trusted) else {
            return fallback
        }

        // Às vezes o modelo escreve a chamada da ferramenta como texto.
        if text.contains("{") || text.contains("}") { return fallback }

        let numbers = SummaryAnswerGuard.numbers(in: text)
        // Com vários valores na frase, o modelo já trocou um rótulo por outro nos testes.
        if numbers.count > 1 { return fallback }
        return numbers.isEmpty && Self.asksForAmount(question) ? fallback : text
    }

    private var nextBill: String? {
        guard let bill = entries
            .filter({ $0.type == .expense && !$0.isPaid })
            .min(by: { $0.dueDate < $1.dueDate })
        else { return nil }
        let amount = bill.amount.getLocalCurrency()
        let date = bill.dueDate.formatted(date: .long, time: .omitted)
        return String(localized: "A próxima conta é \(bill.name), de \(amount), com vencimento em \(date).")
    }

    private var savingsTips: String? {
        let tips = SavingsAdvisor.suggestions(entries: entries, now: now).map(\.text)
        return tips.isEmpty ? nil : tips.joined(separator: "\n")
    }

    /// Resposta do próprio app, usada quando o modelo não consulta os dados.
    private func calculatedReport(for question: String) -> String {
        let scope = SummaryQuestionScope(question: question, entries: entries, now: now)
        guard let name = scope.name else { return brief }
        var arguments = EntryLookupTool.Arguments(type: .todos, payment: scope.payment)
        arguments.name = name
        arguments.year = scope.year
        arguments.month = scope.month
        return EntryLookupTool.report(entries: EntryLookupTool.filter(entries, with: arguments))
    }

    // MARK: - Termos

    private static let genericTerms: Set<String> = [
        "gasto", "gastos", "despesa", "despesas", "conta", "contas", "saida", "saidas", "lancamento", "lancamentos",
        "expense", "expenses", "spending", "bill", "bills", "entries", "cuenta", "cuentas", "egreso", "egresos",
        "depense", "depenses", "facture", "factures", "spesa", "spese", "bolletta", "bollette", "uscita", "uscite"
    ]

    private static let amountTerms = [
        "quanto", "gast", "falta", "paguei", "pagar", "recebi", "saldo", "devo",
        "how much", "spent", "spend", "expense", "owe", "balance", "received",
        "cuanto", "pague", "recibi", "combien", "depens", "paye", "recu", "speso", "pagato", "ricevuto"
    ]

    private static let dueTerms = ["vence", "vencimento", "due", "vencen", "echeance", "scadenza", "scade"]

    private static func asksWhatIsDue(_ question: String) -> Bool {
        let text = folded(question)
        return dueTerms.contains { text.contains($0) }
    }

    private static let savingTerms = ["econom", "save money", "saving", "ahorr", "risparm", "gastar menos", "spend less"]

    private static func asksHowToSave(_ question: String) -> Bool {
        let text = folded(question)
        return savingTerms.contains { text.contains($0) }
    }

    private static func folded(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// "Gastos" não é o nome de uma conta: filtrar por essa palavra esconderia tudo.
    nonisolated static func isGenericName(_ name: String) -> Bool {
        genericTerms.contains(name.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private static func asksForAmount(_ question: String) -> Bool {
        let text = folded(question)
        return amountTerms.contains { text.contains($0) }
    }
}

// MARK: - Escopo da pergunta

/// Período e conta citados na pergunta, decididos pelo app. O modelo inventa o mês quando
/// a pergunta não cita nenhum, e um filtro errado faz ele responder que não há dados.
nonisolated struct SummaryQuestionScope: Sendable {
    let year: Int?
    let month: Int?
    let name: String?
    let type: EntryLookupTool.EntryTypeFilter
    let payment: EntryLookupTool.PaymentFilter
    /// A pergunta cita algo, como "com academia", que não existe nos lançamentos.
    let isUnknownBill: Bool

    private static let months: [[String]] = [
        ["janeiro", "january", "enero", "janvier", "gennaio"],
        ["fevereiro", "february", "febrero", "fevrier", "febbraio"],
        ["marco", "march", "marzo", "mars"],
        ["abril", "april", "avril", "aprile"],
        ["maio", "may", "mayo", "mai", "maggio"],
        ["junho", "june", "junio", "juin", "giugno"],
        ["julho", "july", "julio", "juillet", "luglio"],
        ["agosto", "august", "aout"],
        ["setembro", "september", "septiembre", "septembre", "settembre"],
        ["outubro", "october", "octubre", "octobre", "ottobre"],
        ["novembro", "november", "noviembre", "novembre"],
        ["dezembro", "december", "diciembre", "decembre", "dicembre"]
    ]

    private static let lastMonthTerms = ["mes passado", "mes anterior", "last month", "mes pasado", "mois dernier", "mese scorso"]
    private static let yearTerms = ["este ano", "neste ano", "no ano", "this year", "este ano", "cette annee", "quest'anno", "questo anno"]

    private static let pendingTerms = ["falta", "pendente", "a pagar", "devo", "left", "owe", "unpaid", "pending", "por pagar", "pendiente", "reste", "impaye", "manca", "da pagare"]
    private static let paidTerms = ["paguei", "pagos", "pagas", "paid", "pague", "pagado", "paye", "pagato"]
    private static let incomeTerms = ["recebi", "entrada", "receita", "ganhei", "received", "income", "earned", "recibi", "ingreso", "recu", "entree", "ricevuto", "entrat"]

    private static let subjectPrepositions: Set<String> = ["com", "no", "na", "on", "at", "for", "en", "con", "avec", "dans", "per"]
    private static let notSubjects: Set<String> = [
        "o", "a", "os", "as", "the", "el", "la", "le", "il", "meu", "minha", "my", "mi", "mon", "ma", "mio", "mia",
        "mes", "ano", "month", "year", "este", "esta", "this", "total", "geral", "dinheiro", "money", "dia", "hoje", "today",
        "passado", "pasado", "anterior", "last", "past", "dernier", "scorso", "ultimo", "mois", "mese"
    ]

    private static func mentionsUnknownSubject(_ words: [String]) -> Bool {
        let monthNames = Set(months.flatMap { $0 })
        for (index, word) in words.enumerated() where subjectPrepositions.contains(word) {
            guard let subject = words[(index + 1)...].first(where: { !notSubjects.contains($0) }), index + 3 >= words.firstIndex(of: subject) ?? 0 else { continue }
            let isPeriod = monthNames.contains(subject) || Int(subject) != nil
            if !isPeriod, subject.count >= 3, !SummaryChatContext.isGenericName(subject) { return true }
        }
        return false
    }

    private static func fold(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
    }

    init(question: String, entries: [SummaryEntry], now: Date) {
        let calendar = Calendar.current
        let text = Self.fold(question)
        let words = text.split { !$0.isLetter && !$0.isNumber }.map(String.init)
        let current = calendar.dateComponents([.year, .month], from: now)
        let thisYear = current.year ?? 0
        let thisMonth = current.month ?? 1

        let writtenYear = words.compactMap { Int($0) }.first { (2000...2100).contains($0) }
        let namedMonth = Self.months.firstIndex { $0.contains(where: words.contains) }.map { $0 + 1 }

        if let namedMonth {
            month = namedMonth
            year = writtenYear ?? (namedMonth > thisMonth ? thisYear - 1 : thisYear)
        } else if Self.lastMonthTerms.contains(where: text.contains) {
            month = thisMonth == 1 ? 12 : thisMonth - 1
            year = thisMonth == 1 ? thisYear - 1 : thisYear
        } else if let writtenYear {
            month = nil
            year = writtenYear
        } else if Self.yearTerms.contains(where: text.contains) {
            month = nil
            year = thisYear
        } else {
            month = thisMonth
            year = thisYear
        }

        let foundName = Set(entries.map(\.name))
            .filter { $0.count >= 3 && text.contains(Self.fold($0)) }
            .max { $0.count < $1.count }
        name = foundName
        isUnknownBill = foundName == nil && Self.mentionsUnknownSubject(words)

        if foundName != nil {
            type = .todos
        } else {
            type = Self.incomeTerms.contains(where: text.contains) ? .receita : .despesa
        }

        if Self.pendingTerms.contains(where: text.contains) {
            payment = .pendente
        } else if Self.paidTerms.contains(where: text.contains) {
            payment = .pago
        } else {
            payment = .todos
        }
    }
}
