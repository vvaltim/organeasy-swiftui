import Foundation
import FoundationModels

enum SummaryAssistantAvailability {
    static var isModelReady: Bool {
        guard case .available = SystemLanguageModel.default.availability else { return false }
        return SystemLanguageModel.default.supportsLocale()
    }

    static var isAvailable: Bool {
        isModelReady || ShowcaseMode.isEnabled || ShowcaseMode.forcesAICard
    }
}

@Generable
struct MonthInsights: Sendable {
    @Guide(description: "One short neutral sentence about the month, with no digits.")
    var headline: String

    @Guide(description: "Three short practical remarks, with no digits and no currency.", .count(3))
    var tips: [String]
}

nonisolated enum SummaryAssistant {
    private static var language: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return Locale(identifier: "en").localizedString(forLanguageCode: code) ?? "English"
    }

    static func instructions(now: Date, facts: String) -> String {
        let today = now.formatted(date: .long, time: .omitted)
        return """
        You are My AI, a personal assistant for the user's bills. Today is \(today).
        The user's locale is \(Locale.current.identifier). Always answer in \(language).
        You have access to the user's finances. Never say you lack their data.
        When the question is not about money, say briefly that you only help with the user's bills.
        \(facts)
        Answer general questions about the current month directly from those facts.
        For a specific bill, a past month or a past year, call the tool consultarLancamentos.
        When calling the tool, set name only to the name of a bill. Leave it empty for general questions.
        Copy amounts exactly as written here or as the tool returns them. Never calculate or estimate numbers.
        If the tool finds nothing, say so. Do not give investment advice.
        Use plain text with no markdown. Answer in at most three sentences.
        """
    }

    static func insights(for prompt: String) async throws -> MonthInsights {
        let session = LanguageModelSession(instructions: """
        You comment on the user's month with a neutral tone and no judgment.
        The user's locale is \(Locale.current.identifier). Always write in \(language).
        Never write digits, amounts or currency symbols. Do not give investment advice.
        """)
        return try await session.respond(to: prompt, generating: MonthInsights.self).content
    }
}

nonisolated enum SummaryAnswerGuard {
    static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: "**", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func numbers(in text: String) -> Set<String> {
        guard let regex = try? NSRegularExpression(pattern: "\\d+(?:[.,\\s\\u00A0\\u202F]\\d+)*") else { return [] }
        let range = NSRange(text.startIndex..., in: text)
        return Set(regex.matches(in: text, range: range).compactMap { match in
            Range(match.range, in: text).map { String(text[$0].filter(\.isNumber)) }
        })
    }

    static func verified(_ reply: String, question: String, reports: [String]) -> String? {
        let text = clean(reply)
        let found = numbers(in: text)
        guard !found.isEmpty else { return text }

        var allowed = numbers(in: question)
        for report in reports {
            allowed.formUnion(numbers(in: report))
        }

        let isTrusted = found.allSatisfy { number in
            allowed.contains(number) || allowed.contains(number + "00")
        }
        return isTrusted ? text : nil
    }
}

actor EntryLookupLog {
    private(set) var reports: [String] = []
    private(set) var scope: SummaryQuestionScope?

    func add(_ report: String) {
        reports.append(report)
    }

    func clear() {
        reports = []
    }

    func start(_ scope: SummaryQuestionScope) {
        reports = []
        self.scope = scope
    }
}

nonisolated struct EntryLookupTool: Tool {
    let name = "consultarLancamentos"
    let description = "Looks up the user's bills and income and returns the calculated totals. Filters are optional."

    let entries: [SummaryEntry]
    let log: EntryLookupLog

    @Generable
    enum EntryTypeFilter: String {
        case despesa
        case receita
        case todos
    }

    @Generable
    enum PaymentFilter: String {
        case pago
        case pendente
        case todos
    }

    @Generable
    struct Arguments {
        @Guide(description: "Part of the entry name, like electricity or rent. Leave empty for all entries.")
        var name: String?

        @Guide(description: "Four digit year. Leave empty for every year.")
        var year: Int?

        @Guide(description: "Month from 1 to 12. Leave empty for the whole year.")
        var month: Int?

        @Guide(description: "despesa for expenses, receita for income, todos for both.")
        var type: EntryTypeFilter

        @Guide(description: "pago for paid, pendente for not paid yet, todos for both.")
        var payment: PaymentFilter
    }

    func call(arguments: Arguments) async throws -> String {
        var filters = arguments
        if let scope = await log.scope {
            filters.year = scope.year
            filters.month = scope.month
            filters.type = scope.type
            filters.payment = scope.payment
            if let name = scope.name {
                filters.name = name
            }
        }
        let isUnknownBill = await log.scope?.isUnknownBill ?? false
        let report = Self.report(entries: isUnknownBill ? [] : Self.filter(entries, with: filters))
        await log.add(report)
        return report
    }

    static func filter(_ entries: [SummaryEntry], with arguments: Arguments) -> [SummaryEntry] {
        let calendar = Calendar.current
        let rawName = arguments.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = SummaryChatContext.isGenericName(rawName) ? "" : rawName

        return entries.filter { entry in
            let date = calendar.dateComponents([.year, .month], from: entry.dueDate)

            if !name.isEmpty && !entry.name.localizedStandardContains(name) { return false }
            if let year = arguments.year, date.year != year { return false }
            if let month = arguments.month, date.month != month { return false }

            switch arguments.type {
            case .despesa where entry.type != .expense: return false
            case .receita where entry.type != .income: return false
            default: break
            }

            switch arguments.payment {
            case .pago where !entry.isPaid: return false
            case .pendente where entry.isPaid: return false
            default: break
            }

            return true
        }
    }

    static func report(entries: [SummaryEntry]) -> String {
        guard !entries.isEmpty else { return String(localized: "Nenhum lançamento encontrado.") }

        let currency = FloatingPointFormatStyle<Double>.Currency(
            code: Locale.current.currency?.identifier ?? "BRL"
        )
        let total = entries.map(\.amount).reduce(.zero, +).formatted(currency)
        let largest = entries
            .sorted { $0.amount > $1.amount }
            .prefix(3)
            .map { "\($0.name): \($0.amount.formatted(currency))" }
            .joined(separator: "; ")

        return String(localized: "Total de \(total) em \(entries.count) lançamentos. Maiores: \(largest).")
    }
}
