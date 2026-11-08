import Foundation

struct StatementTransaction: Equatable, Sendable {
    let date: Date
    let name: String
    let amount: Double
    let type: EntryType

    var inverted: StatementTransaction {
        StatementTransaction(date: date, name: name, amount: amount, type: type == .income ? .expense : .income)
    }
}

struct Statement: Identifiable, Sendable {
    let id = UUID()
    let format: String
    let transactions: [StatementTransaction]
}

enum StatementError: Error, Equatable {
    case tooLarge
    case legacyExcel
    case noTransactions
}

enum StatementParser {
    static let maxFileSize = 20 * 1024 * 1024

    static func parse(_ data: Data) throws -> Statement {
        guard data.count <= maxFileSize else { throw StatementError.tooLarge }

        let statement: Statement
        if data.starts(with: [0x50, 0x4B, 0x03, 0x04]) {
            statement = Statement(format: "Excel", transactions: transactions(fromRows: try XLSXReader.rows(from: data)))
        } else if data.starts(with: [0xD0, 0xCF, 0x11, 0xE0]) {
            throw StatementError.legacyExcel
        } else {
            let text = decode(data)
            let lowered = text.prefix(4096).lowercased()
            if text.range(of: "<stmttrn>", options: .caseInsensitive) != nil {
                statement = Statement(format: "OFX", transactions: parseOFX(text))
            } else if lowered.contains("<table") || lowered.contains("<html") {
                statement = Statement(format: "Excel", transactions: transactions(fromRows: parseHTMLTable(text)))
            } else {
                statement = Statement(format: "CSV", transactions: transactions(fromRows: parseDelimited(text)))
            }
        }

        guard !statement.transactions.isEmpty else { throw StatementError.noTransactions }
        return statement
    }

