import SwiftData
import XCTest
@testable import OrganEasy

@MainActor
final class StatementParserTests: XCTestCase {
    private func parse(_ text: String, encoding: String.Encoding = .utf8) throws -> Statement {
        try StatementParser.parse(XCTUnwrap(text.data(using: encoding)))
    }

    private func day(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year!)-\(parts.month!)-\(parts.day!)"
    }

    func testSignedAmountColumn() throws {
        let statement = try parse("""
        Data,Valor,Identificador,Descrição
        01/10/2026,-50.00,abc,Transferência enviada pelo Pix - Fulano
        02/10/2026,1500.00,def,Transferência recebida - Empresa
        """)
        XCTAssertEqual(statement.format, "CSV")
        XCTAssertEqual(statement.transactions.count, 2)
        XCTAssertEqual(statement.transactions[0].type, .expense)
        XCTAssertEqual(statement.transactions[0].amount, 50)
        XCTAssertEqual(statement.transactions[0].name, "Transferência enviada pelo Pix - Fulano")
        XCTAssertEqual(statement.transactions[1].type, .income)
        XCTAssertEqual(day(statement.transactions[0].date), "2026-10-1")
    }

    func testCardFileTreatsPurchasesAsExpensesAndDropsInvoicePayment() throws {
        let statement = try parse("""
        date,title,amount
        2026-10-03,Mercado,120.50
        2026-10-04,Estorno de Loja,-20.00
        2026-10-05,Pagamento recebido,-900.00
        """)
        XCTAssertEqual(statement.transactions.map(\.name), ["Mercado", "Estorno de Loja"])
        XCTAssertEqual(statement.transactions.map(\.type), [.expense, .income])
    }

    func testSkipsSummaryLinesBeforeHeader() throws {
        let statement = try parse("""
        Extrato Conta Corrente
        Conta ;12345
        Período ;01/10/2026 a 31/10/2026
        Saldo ;1.000,00

        Data Lançamento;Histórico;Descrição;Valor;Saldo
        05/10/2026;Pix enviado;Padaria;-1.234,56;9.000,00
        """)
        XCTAssertEqual(statement.transactions.count, 1)
        XCTAssertEqual(statement.transactions[0].name, "Padaria")
        XCTAssertEqual(statement.transactions[0].amount, 1234.56)
        XCTAssertEqual(statement.transactions[0].type, .expense)
    }

    func testSplitCreditAndDebitColumnsIgnoreBalance() throws {
        let text = """
        Data;Histórico;Docto.;Crédito (R$);Débito (R$);Saldo (R$)
        01/10/2026;SALDO ANTERIOR;;;;1.000,00
        02/10/2026;COMPRA CARTAO;123;;-89,90;910,10
        03/10/2026;SALARIO;456;3.000,00;;3.910,10
        """
        let statement = try parse(text, encoding: .windowsCP1252)
        XCTAssertEqual(statement.transactions.map(\.name), ["COMPRA CARTAO", "SALARIO"])
        XCTAssertEqual(statement.transactions.map(\.amount), [89.9, 3000])
        XCTAssertEqual(statement.transactions.map(\.type), [.expense, .income])
    }

    func testCardFileChoosesRealsOverDollarsAndDescriptionOverCardholder() throws {
        let statement = try parse("""
        Data de Compra;Nome no Cartão;Final do Cartão;Categoria;Descrição;Parcela;Valor (em US$);Cotação (em R$);Valor (em R$)
        10/10/2026;FULANO;1234;Compras;LOJA;Única;2,00;5,50;11,00
        """)
        XCTAssertEqual(statement.transactions.first?.name, "LOJA")
        XCTAssertEqual(statement.transactions.first?.amount, 11)
        XCTAssertEqual(statement.transactions.first?.type, .expense)
    }

    func testHeaderlessFile() throws {
        let statement = try parse("""
        01/10/2026;SALDO ANTERIOR;100,00
        02/10/2026;PIX TRANSF FULANO;-50,00
        03/10/2026;REMUNERACAO;10,00
        """)
        XCTAssertEqual(statement.transactions.map(\.name), ["PIX TRANSF FULANO", "REMUNERACAO"])
        XCTAssertEqual(statement.transactions.map(\.type), [.expense, .income])
    }

    func testOFXWithoutClosingTags() throws {
        let statement = try parse("""
        OFXHEADER:100
        <OFX><BANKTRANLIST>
        <STMTTRN>
        <TRNTYPE>DEBIT
        <DTPOSTED>20261005120000[-3:BRT]
        <TRNAMT>-45,90
        <FITID>1
        <MEMO>Farmacia &amp; Cia
        </STMTTRN>
        <STMTTRN><TRNTYPE>CREDIT<DTPOSTED>20261006<TRNAMT>100.00<NAME>Pix</STMTTRN>
        </BANKTRANLIST></OFX>
        """)
        XCTAssertEqual(statement.format, "OFX")
        XCTAssertEqual(statement.transactions.map(\.name), ["Farmacia & Cia", "Pix"])
        XCTAssertEqual(statement.transactions.map(\.amount), [45.9, 100])
        XCTAssertEqual(day(statement.transactions[0].date), "2026-10-5")
    }

    func testHTMLTableSavedAsXLS() throws {
        let statement = try parse("""
        <html><table>
        <tr><td>Data</td><td>Lançamento</td><td>Valor (R$)</td></tr>
        <tr><td>07/10/2026</td><td>Luz</td><td>-80,00</td></tr>
        </table></html>
        """)
        XCTAssertEqual(statement.transactions.first?.name, "Luz")
    }

    func testXLSX() throws {
        let statement = try StatementParser.parse(XLSXFixture.make(rows: [
            ["Extrato"],
            ["Data", "Descrição", "Valor"],
            ["46300", "Mercado", "-12.5"],
            ["", "linha sem data", "1"]
        ]))
        XCTAssertEqual(statement.format, "Excel")
        XCTAssertEqual(statement.transactions.count, 1)
        XCTAssertEqual(statement.transactions[0].name, "Mercado")
        XCTAssertEqual(statement.transactions[0].amount, 12.5)
        XCTAssertEqual(statement.transactions[0].type, .expense)
    }

    func testLegacyExcelAndUnknownFilesAreRejected() {
        XCTAssertThrowsError(try StatementParser.parse(Data([0xD0, 0xCF, 0x11, 0xE0, 0, 0]))) {
            XCTAssertEqual($0 as? StatementError, .legacyExcel)
        }
        XCTAssertThrowsError(try parse("apenas um texto\nsem nada útil")) {
            XCTAssertEqual($0 as? StatementError, .noTransactions)
        }
    }

    func testAmounts() {
        let cases: [(String, Double?)] = [
            ("R$ 1.234,56", 1234.56), ("1,234.56", 1234.56), ("-12,34", -12.34), ("12,34-", -12.34),
            ("(12,34)", -12.34), ("12,34 D", -12.34), ("12,34 C", 12.34), ("1.234", 1234),
            ("1.234.567", 1234567), ("0.125", 0.125), ("120.5", 120.5), ("\u{2212}5,00", -5),
            ("Única", nil), ("3 parcelas", nil), ("", nil)
        ]
        for (text, expected) in cases {
            XCTAssertEqual(StatementParser.parseAmount(text), expected, text)
        }
    }

    func testDates() {
        XCTAssertEqual(StatementParser.parseDate("05/10/2026").map(day), "2026-10-5")
        XCTAssertEqual(StatementParser.parseDate("05/10/26").map(day), "2026-10-5")
        XCTAssertEqual(StatementParser.parseDate("2026-10-05T10:00:00").map(day), "2026-10-5")
        XCTAssertEqual(StatementParser.parseDate("05/10/2026 14:30").map(day), "2026-10-5")
        XCTAssertEqual(StatementParser.parseDate("46300").map(day), "2026-10-5")
        XCTAssertNil(StatementParser.parseDate("31/02/2026"))
        XCTAssertNil(StatementParser.parseDate("Total"))
    }

    func testPlanKeepsRepeatedPurchasesAndSkipsExistingOnes() throws {
        let schema = Schema([MonthlyEntry.self, RecurringEntryTemplate.self])
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        let date = try XCTUnwrap(StatementParser.parseDate("05/10/2026"))
        let coffee = StatementTransaction(date: date, name: "Café", amount: 8, type: .expense)

        let plan = StatementImportPlan(transactions: [coffee, coffee], existing: [])
        XCTAssertEqual(plan.newTransactions.count, 2)
        try plan.apply(to: container.mainContext)

        let saved = try container.mainContext.fetch(FetchDescriptor<MonthlyEntry>())
        XCTAssertEqual(saved.count, 2)
        XCTAssertEqual(saved[0].paymentDate, date)
        XCTAssertEqual(saved[0].referenceMonth, date.getReferenceMonth())

        let again = StatementImportPlan(transactions: [coffee, coffee, coffee], existing: saved)
        XCTAssertEqual(again.newTransactions.count, 1)
        XCTAssertEqual(again.duplicateCount, 2)
    }

    func testSavingsSuggestionsComeFromTheUsersSpending() throws {
        let now = try XCTUnwrap(StatementParser.parseDate("20/10/2026"))
        let september = try XCTUnwrap(StatementParser.parseDate("20/09/2026"))
        let august = try XCTUnwrap(StatementParser.parseDate("20/08/2026"))

        func expense(_ name: String, _ amount: Double, _ date: Date) -> SummaryEntry {
            SummaryEntry(
                id: UUID(), name: name, amount: amount, referenceMonth: date.getReferenceMonth(),
                dueDate: date, type: .expense, paymentDate: date
            )
        }

        var entries = [
            expense("Aluguel", 2000, now), expense("Aluguel", 2000, september), expense("Aluguel", 2000, august),
            expense("Streaming", 40, now), expense("Streaming", 40, september), expense("Streaming", 40, august),
            expense("Luz", 300, now), expense("Luz", 100, september), expense("Luz", 100, august)
        ]
        entries += (1...5).map { expense("LANCHE \($0)", 20, now) }

        let texts = SavingsAdvisor.suggestions(entries: entries, now: now).map(\.text)

        XCTAssertEqual(texts.count, 4)
        XCTAssertTrue(texts.contains { $0.contains("LANCHE") && $0.contains("5") })
        XCTAssertTrue(texts.contains { $0.contains("Luz") })
        XCTAssertTrue(texts.contains { $0.contains("Streaming") })
        XCTAssertTrue(texts.contains { $0.contains("Aluguel") })
    }

    func testSavingsWarnsWhenMonthEndsNegativeAndStaysEmptyWithoutExpenses() throws {
        let now = try XCTUnwrap(StatementParser.parseDate("20/10/2026"))
        XCTAssertTrue(SavingsAdvisor.suggestions(entries: [], now: now).isEmpty)

        let reference = now.getReferenceMonth()
        let entries = [
            SummaryEntry(id: UUID(), name: "Salário", amount: 100, referenceMonth: reference, dueDate: now, type: .income, paymentDate: nil),
            SummaryEntry(id: UUID(), name: "Cartão", amount: 150, referenceMonth: reference, dueDate: now, type: .expense, paymentDate: nil)
        ]
        let first = try XCTUnwrap(SavingsAdvisor.suggestions(entries: entries, now: now).first)
        XCTAssertTrue(first.text.contains("50"))
    }

    func testExportedFileImportsBackWithoutDuplicates() throws {
        let date = try XCTUnwrap(StatementParser.parseDate("05/10/2026"))
        let file = EntriesCSVFile(rows: [
            .init(date: date, name: "Luz; casa", amount: 1234.5, type: .expense, paymentDate: nil),
            .init(date: date, name: "Salário", amount: 5000, type: .income, paymentDate: date)
        ])

        let statement = try StatementParser.parse(file.data)

        XCTAssertEqual(statement.transactions.map(\.name), ["Luz; casa", "Salário"])
        XCTAssertEqual(statement.transactions.map(\.amount), [1234.5, 5000])
        XCTAssertEqual(statement.transactions.map(\.type), [.expense, .income])
    }
}

