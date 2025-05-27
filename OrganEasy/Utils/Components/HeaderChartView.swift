//
//  HeaderChartView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import Charts
import SwiftUI

struct HeaderChartView: View {
    let chartData: [TestValues] = [
        TestValues(month: "Jan/25", value: 100),
        TestValues(month: "Feb/25", value: 200),
        TestValues(month: "Mar/25", value: 300),
    ]
    
    var body: some View {
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
}

struct TestValues: Identifiable {
    var id = UUID()
    let month: String
    let value: Double
}

#Preview {
//    let data = [
//        TestValues(month: "Jan", value: 100),
//        TestValues(month: "Feb", value: 200),
//        TestValues(month: "Mar", value: 300),
//    ]
//    
    HeaderChartView()//(chartData: data)
}
