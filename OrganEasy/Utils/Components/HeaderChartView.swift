//
//  HeaderChartView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import Charts
import SwiftUI

struct HeaderChartView: View {
    let chartData: [TestValues]
    
    var body: some View {
        HStack {
            Chart(chartData) { item in
                LineMark(
                    x: .value("Mês", item.month),
                    y: .value("Saldo", item.value)
                )
            }
            .chartYAxis {
                AxisMarks() { value in
                    if let doubleValue = value.as(Double.self) {
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            Text(doubleValue.toBRL())
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .stroke(
                    Color.gray.opacity(0.3),
                    lineWidth: 1
                )
        )
        .padding(.vertical)
    }
}

struct TestValues: Identifiable {
    var id = UUID()
    let month: String
    let value: Double
}

#Preview {
    let data = [
        TestValues(month: "Jan", value: 100),
        TestValues(month: "Feb", value: 200),
        TestValues(month: "Mar", value: 300),
    ]
    
    HeaderChartView(chartData: data)
}
