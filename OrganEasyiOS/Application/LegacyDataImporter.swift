import Foundation
import OSLog
import SQLite3
import SwiftData

/// Traz os dados da versão 1.x (Core Data) para a versão atual (SwiftData).
///
/// O banco antigo nunca é alterado: a leitura acontece numa cópia temporária.
/// Bancos e evoluções não têm equivalente no modelo atual e continuam só no
/// arquivo antigo, que fica guardado no aparelho.
enum LegacyDataImporter {
    struct Result: Equatable {
        var entries = 0
        var templates = 0
    }

    enum ImportError: Error {
        case unreadableStore(String)
    }

    static let completedKey = "legacyCoreDataImportCompleted"

    static var defaultStoreURL: URL {
        URL.applicationSupportDirectory.appending(path: "OrganEasy.sqlite")
    }

    /// Roda uma vez. Se falhar, tenta de novo na próxima abertura do app.
    static func runIfNeeded(
        into context: ModelContext,
        storeURL: URL = defaultStoreURL,
        defaults: UserDefaults = .standard
    ) {
        guard !defaults.bool(forKey: completedKey) else { return }
        guard FileManager.default.fileExists(atPath: storeURL.path(percentEncoded: false)) else { return }

        do {
            _ = try importStore(at: storeURL, into: context)
            defaults.set(true, forKey: completedKey)
        } catch {
            Logger(subsystem: "OrganEasy", category: "LegacyDataImporter")
                .error("Falha ao importar dados antigos: \(String(describing: error), privacy: .public)")
        }
    }

    @discardableResult
    static func importStore(at storeURL: URL, into context: ModelContext) throws -> Result {
        let rows = try readRows(from: storeURL)
        var result = Result()

        var knownEntries = Set(try context.fetch(FetchDescriptor<MonthlyEntry>()).map(entryKey))
        for row in rows.transactions {
            let entry = MonthlyEntry(
                name: row.name,
                amount: row.amount,
                referenceMonth: row.dueDate.getReferenceMonth(),
                dueDate: row.dueDate,
                type: row.isIncome ? .income : .expense
            )
            if let id = row.id { entry.id = id }
            entry.paymentDate = row.paymentDate

            guard !knownEntries.contains(entryKey(entry)) else { continue }
            context.insert(entry)
            result.entries += 1
        }
        knownEntries.removeAll()

        let knownTemplates = Set(try context.fetch(FetchDescriptor<RecurringEntryTemplate>()).map(templateKey))
        for row in rows.bills {
            let template = RecurringEntryTemplate(
                dueDay: Calendar.current.component(.day, from: row.dueDate ?? .now),
                enabled: true,
                name: row.name,
                type: .expense
            )
            if let id = row.id { template.id = id }

            guard !knownTemplates.contains(templateKey(template)) else { continue }
            context.insert(template)
            result.templates += 1
        }

        try context.save()
        return result
    }

    // MARK: - Chaves de duplicidade

    private static func entryKey(_ entry: MonthlyEntry) -> String {
        "\(entry.name)|\(entry.amount)|\(entry.dueDate.timeIntervalSinceReferenceDate)"
    }

    private static func templateKey(_ template: RecurringEntryTemplate) -> String {
        "\(template.name)|\(template.dueDay)"
    }

    // MARK: - Leitura do banco antigo

    private struct Rows {
        var transactions: [TransactionRow] = []
        var bills: [BillRow] = []
    }

    private struct TransactionRow {
        let id: UUID?
        let name: String
        let amount: Double
        let dueDate: Date
        let paymentDate: Date?
        let isIncome: Bool
    }

    private struct BillRow {
        let id: UUID?
        let name: String
        let dueDate: Date?
    }

