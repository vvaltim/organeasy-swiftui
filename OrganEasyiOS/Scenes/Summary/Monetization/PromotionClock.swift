import Foundation
import Security

/// Guarda quando o usuário abriu o Resumo pela primeira vez. Fica no Keychain,
/// que sobrevive à reinstalação, para o prazo de 24 horas ser único e real.
enum PromotionClock {
    static let duration: TimeInterval = 24 * 60 * 60

    private static let account = "promotionStartDate"

    static func startIfNeeded(now: Date = .now) -> Date {
        if let saved = load() { return saved }
        save(now)
        return now
    }

    static func reset() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private static var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
    }

    private static func load() -> Date? {
        var query = baseQuery
        query[kSecReturnData as String] = true

        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data,
              let seconds = Double(String(decoding: data, as: UTF8.self)) else {
            return nil
        }
        return Date(timeIntervalSince1970: seconds)
    }

    private static func save(_ date: Date) {
        var query = baseQuery
        query[kSecValueData as String] = Data(String(date.timeIntervalSince1970).utf8)
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(query as CFDictionary, nil)
    }
}
