import Foundation

extension Double {
    func getLocalCurrency() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(for: self) ?? "-"
    }
}
