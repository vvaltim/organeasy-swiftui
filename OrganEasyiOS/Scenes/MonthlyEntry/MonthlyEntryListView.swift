import SwiftData
import SwiftUI

struct MonthlyEntryListView: View {

    // MARK:  Scene Phase
    
    @Environment(\.scenePhase) private var scenePhase
    
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
    
    // MARK: - App Storage
    
    @AppStorage("MonthlyEntryReferenceDate") private var referenceDate: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Date())) ?? Date()
    
    // MARK: - Computed Variables
    
    var entriesForCurrentReference: [MonthlyEntry] {
        let base = referenceDate
        let current = Calendar.current.date(byAdding: DateComponents(month: referenceOffset), to: base) ?? base
        let currentReference = current.getCurrentReference(with: 0)
        return allEntries.filter { $0.referenceMonth == currentReference }
    }
    
    private var income: Double {
        entriesForCurrentReference.filter { $0.type == .income }.map(\.amount).reduce(0, +)
    }
    
    private var expense: Double {
        entriesForCurrentReference.filter { $0.type == .expense }.map(\.amount).reduce(0, +)
    }
    
    var monthFormatted: String {
        let base = referenceDate
        let date = Calendar.current.date(byAdding: DateComponents(month: referenceOffset), to: base) ?? base
        return date.getDateFormatted(with: .MMMMyyyy)
    }
    
    // MARK: - Main View
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Size.x12.rawValue) {
                monthSelector
                    .padding(.horizontal)
                
                if entriesForCurrentReference.isEmpty {
                    emptyView
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink {
                            TemplateListView()
                        } label: {
                            Label("Recorrerência", systemImage: Icon.listNumber.rawValue)
                        }

                        Button {
                            print("Criar com os templates")
                        } label: {
                            Label("Aplicar recorrências", systemImage: Icon.squareAndArrowDownOnSquare.rawValue)
                        }
                    } label: {
                        Image(systemName: Icon.ellipsis.rawValue)
                    }
                    .accessibilityLabel("Mais opções")
                }
            }
        }
        .sheet(item: $selectedEntry) { entry in
            MonthlyEntryFormView(entryToEdit: entry)
        }
        .sheet(isPresented: $isPresentingMonthlyEntrySheet) {
            MonthlyEntryFormView(entryToEdit: nil)
        }
        .onDisappear { commitOffsetToReferenceDate() }
        .onChange(of: scenePhase) { _, newValue in
            if newValue != .active { commitOffsetToReferenceDate() }
        }
    }
    
    // MARK: - Selector View
    
    var monthSelector: some View {
        HStack(spacing: Size.x12.rawValue) {
            Button {
                withAnimation(.snappy) { addMonth() }
            } label: {
                Image(systemName: Icon.chevronLeft.rawValue)
            }
            .buttonStyle(.glass)
            
            VStack(spacing: Size.x2.rawValue) {
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
            .buttonStyle(.glass)
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
    
    // MARK:  Empty View
    
    private var emptyView: some View {
        ContentUnavailableView {
            Label {
                Text("Sem lancamentos")
                    .font(.title3)
            } icon: {
                Image(systemName: Icon.listBulletRectanglePortrait.rawValue)
            }
        } description: {
            Text("Adicione um lançamento manualmente ou aplique suas recorrências.")
                .font(.caption)
        }actions: {
            Button {
                insertRecurrences()
            } label: {
                Label("Aplicar recorrências", systemImage: Icon.squareAndArrowDownOnSquare.rawValue)
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
    
    private func commitOffsetToReferenceDate() {
        guard referenceOffset != 0 else { return }
        let newDate = Calendar.current.date(byAdding: DateComponents(month: referenceOffset), to: referenceDate) ?? referenceDate
        referenceDate = newDate
        referenceOffset = 0
    }
    
    private func insertRecurrences() {
        
    }
}

// MARK: - Preview

#Preview {
    MonthlyEntryListView()
        .modelContainer(OrganEasyModelContainer.preview)
}