    private static func readRows(from storeURL: URL) throws -> Rows {
        let fileManager = FileManager.default
        let folder = fileManager.temporaryDirectory.appending(path: "legacy-\(UUID().uuidString)")
        try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: folder) }

        // O WAL guarda gravações recentes, então os três arquivos são copiados juntos.
        let copyURL = folder.appending(path: storeURL.lastPathComponent)
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(filePath: storeURL.path(percentEncoded: false) + suffix)
            guard fileManager.fileExists(atPath: source.path(percentEncoded: false)) else { continue }
            try fileManager.copyItem(at: source, to: URL(filePath: copyURL.path(percentEncoded: false) + suffix))
        }

        var database: OpaquePointer?
        defer { sqlite3_close(database) }
        guard sqlite3_open_v2(copyURL.path(percentEncoded: false), &database, SQLITE_OPEN_READWRITE, nil) == SQLITE_OK else {
            throw ImportError.unreadableStore(message(from: database))
        }

        var rows = Rows()
        try forEachRow(in: "ZTRANSACTION", database: database) { row in
            guard let dueDate = row.date("ZDUEDATE") else { return }
            rows.transactions.append(TransactionRow(
                id: row.uuid("ZID"),
                name: row.text("ZDESCRIPTIONTEXT") ?? "",
                amount: row.double("ZAMOUNT") ?? 0,
                dueDate: dueDate,
                paymentDate: row.date("ZPAYMENTDATE"),
                isIncome: (row.double("ZISINCOME") ?? 0) != 0
            ))
        }
        try forEachRow(in: "ZRECURRINGBILL", database: database) { row in
            rows.bills.append(BillRow(
                id: row.uuid("ZID"),
                name: row.text("ZNAME") ?? "",
                dueDate: row.date("ZDUEDATE")
            ))
        }
        return rows
    }

    private static func forEachRow(
        in table: String,
        database: OpaquePointer?,
        _ body: (LegacyRow) -> Void
    ) throws {
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }

        let prepared = sqlite3_prepare_v2(database, "SELECT * FROM \(table)", -1, &statement, nil)
        if prepared == SQLITE_ERROR { return } // Tabela criada só em versões posteriores.
        guard prepared == SQLITE_OK else { throw ImportError.unreadableStore(message(from: database)) }

        let row = LegacyRow(statement: statement)
        var step = sqlite3_step(statement)
        while step == SQLITE_ROW {
            body(row)
            step = sqlite3_step(statement)
        }
        guard step == SQLITE_DONE else { throw ImportError.unreadableStore(message(from: database)) }
    }

    private static func message(from database: OpaquePointer?) -> String {
        database.flatMap { sqlite3_errmsg($0) }.map { String(cString: $0) } ?? "erro desconhecido"
    }
}

/// Lê a linha atual pelo nome da coluna, para aceitar bancos sem colunas mais novas.
private struct LegacyRow {
    private let statement: OpaquePointer?
    private let columns: [String: Int32]

    init(statement: OpaquePointer?) {
        self.statement = statement
        var columns: [String: Int32] = [:]
        for index in 0..<sqlite3_column_count(statement) {
            if let name = sqlite3_column_name(statement, index) {
                columns[String(cString: name)] = index
            }
        }
        self.columns = columns
    }

    private func index(_ name: String) -> Int32? {
        guard let index = columns[name], sqlite3_column_type(statement, index) != SQLITE_NULL else { return nil }
        return index
    }

    func text(_ name: String) -> String? {
        guard let index = index(name), let value = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: value)
    }

    func double(_ name: String) -> Double? {
        index(name).map { sqlite3_column_double(statement, $0) }
    }

    /// O Core Data grava datas em segundos desde 1º de janeiro de 2001.
    func date(_ name: String) -> Date? {
        double(name).map(Date.init(timeIntervalSinceReferenceDate:))
    }

    func uuid(_ name: String) -> UUID? {
        guard
            let index = index(name),
            sqlite3_column_bytes(statement, index) == 16,
            let bytes = sqlite3_column_blob(statement, index)
        else { return nil }
        return NSUUID(uuidBytes: bytes.assumingMemoryBound(to: UInt8.self)) as UUID
    }
}
