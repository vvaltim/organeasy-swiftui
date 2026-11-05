import AppIntents

/// Responde perguntas como "quando vence a luz?" com dados do app, sem passar pelo modelo.
struct FindBillsIntent: AppIntent {
    private enum Constants {
        static let visibleLimit = 5
    }

    static let title: LocalizedStringResource = "Consultar lançamentos"
    static let description = IntentDescription("Procura contas e mostra valor, vencimento e se já foram pagas.")

    @Parameter(
        title: "Nome",
        description: "Nome da conta, como luz ou aluguel. Deixe vazio para ver as próximas contas.",
        requestValueDialog: "Qual conta você quer ver?"
    )
    var name: String?

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<[BillEntity]> {
        let bills = try BillStore.bills(matching: name ?? "")
        return .result(value: bills, dialog: IntentDialog(stringLiteral: Self.answer(for: bills)))
    }

    static func answer(for bills: [BillEntity]) -> String {
        guard !bills.isEmpty else { return String(localized: "Nenhum lançamento encontrado.") }
        return bills
            .prefix(Constants.visibleLimit)
            .map { "\($0.name): \($0.displayRepresentation.subtitleText)" }
            .joined(separator: "\n")
    }
}

private extension DisplayRepresentation {
    var subtitleText: String {
        subtitle.map { String(localized: $0) } ?? ""
    }
}
