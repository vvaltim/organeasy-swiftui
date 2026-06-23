//
//  MainTabBar.swift
//  MyApp
//
//  Created by Walter Vânio dos Reis Júnior on 09/06/26.
//

import SwiftData
import SwiftUI

struct HomePage: View {
    @Environment(\.modelContext) private var modelContext
    @Query<MonthlyEntry>(sort: [SortDescriptor(\MonthlyEntry.dueDate, order: .forward)]) private var allEntries: [MonthlyEntry]

    @State private var isPresentingNewEntrySheet = false
    @State private var isPresentingEditSheet = false
    @State private var selectedEntry: MonthlyEntry? = nil

    @State private var referenceOffset: Int = 0

    private var currentReference: String {
        let now = Date()
        var comps = Calendar.current.dateComponents([.year, .month], from: now)
        if let month = comps.month { comps.month = month + referenceOffset }
        let date = Calendar.current.date(from: comps) ?? now
        return date.formatted(.dateTime.year(.twoDigits).month(.twoDigits))
    }

    private var entriesForCurrentReference: [MonthlyEntry] {
        allEntries.filter { $0.referenceMonth == currentReference }
            .sorted { $0.dueDate < $1.dueDate }
    }
    
    private var income: Double {
        entriesForCurrentReference.filter { $0.type == .income }.map(\.amount).reduce(0, +)
    }
    
    private var expense: Double {
        entriesForCurrentReference.filter { $0.type == .expense }.map(\.amount).reduce(0, +)
    }
    
    private var monthFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "MMMM yyyy"
        
        let now = Date()
        var comps = Calendar.current.dateComponents([.year, .month], from: now)
        
        if let month = comps.month {
            comps.month = month + referenceOffset
        }
        
        let date = Calendar.current.date(from: comps) ?? now
        
        return formatter.string(from: date)
            .capitalized
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.snappy) { referenceOffset += 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)

                    VStack(spacing: 2) {
                        Text("Referência")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(monthFormatted)
                            .font(.headline)
                            .monospaced()
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        withAnimation(.snappy) { referenceOffset -= 1 }
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal)

                if entriesForCurrentReference.isEmpty {
                    ContentUnavailableView(
                        "Sem lancamentos",
                        systemImage: "list.bullet.rectangle.portrait",
                        description: Text("Adicione um novo item, ou tente outro mês.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            HomeSummaryHeaderView(
                                income: income,
                                expense: expense
                            )
                        }
                        
                        Section("A pagar") {
                            let unpaid = entriesForCurrentReference.filter { $0.paymentDate == nil }
                            if unpaid.isEmpty {
                                Text("Nenhum item a pagar")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(unpaid, id: \.id) { entry in
                                    EntryRow(entry: entry) {
                                        selectedEntry = entry
                                        isPresentingEditSheet = true
                                    } onTogglePaid: {
                                        togglePayment(for: entry)
                                    }
                                }
                            }
                        }

                        Section("Pago") {
                            let paid = entriesForCurrentReference.filter { $0.paymentDate != nil }
                            if paid.isEmpty {
                                Text("Nenhum item pago")
                                    .foregroundStyle(.secondary)
                            } else {
                                ForEach(paid, id: \.id) { entry in
                                    EntryRow(entry: entry) {
                                        selectedEntry = entry
                                        isPresentingEditSheet = true
                                    } onTogglePaid: {
                                        togglePayment(for: entry)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingNewEntrySheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add entry")
                }
            }
        }
        .sheet(isPresented: $isPresentingNewEntrySheet) {
            NewMonthlyEntrySheet()
        }
        .sheet(isPresented: $isPresentingEditSheet) {
            if let selectedEntry {
                NewMonthlyEntrySheet(entryToEdit: selectedEntry)
            }
        }
    }

    private func togglePayment(for entry: MonthlyEntry) {
        if entry.paymentDate == nil {
            entry.paymentDate = Date()
        } else {
            entry.paymentDate = nil
        }
        try? modelContext.save()
    }
}

#Preview {
    HomePage()
}
