import Foundation
import SwiftUI

/// Month summary the app writes to the App Group so the widgets can read it
/// without opening the SwiftData/CloudKit store.
nonisolated struct FinanceSnapshot: Codable, Equatable, Sendable {
    struct Bill: Codable, Equatable, Sendable, Identifiable {
        var id: UUID
        var name: String
        var amount: Double
        var dueDate: Date
        var isIncome: Bool
    }

    var monthStart: Date
    var income: Double
    var expense: Double
    var paidExpense: Double
    /// Expense total per day of the month (index 0 = day 1), by due date.
    var dailyExpenses: [Double]
    /// Unpaid expenses of the month (overdue first), sorted by due date.
    var upcoming: [Bill]
    var currencyCode: String
    var updatedAt: Date

    var balance: Double { income - expense }
    var pendingExpense: Double { max(expense - paidExpense, .zero) }
    var paidRatio: Double { expense > .zero ? min(paidExpense / expense, 1) : .zero }

    var averagePerDay: Double {
        let days = dailyExpenses.count
        return days > .zero ? expense / Double(days) : .zero
    }

    static let empty = FinanceSnapshot(
        monthStart: Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now,
        income: .zero,
        expense: .zero,
        paidExpense: .zero,
        dailyExpenses: Array(repeating: .zero, count: 30),
        upcoming: [],
        currencyCode: Locale.current.currency?.identifier ?? "BRL",
        updatedAt: .now
    )

    static let sample: FinanceSnapshot = {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        func day(_ value: Int) -> Date { calendar.date(byAdding: .day, value: value - 1, to: start) ?? start }
        var daily = Array(repeating: 0.0, count: 30)
        for (index, value) in [(4, 1450.0), (9, 189.9), (11, 129.9), (14, 312.4), (19, 98.5), (24, 640.0), (27, 74.9)] {
            daily[index] = value
        }
        return FinanceSnapshot(
            monthStart: start,
            income: 5800,
            expense: daily.reduce(.zero, +),
            paidExpense: 1769.8,
            dailyExpenses: daily,
            upcoming: [
                Bill(id: UUID(), name: "Internet", amount: 129.9, dueDate: day(12), isIncome: false),
                Bill(id: UUID(), name: "Cartão Nubank", amount: 640, dueDate: day(25), isIncome: false),
                Bill(id: UUID(), name: "Academia", amount: 74.9, dueDate: day(28), isIncome: false)
            ],
            currencyCode: Locale.current.currency?.identifier ?? "BRL",
            updatedAt: .now
        )
    }()
}

nonisolated enum FinanceSnapshotStore {
    static let appGroup = "group.br.com.vanio.walter.app"
    static let widgetKind = "OrganEasyWidgets"
    private static let key = "financeSnapshot.v1"

    private static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func load() -> FinanceSnapshot? {
        guard let data = defaults?.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(FinanceSnapshot.self, from: data)
    }

    @discardableResult
    static func save(_ snapshot: FinanceSnapshot) -> Bool {
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return false }
        if defaults.data(forKey: key) == data { return false }
        defaults.set(data, forKey: key)
        return true
    }
}

/// Picks an SF Symbol and tint for a bill from its name, so lists and widgets get
/// colorful icon tiles without asking the user for a category.
nonisolated enum EntryStyle {
    private static let rules: [(keywords: [String], symbol: String, color: Color)] = [
        (["aluguel", "rent", "alquiler", "loyer", "affitto", "condom", "casa", "home", "iptu"], "house.fill", .orange),
        (["luz", "energia", "enel", "cemig", "light", "electric", "luce"], "bolt.fill", .yellow),
        (["água", "agua", "sabesp", "water", "eau", "acqua"], "drop.fill", .cyan),
        (["internet", "wifi", "vivo", "claro", "tim", "oi ", "fibra", "telefone", "celular", "phone"], "wifi", .indigo),
        (["cartão", "cartao", "card", "nubank", "inter", "itaú", "itau", "bradesco", "santander", "fatura", "tarjeta", "carte", "carta"], "creditcard.fill", .purple),
        (["mercado", "supermerc", "market", "feira", "food", "comida", "ifood", "restaurante"], "cart.fill", .green),
        (["netflix", "spotify", "disney", "prime", "youtube", "hbo", "max", "assinatura", "streaming", "apple"], "play.rectangle.fill", .red),
        (["academia", "gym", "smart fit", "esporte", "palestra", "gimnasio"], "figure.run", .mint),
        (["carro", "car", "combust", "gasolina", "uber", "99", "ipva", "seguro", "transporte", "ônibus"], "car.fill", .blue),
        (["escola", "faculdade", "curso", "school", "college", "école", "scuola", "educa"], "graduationcap.fill", .teal),
        (["saúde", "saude", "plano", "médico", "medico", "farmácia", "farmacia", "health", "salud", "santé", "salute"], "cross.case.fill", .pink),
        (["salário", "salario", "salary", "salaire", "stipendio", "pagamento", "pró-labore"], "banknote.fill", .green),
        (["investimento", "invest", "poupança", "tesouro", "dividendo"], "chart.line.uptrend.xyaxis", .green)
    ]

    static func symbol(for name: String, isIncome: Bool) -> String {
        match(name)?.symbol ?? (isIncome ? "arrow.down.left" : "doc.text.fill")
    }

    static func color(for name: String, isIncome: Bool) -> Color {
        match(name)?.color ?? (isIncome ? .green : .gray)
    }

    private static func match(_ name: String) -> (symbol: String, color: Color)? {
        let text = " " + name.lowercased() + " "
        for rule in rules where rule.keywords.contains(where: { text.contains($0) }) {
            return (rule.symbol, rule.color)
        }
        return nil
    }
}

/// Rounded colored tile with a symbol (list rows and widgets).
struct EntryIconTile: View {
    let name: String
    let isIncome: Bool
    var size: CGFloat = 34

    var body: some View {
        let tint = EntryStyle.color(for: name, isIncome: isIncome)
        Image(systemName: EntryStyle.symbol(for: name, isIncome: isIncome))
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.16), in: .rect(cornerRadius: size * 0.3, style: .continuous))
    }
}

/// Large amount with a small currency symbol in front, e.g. "R$ 1.234,56".
struct BigAmountText: View {
    let value: Double
    let currencyCode: String
    var size: CGFloat = 44
    var showsSign = false

    private var parts: (symbol: String, number: String) {
        let style = FloatingPointFormatStyle<Double>.Currency(code: currencyCode)
        let full = abs(value).formatted(style)
        let symbol = full.filter { !$0.isNumber && $0 != "," && $0 != "." && !$0.isWhitespace }
        let number = abs(value).formatted(.number.precision(.fractionLength(2)))
        return (symbol, number)
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Text((showsSign ? (value < 0 ? "−" : "+") : (value < 0 ? "−" : "")) + parts.symbol)
                .font(.system(size: size * 0.48, weight: .regular, design: .rounded))
                .foregroundStyle(.secondary)
            Text(parts.number)
                .font(.system(size: size, weight: .medium, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText(value: value))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(value.formatted(.currency(code: currencyCode)))
    }
}
