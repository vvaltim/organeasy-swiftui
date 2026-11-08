import Compression
import Foundation

enum XLSXReader {
    enum ReadError: Error {
        case invalidFile
    }

    private static let maxUncompressedSize = 200 * 1024 * 1024

    static func rows(from data: Data) throws -> [[String]] {
        let files = try unzip(data)
        let sharedStrings = files["xl/sharedStrings.xml"].map(SharedStringsParser.parse) ?? []
        let sheetName = files.keys
            .filter { $0.hasPrefix("xl/worksheets/") && $0.hasSuffix(".xml") }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            .first
        guard let sheetName, let sheet = files[sheetName] else { throw ReadError.invalidFile }
        return SheetParser.parse(sheet, sharedStrings: sharedStrings)
    }

    private static func unzip(_ data: Data) throws -> [String: Data] {
        let bytes = [UInt8](data)
        func uint16(_ offset: Int) -> Int { Int(bytes[offset]) | Int(bytes[offset + 1]) << 8 }
        func uint32(_ offset: Int) -> Int { uint16(offset) | uint16(offset + 2) << 16 }

        guard bytes.count >= 22 else { throw ReadError.invalidFile }
        var end = bytes.count - 22
        let limit = max(0, end - 65_535)
        while end >= limit, !(bytes[end] == 0x50 && bytes[end + 1] == 0x4B && bytes[end + 2] == 5 && bytes[end + 3] == 6) {
            end -= 1
        }
        guard end >= limit else { throw ReadError.invalidFile }

        var files: [String: Data] = [:]
        var position = uint32(end + 16)
        var total = 0

        for _ in 0..<uint16(end + 10) {
            guard position + 46 <= bytes.count, uint32(position) == 0x0201_4B50 else { throw ReadError.invalidFile }
            let method = uint16(position + 10)
            let compressedSize = uint32(position + 20)
            let size = uint32(position + 24)
            let nameLength = uint16(position + 28)
            let extraLength = uint16(position + 30)
            let commentLength = uint16(position + 32)
            let localHeader = uint32(position + 42)
            guard position + 46 + nameLength <= bytes.count else { throw ReadError.invalidFile }
            let name = String(decoding: bytes[(position + 46)..<(position + 46 + nameLength)], as: UTF8.self)
            position += 46 + nameLength + extraLength + commentLength

            guard name.hasPrefix("xl/"), name.hasSuffix(".xml") else { continue }
            guard localHeader + 30 <= bytes.count else { throw ReadError.invalidFile }
            let start = localHeader + 30 + uint16(localHeader + 26) + uint16(localHeader + 28)
            guard start + compressedSize <= bytes.count else { throw ReadError.invalidFile }

            total += size
            guard total <= maxUncompressedSize else { throw ReadError.invalidFile }

            let compressed = bytes[start..<(start + compressedSize)]
            switch method {
            case 0:
                files[name] = Data(compressed)
            case 8:
                files[name] = try inflate(Array(compressed), size: size)
            default:
                throw ReadError.invalidFile
            }
        }
        return files
    }

    private static func inflate(_ source: [UInt8], size: Int) throws -> Data {
        guard size > 0 else { return Data() }
        var output = [UInt8](repeating: 0, count: size)
        let written = compression_decode_buffer(&output, size, source, source.count, nil, COMPRESSION_ZLIB)
        guard written == size else { throw ReadError.invalidFile }
        return Data(output)
    }
}

private final class SharedStringsParser: NSObject, XMLParserDelegate {
    private var strings: [String] = []
    private var current = ""
    private var isInsideText = false

    static func parse(_ data: Data) -> [String] {
        let delegate = SharedStringsParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.strings
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        if elementName == "si" { current = "" }
        if elementName == "t" { isInsideText = true }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInsideText { current += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        if elementName == "t" { isInsideText = false }
        if elementName == "si" { strings.append(current) }
    }
}

private final class SheetParser: NSObject, XMLParserDelegate {
    private let sharedStrings: [String]
    private var rows: [[String]] = []
    private var row: [String] = []
    private var column = 0
    private var cellType = ""
    private var value = ""
    private var isInsideValue = false

    private init(sharedStrings: [String]) {
        self.sharedStrings = sharedStrings
    }

    static func parse(_ data: Data, sharedStrings: [String]) -> [[String]] {
        let delegate = SheetParser(sharedStrings: sharedStrings)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.rows
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName: String?, attributes: [String: String] = [:]) {
        switch elementName {
        case "row":
            row = []
        case "c":
            cellType = attributes["t"] ?? ""
            column = Self.columnIndex(attributes["r"]) ?? row.count
            value = ""
        case "v", "t":
            isInsideValue = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if isInsideValue { value += string }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName: String?) {
        switch elementName {
        case "v", "t":
            isInsideValue = false
        case "c":
            while row.count <= column { row.append("") }
            if cellType == "s", let index = Int(value), sharedStrings.indices.contains(index) {
                row[column] = sharedStrings[index].trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                row[column] = value.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        case "row":
            if row.contains(where: { !$0.isEmpty }) { rows.append(row) }
        default:
            break
        }
    }

    private static func columnIndex(_ reference: String?) -> Int? {
        guard let reference else { return nil }
        var index = 0
        for scalar in reference.unicodeScalars {
            guard (65...90).contains(scalar.value) else { break }
            index = index * 26 + Int(scalar.value) - 64
        }
        return index > 0 ? index - 1 : nil
    }
}
