import AppIntents
import CoreSpotlight
import SwiftData

struct BillEntity: IndexedEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Lançamento")
    static let defaultQuery = BillEntityQuery()

    let id: UUID

    @Property(title: "Nome")
    var name: String

    @Property(title: "Valor")
    var amount: Double

    @Property(title: "Data de vencimento")
    var dueDate: Date

    @Property(title: "Já foi pago")
    var isPaid: Bool

    @Property(title: "É entrada de dinheiro")
    var isIncome: Bool

    init(id: UUID, name: String, amount: Double, dueDate: Date, isPaid: Bool, isIncome: Bool) {
        self.id = id
        self.name = name
        self.amount = amount
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.isIncome = isIncome
    }

    init(entry: MonthlyEntry) {
        self.init(
            id: entry.id,
            name: entry.name,
            amount: entry.amount,
            dueDate: entry.dueDate,
            isPaid: entry.paymentDate != nil,
            isIncome: entry.type == .income
        )
    }

    private var summary: String {
        let value = amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "BRL"))
        let date = dueDate.formatted(date: .abbreviated, time: .omitted)
        return isPaid
            ? String(localized: "\(value), pago, vencimento em \(date)")
            : String(localized: "\(value), a pagar, vencimento em \(date)")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "\(summary)")
    }

    var attributeSet: CSSearchableItemAttributeSet {
        let attributes = defaultAttributeSet
        attributes.title = name
        attributes.contentDescription = summary
        attributes.dueDate = dueDate
        attributes.keywords = [name]
        return attributes
    }
}

struct BillEntityQuery: EnumerableEntityQuery, EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [BillEntity] {
        try BillStore.bills().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func entities(matching string: String) async throws -> [BillEntity] {
        try BillStore.bills(matching: string)
    }

    @MainActor
    func allEntities() async throws -> [BillEntity] {
        try BillStore.bills()
    }

    @MainActor
    func suggestedEntities() async throws -> [BillEntity] {
        Array(try BillStore.bills().prefix(BillStore.suggestionLimit))
    }
}

@MainActor
enum BillStore {
    static let suggestionLimit = 10
    private static let indexLimit = 500

    static func bills(context: ModelContext? = nil) throws -> [BillEntity] {
        let context = context ?? ModelContext(OrganEasyModelContainer.shared)
        return try context.fetch(FetchDescriptor<MonthlyEntry>())
            .map(BillEntity.init(entry:))
            .sorted { first, second in
                if first.isPaid != second.isPaid { return !first.isPaid }
                return first.isPaid ? first.dueDate > second.dueDate : first.dueDate < second.dueDate
            }
    }

    static func bills(matching name: String, context: ModelContext? = nil) throws -> [BillEntity] {
        let all = try bills(context: context)
        let term = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty, !SummaryChatContext.isGenericName(term) else { return all }
        return all.filter { $0.name.localizedStandardContains(term) }
    }

    static func reindex(_ entries: [MonthlyEntry]) async {
        let entities = entries
            .sorted { $0.dueDate > $1.dueDate }
            .prefix(indexLimit)
            .map(BillEntity.init(entry:))
        let index = CSSearchableIndex.default()
        try? await index.deleteAppEntities(ofType: BillEntity.self)
        try? await index.indexAppEntities(Array(entities))
    }
}
