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
                    x: .value("header_chart_view_month", item.month),
                    y: .value("header_chart_view_balance", item.value)
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
        .glassEffect(in: .rect(cornerRadius: 24.00))
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
