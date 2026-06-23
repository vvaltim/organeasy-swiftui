//
//  HomeSummaryHeaderView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 23/06/26.
//

import SwiftUI

struct HomeSummaryHeaderView: View {
    let income: Double
    let expense: Double

    private var balance: Double { income - expense }

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            SummaryItemView(title: "Entradas", value: income, color: .green)
            Divider()
                .frame(height: 44)
            SummaryItemView(title: "Saídas", value: expense, color: .red)
            Divider()
                .frame(height: 44)
            SummaryItemView(title: "Saldo", value: balance, color: balanceColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resumo: Entradas, Saídas e Restante")
    }

    private var balanceColor: Color {
        if balance > 0 { return .green }
        if balance < 0 { return .red }
        return .secondary
    }
}

private struct SummaryItemView: View {
    let title: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatted(value))
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatted(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(for: number) ?? "-"
    }
}

#Preview("HomeSummaryHeaderView") {
    VStack(spacing: 16) {
        HomeSummaryHeaderView(income: 2500, expense: 1750)
        HomeSummaryHeaderView(income: 1200.75, expense: 1800.20)
        HomeSummaryHeaderView(income: 1000, expense: 1000)
    }
    .padding()
}
