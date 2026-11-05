import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// CSV com `;` e vírgula decimal, que abre direto no Excel e volta pelo Importar extrato.
struct EntriesCSVFile: Transferable {
    struct Row {
        let date: Date
        let name: String
        let amount: Double
        let type: EntryType
        let paymentDate: Date?
    }

    let rows: [Row]

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { $0.data }
            .suggestedFileName("OrganEasy.csv")
    }

    var data: Data {
        let lines = rows
            .sorted { $0.date < $1.date }
            .map { row in
                let signed = row.type == .expense ? -row.amount : row.amount
                let amount = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), signed)
                    .replacingOccurrences(of: ".", with: ",")
                return [
                    Self.format(row.date),
                    Self.escape(row.name),
                    amount,
                    row.paymentDate.map(Self.format) ?? ""
                ].joined(separator: ";")
            }
        let text = (["Data;Descrição;Valor;Pago em"] + lines).joined(separator: "\r\n") + "\r\n"
        return Data([0xEF, 0xBB, 0xBF]) + Data(text.utf8)
    }

    private static func format(_ date: Date) -> String {
        let day = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%02d/%02d/%04d", day.day ?? 0, day.month ?? 0, day.year ?? 0)
    }

    private static func escape(_ text: String) -> String {
        guard text.contains(where: { $0 == ";" || $0 == "\"" || $0.isNewline }) else { return text }
        return "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
