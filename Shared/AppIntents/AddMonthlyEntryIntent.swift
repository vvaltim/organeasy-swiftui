import AppIntents
import SwiftData

struct AddMonthlyEntryIntent: AppIntent {

    static var title: LocalizedStringResource = "Adicionar lancamento mensal"
    
    static var description = IntentDescription(
        "Criação de um novo lancamento mensal"
    )

    @Parameter(title: "Descrição")
    var title: String

    @Parameter(title: "Valor")
    var amount: Double
    
    @Parameter(title: "Data de vencimento")
    var dueDate: Date?

    @Parameter(title: "Categoria")
    var category: EntryType?

    func perform() async throws -> some IntentResult {
        
        let container = await OrganEasyModelContainer.shared
        let context = ModelContext(container)
        
        let entry = MonthlyEntry(
            name: title,
            amount: amount,
            referenceMonth: "",
            dueDate: dueDate ?? Date(),
            type: category ?? .expense
        )
        
        context.insert(entry)
        try context.save()
        
        let formattedAmount = await amount.getLocalCurrency()

        return .result(
            dialog: "Adicionei \(title) no valor de \(formattedAmount)."
        )
    }
}
