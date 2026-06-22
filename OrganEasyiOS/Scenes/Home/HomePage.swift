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

    @State private var referenceOffset: Int = 0 // -1 = previous, 0 = current, 1 = next

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

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Reference selector with a subtle Liquid Glass background
                HStack(spacing: 12) {
                    Button {
                        withAnimation(.snappy) { referenceOffset -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)

                    VStack(spacing: 2) {
                        Text("Referencia")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(currentReference)
                            .font(.headline)
                            .monospaced()
                    }
                    .frame(maxWidth: .infinity)

                    Button {
                        withAnimation(.snappy) { referenceOffset += 1 }
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
                        ForEach(entriesForCurrentReference, id: \.id) { entry in
                            EntryRow(entry: entry) {
                                selectedEntry = entry
                                isPresentingEditSheet = true
                            } onTogglePaid: {
                                togglePayment(for: entry)
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
