import AppIntents

enum EntryType: String, Codable, AppEnum, CaseIterable, Sendable {
    case expense
    case income

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Categoria"

    static var caseDisplayRepresentations: [EntryType: DisplayRepresentation] = [
        .expense: "Despesa",
        .income: "Receita"
    ]
}
