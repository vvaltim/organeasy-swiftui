import SwiftUI
import SwiftData

struct MonthlyEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String = ""
    @State private var textAmount: String = ""
    @State private var amount: Double = 0.0
    @State private var dueDate: Date = .now
    @State private var type: EntryType = .expense
    @State private var paymentDate: Date? = nil
    
    @State private var showPaymentDate: Bool = false
    @State private var isRecurrent: Bool = false
    
    @FocusState private var isAmountFocused: Bool
    @State private var amountInCents: Int = 0
    
    @State private var isShowingDeleteConfirmation: Bool = false
    var entryToEdit: MonthlyEntry? = nil

    // MARK: Initializer
    
    init(entryToEdit: MonthlyEntry? = nil) {
        self.entryToEdit = entryToEdit
        if let entry = entryToEdit {
            _title = State(initialValue: entry.name)
            _amount = State(initialValue: entry.amount)
            _dueDate = State(initialValue: entry.dueDate)
            _type = State(initialValue: entry.type)
            _paymentDate = State(initialValue: entry.paymentDate)
            _showPaymentDate = State(initialValue: entry.paymentDate != nil)
            _textAmount = State(initialValue: "")
        }
        
        let initialCents = Int((self._amount.wrappedValue * 100.0).rounded())
        self._amountInCents = State(initialValue: max(0, initialCents))
    }
    
    // MARK: Main View
    
    var body: some View {
        NavigationStack {
            Form {
                formSection
                
                paymentDateSection
                
                recurrenceSection
                
                if let entry = entryToEdit {
                    deleteSection
                        .confirmationDialog(OrganEasyStrings.Form.deleteConfirmTitle, isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                            Button(OrganEasyStrings.Form.delete, role: .destructive) {
                                deleteEntry(with: entry)
                            }
                            Button(OrganEasyStrings.Form.cancel, role: .cancel) {}
                        }
                }
            }
            .navigationTitle(OrganEasyStrings.Form.newEntry)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: Icon.xmark.rawValue)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        saveEntry()
                    } label: {
                        Image(systemName: Icon.checkmark.rawValue)
                   }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // MARK: Form Section
    
    var formSection: some View {
        Section(header: Text(entryToEdit == nil ? OrganEasyStrings.Form.newEntry : OrganEasyStrings.Form.editEntry)) {
            TextField(OrganEasyStrings.Form.valuePlaceholder, text: Binding(
                get: { textAmount },
                set: { newValue in
                    let digits = newValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

                    let cents = Int(digits) ?? 0
                    amountInCents = cents
                    
                    amount = Double(cents) / 100.0
                    
                    if isAmountFocused {
                        textAmount = digits
                    } else {
                        textAmount = amount.formatted(.currency(code: "BRL"))
                    }
                }
            ))
            .keyboardType(.numberPad)
            .focused($isAmountFocused)
            .onChange(of: isAmountFocused) { old, isFocused in
                if isFocused {
                    let digits = String(amountInCents)
                    textAmount = digits == "0" ? "" : digits
                } else {
                    amount = Double(amountInCents) / 100.0
                    textAmount = amount.formatted(.currency(code: "BRL"))
                }
            }
            .onAppear {
                amountInCents = Int((amount * 100.0).rounded())
                textAmount = amount.formatted(.currency(code: "BRL"))
            }
            
            TextField(OrganEasyStrings.Form.descriptionPlaceholder, text: $title)
                .autocapitalization(.words)
            
            DatePicker(OrganEasyStrings.Form.dueDate, selection: $dueDate, displayedComponents: .date)
            
            Picker(OrganEasyStrings.Form.type, selection: $type) {
                Text(OrganEasyStrings.Form.typeIncome).tag(EntryType.income)
                Text(OrganEasyStrings.Form.typeExpense).tag(EntryType.expense)
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: Payment Date Section
    
    var paymentDateSection: some View {
        Section {
            Toggle(OrganEasyStrings.Form.addPaymentDate, isOn: $showPaymentDate.animation())
            if showPaymentDate {
                DatePicker(OrganEasyStrings.Form.payment, selection: Binding(
                    get: { paymentDate ?? .now },
                    set: { paymentDate = $0 }
                ), displayedComponents: .date)
            }
        }
    }
    
    // MARK: Recurrence Section
    
    var recurrenceSection: some View {
        Section {
            Toggle(OrganEasyStrings.Form.recurrent, isOn: $isRecurrent.animation())
        }
    }
    
    // MARK: Delete Section
    
    var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                isShowingDeleteConfirmation = true
            } label: {
                HStack {
                    Spacer()
                    Image(systemName: Icon.trash.rawValue)
                    Text(OrganEasyStrings.Form.delete)
                    Spacer()
                }
            }
        }
    }
    
    // MARK:  Functions
    
    private func saveEntry() {
        let referenceMonth = dueDate.getReferenceMonth()
        
        if let entry = entryToEdit {
            entry.name = title
            entry.amount = amount
            entry.dueDate = dueDate
            entry.type = type
            entry.referenceMonth = referenceMonth
            entry.paymentDate = showPaymentDate ? paymentDate : nil
            try? modelContext.save()
        } else {
            let entry = MonthlyEntry(
                name: title,
                amount: amount,
                referenceMonth: referenceMonth,
                dueDate: dueDate,
                type: type
            )
            if showPaymentDate {
                entry.paymentDate = paymentDate
            }
            modelContext.insert(entry)
        }
        
        saveTemplate()
        
        dismiss()
    }
    
    private func deleteEntry(with entry: MonthlyEntry) {
        modelContext.delete(entry)
        try? modelContext.save()
        dismiss()
    }
    
    private func saveTemplate() {
        if !isRecurrent {
            return
        }
        
        let dueDayString: String = dueDate.formatted(.dateTime.day())
        let dueDay = Int(dueDayString) ?? 1

        if templateExists(name: title, type: type, dueDay: dueDay) {
            return
        }
        
        let template = RecurringEntryTemplate(
            dueDay: dueDay,
            enabled: true,
            name: title,
            type: type
        )
        modelContext.insert(template)
    }
    
    private func templateExists(name: String, type: EntryType, dueDay: Int) -> Bool {
        let descriptor = FetchDescriptor<RecurringEntryTemplate>(
            predicate: #Predicate { template in
                template.name == name && template.type == type && template.dueDay == dueDay
            },
            sortBy: []
        )
        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            return false
        }
    }
}

// MARK: - Preview

#Preview {
    MonthlyEntryFormView()
        .modelContainer(for: MonthlyEntry.self)
}