    static func decode(_ data: Data) -> String {
        if data.starts(with: [0xFF, 0xFE]), let text = String(data: data, encoding: .utf16LittleEndian) {
            return text.replacingOccurrences(of: "\u{FEFF}", with: "")
        }
        if data.starts(with: [0xFE, 0xFF]), let text = String(data: data, encoding: .utf16BigEndian) {
            return text.replacingOccurrences(of: "\u{FEFF}", with: "")
        }
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .windowsCP1252)
            ?? String(decoding: data, as: UTF8.self)
        return text.replacingOccurrences(of: "\u{FEFF}", with: "")
    }

    private static func parseOFX(_ text: String) -> [StatementTransaction] {
        let blocks = text
            .replacingOccurrences(of: "<STMTTRN>", with: "\u{1}", options: .caseInsensitive)
            .components(separatedBy: "\u{1}")
            .dropFirst()

        return blocks.compactMap { block in
            guard
                let rawDate = ofxValue("DTPOSTED", in: block),
                let date = parseDate(String(rawDate.prefix(8))),
                let rawAmount = ofxValue("TRNAMT", in: block),
                let amount = parseAmount(rawAmount),
                amount != .zero
            else { return nil }

            let name = ofxValue("MEMO", in: block) ?? ofxValue("NAME", in: block) ?? ""
            return makeTransaction(date: date, name: decodeEntities(name), signedAmount: amount)
        }
    }

    private static func ofxValue(_ tag: String, in block: String) -> String? {
        guard
            let open = block.range(of: "<\(tag)>", options: .caseInsensitive),
            let end = block[open.upperBound...].firstIndex(where: { $0 == "<" || $0.isNewline })
                ?? Optional(block.endIndex)
        else { return nil }
        let value = block[open.upperBound..<end].trimmingCharacters(in: .whitespaces)
        return value.isEmpty ? nil : value
    }

    private static func parseHTMLTable(_ text: String) -> [[String]] {
        matches(of: "<tr[^>]*>(.*?)</tr>", in: text).map { row in
            matches(of: "<t[dh][^>]*>(.*?)</t[dh]>", in: row).map { cell in
                let plain = cell.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                return decodeEntities(plain).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    private static func matches(of pattern: String, in text: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return [] }
        let source = text as NSString
        return regex.matches(in: text, range: NSRange(location: 0, length: source.length))
            .map { source.substring(with: $0.range(at: 1)) }
    }

    private static func decodeEntities(_ text: String) -> String {
        [("&nbsp;", " "), ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"), ("&quot;", "\""), ("&#39;", "'")]
            .reduce(text) { $0.replacingOccurrences(of: $1.0, with: $1.1, options: .caseInsensitive) }
    }

    static func parseDelimited(_ text: String) -> [[String]] {
        let delimiter = detectDelimiter(in: text)
        var rows: [[String]] = []
        var row: [String] = []
        var cell = ""
        var isQuoted = false

        func closeRow() {
            row.append(cell)
            cell = ""
            if row.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                rows.append(row.map { $0.trimmingCharacters(in: .whitespaces) })
            }
            row = []
        }

        var characters = Array(text)[...]
        while let character = characters.popFirst() {
            if isQuoted {
                if character == "\"" {
                    if characters.first == "\"" {
                        cell.append("\"")
                        characters.removeFirst()
                    } else {
                        isQuoted = false
                    }
                } else {
                    cell.append(character)
                }
            } else if character == "\"" && cell.isEmpty {
                isQuoted = true
            } else if character == delimiter {
                row.append(cell)
                cell = ""
            } else if character.isNewline {
                closeRow()
            } else {
                cell.append(character)
            }
        }
        if !cell.isEmpty || !row.isEmpty { closeRow() }
        return rows
    }

    private static func detectDelimiter(in text: String) -> Character {
        let sample = text.split(whereSeparator: \.isNewline).prefix(30)
        guard !sample.isEmpty else { return "," }
        for delimiter in [";", "\t"] as [Character] {
            if sample.reduce(0, { $0 + $1.filter { $0 == delimiter }.count }) >= sample.count / 2 + 1 {
                return delimiter
            }
        }
        let commas = sample.reduce(0) { $0 + $1.filter { $0 == "," }.count }
        let pipes = sample.reduce(0) { $0 + $1.filter { $0 == "|" }.count }
        return pipes > commas ? "|" : ","
    }

    private struct Columns {
        var date: Int
        var descriptions: [Int]
        var amount: Int?
        var debit: Int?
        var credit: Int?
        var direction: Int?
        var isCard: Bool
    }

    static func normalized(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR"))
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
    }

    private static func detectColumns(in header: [String]) -> Columns? {
        let names = header.map(normalized)

        func first(_ predicate: (String) -> Bool) -> Int? {
            names.firstIndex(where: predicate)
        }

        guard let date = first({ $0 == "data" || $0 == "date" })
            ?? first({ $0.hasPrefix("data") || $0.hasPrefix("dt ") || $0 == "dt" })
        else { return nil }

        let foreign = ["saldo", "us$", "usd", "dolar", "cotacao"]
        let isMoney: (String) -> Bool = { name in
            (name.contains("valor") || name == "amount" || name == "value" || name == "montante" || name == "quantia")
                && !foreign.contains(where: name.contains)
        }
        let amount = first { isMoney($0) && $0.contains("r$") } ?? first(isMoney)

        let debit = first { ($0.hasPrefix("debito") || $0.hasPrefix("saida") || $0.hasPrefix("valor debito")) && !$0.contains("saldo") }
        let credit = first { ($0.hasPrefix("credito") || $0.hasPrefix("entrada") || $0.hasPrefix("valor credito")) && !$0.contains("saldo") }
        guard amount != nil || debit != nil || credit != nil else { return nil }

        let direction = first {
            ["tipo", "d/c", "c/d", "deb/cred", "natureza", "tipo lancamento", "tipo de lancamento"].contains($0)
        }

        let taken = Set([date, amount, debit, credit, direction].compactMap { $0 })
        let rules: [(String) -> Bool] = [
            { $0.contains("descricao") || $0.contains("description") },
            { $0 == "title" || $0 == "memo" },
            { $0.contains("estabelecimento") || $0.contains("favorecido") },
            { $0.contains("historico") },
            { $0.contains("lancamento") },
            { $0 == "detalhes" || $0 == "nome" },
            { $0 == "identificador" }
        ]
        var descriptions: [Int] = []
        for rule in rules {
            for (index, name) in names.enumerated() where rule(name) && !taken.contains(index) && !descriptions.contains(index) {
                descriptions.append(index)
            }
        }
        guard !descriptions.isEmpty else { return nil }

        let cardMarkers = ["parcela", "final do cartao", "nome no cartao", "data de compra", "data da compra"]
        let isCard = names.contains("title") && amount != nil
            || names.contains(where: { name in cardMarkers.contains(where: name.contains) })

        return Columns(
            date: date,
            descriptions: descriptions,
            amount: amount,
            debit: debit,
            credit: credit,
            direction: direction,
            isCard: isCard
        )
    }

    static func transactions(fromRows rows: [[String]]) -> [StatementTransaction] {
        for (index, row) in rows.prefix(40).enumerated() {
            if let columns = detectColumns(in: row) {
                return transactions(from: rows.dropFirst(index + 1), columns: columns)
            }
        }
        return headerlessTransactions(from: rows)
    }

    private static func transactions(from rows: ArraySlice<[String]>, columns: Columns) -> [StatementTransaction] {
        func cell(_ row: [String], _ index: Int?) -> String {
            guard let index, row.indices.contains(index) else { return "" }
            return row[index]
        }

        var parsed: [(date: Date, name: String, amount: Double)] = []
        for row in rows {
            guard let date = parseDate(cell(row, columns.date)) else { continue }
            let name = columns.descriptions.lazy.map { cell(row, $0) }.first { !$0.isEmpty } ?? ""
            guard !isBalanceLine(name) else { continue }

            var amount: Double?
            if let debit = parseAmount(cell(row, columns.debit)), debit != .zero {
                amount = -abs(debit)
            } else if let credit = parseAmount(cell(row, columns.credit)), credit != .zero {
                amount = abs(credit)
            } else if let value = parseAmount(cell(row, columns.amount)) {
                amount = value
                let direction = normalized(cell(row, columns.direction))
                if direction.hasPrefix("d") || direction.hasPrefix("saida") {
                    amount = -abs(value)
                } else if direction.hasPrefix("c") || direction.hasPrefix("entrada") {
                    amount = abs(value)
                }
            }

            if let amount, amount != .zero {
                parsed.append((date, name, amount))
            }
        }

        let isSingleColumn = columns.amount != nil && columns.debit == nil && columns.credit == nil && columns.direction == nil
        let positives = parsed.filter { $0.amount > .zero }.count
        let looksLikeCard = isSingleColumn && parsed.count >= 3 && Double(positives) / Double(parsed.count) >= 0.8

        if isSingleColumn && (columns.isCard || looksLikeCard) {
            return parsed.compactMap { item in
                if item.amount < .zero, normalized(item.name).contains("pagamento") { return nil }
                return makeTransaction(date: item.date, name: item.name, signedAmount: -item.amount)
            }
        }
        return parsed.map { makeTransaction(date: $0.date, name: $0.name, signedAmount: $0.amount) }
    }

    private static func headerlessTransactions(from rows: [[String]]) -> [StatementTransaction] {
        rows.compactMap { row in
            let cells = row.filter { !$0.isEmpty }
            guard
                cells.count >= 3,
                let date = parseDate(cells[0]),
                let amount = parseAmount(cells[cells.count - 1]),
                amount != .zero
            else { return nil }

            let name = cells[1..<(cells.count - 1)].max { $0.count < $1.count } ?? ""
            guard !isBalanceLine(name) else { return nil }
            return makeTransaction(date: date, name: name, signedAmount: amount)
        }
    }

    private static func isBalanceLine(_ name: String) -> Bool {
        let name = normalized(name)
        return name.hasPrefix("saldo") || name.hasPrefix("sdo ")
    }

    private static func makeTransaction(date: Date, name: String, signedAmount: Double) -> StatementTransaction {
        StatementTransaction(
            date: date,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: abs(signedAmount),
            type: signedAmount < .zero ? .expense : .income
        )
    }

    static func parseAmount(_ raw: String) -> Double? {
        var text = raw
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: "BRL", with: "")
            .replacingOccurrences(of: " ", with: "")
        guard !text.isEmpty else { return nil }

        var isNegative = false
        if text.hasPrefix("("), text.hasSuffix(")") {
            isNegative = true
            text = String(text.dropFirst().dropLast())
        }
        if let last = text.last, "DdCc".contains(last) {
            isNegative = isNegative || "Dd".contains(last)
            text.removeLast()
        }
        if text.hasPrefix("-") {
            isNegative = true
            text.removeFirst()
        } else if text.hasSuffix("-") {
            isNegative = true
            text.removeLast()
        } else if text.hasPrefix("+") {
            text.removeFirst()
        }

        guard
            !text.isEmpty,
            text.first?.isNumber == true,
            text.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "," || $0 == ".") })
        else { return nil }

        var decimalSeparator: Character?
        let commas = text.filter { $0 == "," }.count
        let dots = text.filter { $0 == "." }.count
        if commas > 0, dots > 0 {
            decimalSeparator = text.lastIndex(of: ",")! > text.lastIndex(of: ".")! ? "," : "."
        } else if commas + dots == 1 {
            let separator: Character = commas == 1 ? "," : "."
            let parts = text.split(separator: separator, omittingEmptySubsequences: false)
            if parts[1].count != 3 || parts[0] == "0" { decimalSeparator = separator }
        }

        var digits = ""
        for character in text {
            if character == decimalSeparator {
                digits.append(".")
            } else if character.isNumber {
                digits.append(character)
            }
        }
        guard let value = Double(digits) else { return nil }
        return isNegative ? -value : value
    }

    static func parseDate(_ raw: String) -> Date? {
        let text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        if let serial = Double(text), text.count >= 5, !text.allSatisfy(\.isNumber) || text.count == 5,
           (20_000...80_000).contains(serial) {
            return makeDate(year: 1899, month: 12, day: 30 + Int(serial))
        }

        let token = text.split(whereSeparator: { $0 == " " || $0 == "T" }).first.map(String.init) ?? text
        if token.count == 8, token.allSatisfy(\.isNumber),
           let year = Int(token.prefix(4)), let month = Int(token.dropFirst(4).prefix(2)), let day = Int(token.suffix(2)) {
            return makeDate(year: year, month: month, day: day)
        }

        let parts = token.split(whereSeparator: { "/-.".contains($0) }).compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        if token.prefix(4).allSatisfy(\.isNumber), parts[0] >= 1000 {
            return makeDate(year: parts[0], month: parts[1], day: parts[2])
        }
        let year = parts[2] < 100 ? 2000 + parts[2] : parts[2]
        if parts[1] > 12 {
            return makeDate(year: year, month: parts[0], day: parts[1])
        }
        return makeDate(year: year, month: parts[1], day: parts[0])
    }

    private static func makeDate(year: Int, month: Int, day: Int) -> Date? {
        var components = DateComponents(year: year, month: month, day: day, hour: 12)
        let calendar = Calendar(identifier: .gregorian)
        if year == 1899 {
            components.day = day
            return calendar.date(from: components)
        }
        guard (2000...2100).contains(year), (1...12).contains(month), (1...31).contains(day) else { return nil }
        components.calendar = calendar
        guard components.isValidDate else { return nil }
        return calendar.date(from: components)
    }
}
