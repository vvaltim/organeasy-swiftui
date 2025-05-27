//
//  EvolutionHomeView.swift
//  OrganEasy
//
//  Created by Walter Vânio dos Reis Júnior on 26/05/25.
//

import SwiftUI

struct EvolutionHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(
                    header: HeaderChartView()
                ) {
                    HStack {
                        Text(Date().formatToMonthYear())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                                                
                    }
                }
            }
            .navigationTitle(Text("Evolução"))
            .toolbar {
                ToolbarItem {
                    Button(action: { }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    EvolutionHomeView()
}
