import SwiftData
import SwiftUI

struct MonthlyEntryListView: View {
    
    // MARK: - Model Container
    
    @Environment(\.modelContext) private var modelContext
    @Query<MonthlyEntry>(
        sort: [
            SortDescriptor(\MonthlyEntry.dueDate, order: .forward)
        ]
    ) private var allEntries: [MonthlyEntry]
    
    // MARK: - States
    
    @State private var isPresentingMonthlyEntrySheet = false
    @State private var selectedEntry: MonthlyEntry? = nil
    
    @State private var referenceOffset: Int = 0
    
    // MARK: - Computed Variables
    
    private var entriesForCurrentReference: [MonthlyEntry] {
        let currentReference = Date().getCurrentReference(with: referenceOffset)
        return allEntries.filter { $0.referenceMonth == currentReference }
    }
    
    private var income: Double {
        entriesForCurrentReference.filter { $0.type == .income }.map(\.amount).reduce(0, +)
    }
    
    private var expense: Double {
        entriesForCurrentReference.filter { $0.type == .expense }.map(\.amount).reduce(0, +)
    }
    
    private var monthFormatted: String {
        let now = Date()
        var comps = Calendar.current.dateComponents([.year, .month], from: now)
        
        if let month = comps.month {
            comps.month = month + referenceOffset
        }
        
        let date = Calendar.current.date(from: comps) ?? now
        
        return date.getDateFormatted(with: .MMMMyyyy)
    }
    
    // MARK: - Main View
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                monthSelector
                    .padding(.horizontal)
                
                if entriesForCurrentReference.isEmpty {
                    ContentUnavailableView(
                        "Sem lancamentos",
                        systemImage: Icon.listBulletRectanglePortrait.rawValue,
                        description: Text("Adicione um novo item, ou tente outro mês.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        headerSection
                        
                        notPaidSection
                        
                        paidSection
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        openMonthlyEntry()
                    } label: {
                        Image(systemName: Icon.plus.rawValue)
                    }
                    .accessibilityLabel("Add entry")
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            MonthlyEntryFormView(entryToEdit: entry)
        }
        .sheet(isPresented: $isPresentingMonthlyEntrySheet) {
            MonthlyEntryFormView(entryToEdit: nil)
        }
    }
    
    // MARK: - Selector View
    
    var monthSelector: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.snappy) { addMonth() }
            } label: {
                Image(systemName: Icon.chevronLeft.rawValue)
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
                withAnimation(.snappy) { subtractMonth() }
            } label: {
                Image(systemName: Icon.chevronRight.rawValue)
            }
            .buttonStyle(.bordered)
        }
    }
    
    // MARK: - Header View
    
    var headerSection: some View {
        Section {
            MonthlyEntrySummaryHeaderView(
                income: income,
                expense: expense
            )
        }
    }
    
    // MARK: - Not Paid Section
    
    var notPaidSection: some View {
        Section("A pagar") {
            let unpaid = entriesForCurrentReference.filter { $0.paymentDate == nil }
            if unpaid.isEmpty {
                Text("Nenhum item a pagar")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(unpaid) { entry in
                    MonthlyEntryRowView(entry: entry) {
                        openMonthlyEntry(with: entry)
                    } onTogglePaid: {
                        togglePayment(for: entry)
                    }
                }
            }
        }
    }
    
    // MARK: - Paid Section
    
    var paidSection: some View {
        Section("Pago") {
            let paid = entriesForCurrentReference.filter { $0.paymentDate != nil }
            if paid.isEmpty {
                Text("Nenhum item pago")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(paid) { entry in
                    MonthlyEntryRowView(entry: entry) {
                        openMonthlyEntry(with: entry)
                    } onTogglePaid: {
                        togglePayment(for: entry)
                    }
                }
            }
        }
    }
    
    // MARK: - Functions
    
    private func togglePayment(for entry: MonthlyEntry) {
        if entry.paymentDate == nil {
            entry.paymentDate = Date()
        } else {
            entry.paymentDate = nil
        }
        try? modelContext.save()
    }
    
    private func addMonth() {
        referenceOffset += 1
    }
    
    private func subtractMonth() {
        referenceOffset -= 1
    }
    
    private func openMonthlyEntry(with entry: MonthlyEntry? = nil) {
        if let entry {
            selectedEntry = entry
        } else {
            isPresentingMonthlyEntrySheet = true
        }
    }
}

// MARK: - Preview

#Preview {
    MonthlyEntryListView()
        .modelContainer(OrganEasyModelContainer.preview)
}