/// Monta um .xlsx mínimo com arquivos sem compressão.
private enum XLSXFixture {
    static func make(rows: [[String]]) -> Data {
        var shared: [String] = []
        var sheet = "<worksheet><sheetData>"
        for (rowIndex, row) in rows.enumerated() {
            sheet += "<row r=\"\(rowIndex + 1)\">"
            for (column, value) in row.enumerated() where !value.isEmpty {
                let reference = "\(Character(UnicodeScalar(65 + column)!))\(rowIndex + 1)"
                if Double(value) != nil {
                    sheet += "<c r=\"\(reference)\"><v>\(value)</v></c>"
                } else {
                    sheet += "<c r=\"\(reference)\" t=\"s\"><v>\(shared.count)</v></c>"
                    shared.append(value)
                }
            }
            sheet += "</row>"
        }
        sheet += "</sheetData></worksheet>"
        let strings = "<sst>" + shared.map { "<si><t>\($0)</t></si>" }.joined() + "</sst>"
        return zip(["xl/sharedStrings.xml": Data(strings.utf8), "xl/worksheets/sheet1.xml": Data(sheet.utf8)])
    }

    private static func zip(_ files: [String: Data]) -> Data {
        func le16(_ value: Int) -> Data { Data([UInt8(value & 0xFF), UInt8(value >> 8 & 0xFF)]) }
        func le32(_ value: Int) -> Data { le16(value & 0xFFFF) + le16(value >> 16 & 0xFFFF) }

        var body = Data()
        var directory = Data()
        for (name, content) in files {
            let offset = body.count
            let fileName = Data(name.utf8)
            body += le32(0x0403_4B50) + le16(20) + le16(0) + le16(0) + le16(0) + le16(0) + le32(0)
            body += le32(content.count) + le32(content.count) + le16(fileName.count) + le16(0) + fileName + content
            directory += le32(0x0201_4B50) + le16(20) + le16(20) + le16(0) + le16(0) + le16(0) + le16(0) + le32(0)
            directory += le32(content.count) + le32(content.count) + le16(fileName.count) + le16(0) + le16(0)
            directory += le16(0) + le16(0) + le32(0) + le32(offset) + fileName
        }
        let end = le32(0x0605_4B50) + le16(0) + le16(0) + le16(files.count) + le16(files.count)
            + le32(directory.count) + le32(body.count) + le16(0)
        return body + directory + end
    }
}
