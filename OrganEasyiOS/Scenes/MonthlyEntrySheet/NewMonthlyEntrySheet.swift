import SwiftUI
import SwiftData

struct NewMonthlyEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title: String = ""
    @State private var textAmount: String = ""
    @State private var amount: Double = 0.0
    @State private var dueDate: Date = .now
    @State private var type: EntryType = .expense
    @State private var paymentDate: Date? = nil
    
    @State private var showPaymentDate: Bool = false
    @FocusState private var isAmountFocused: Bool
    @State private var amountInCents: Int = 0
    
    @State private var isShowingDeleteConfirmation: Bool = false
    
    var entryToEdit: MonthlyEntry? = nil
    
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }()
    
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
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(entryToEdit == nil ? "Nova Entrada" : "Editar Entrada")) {
                    TextField("Valor", text: Binding(
                        get: { textAmount },
                        set: { newValue in
                            let digits = newValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)

                            let cents = Int(digits) ?? 0
                            amountInCents = cents
                            
                            amount = Double(cents) / 100.0
                            
                            if isAmountFocused {
                                textAmount = digits
                            } else {
                                textAmount = currencyFormatter.string(from: NSNumber(value: amount)) ?? ""
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
                            textAmount = currencyFormatter.string(from: NSNumber(value: amount)) ?? ""
                        }
                    }
                    .onAppear {
                        amountInCents = Int((amount * 100.0).rounded())
                        textAmount = currencyFormatter.string(from: NSNumber(value: amount)) ?? ""
                    }
                    
                    TextField("Descrição", text: $title)
                        .autocapitalization(.words)
                    
                    DatePicker("Vencimento", selection: $dueDate, displayedComponents: .date)
                    
                    Picker("Tipo", selection: $type) {
                        Text("Receita").tag(EntryType.income)
                        Text("Despesa").tag(EntryType.expense)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Toggle("Adicionar data de pagamento", isOn: $showPaymentDate.animation())
                    if showPaymentDate {
                        DatePicker("Pagamento", selection: Binding(
                            get: { paymentDate ?? .now },
                            set: { paymentDate = $0 }
                        ), displayedComponents: .date)
                    }
                }
                
                if let entry = entryToEdit {
                    Section {
                        Button(role: .destructive) {
                            isShowingDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text("Excluir entrada")
                                Spacer()
                            }
                        }
                    }
                    .confirmationDialog("Tem certeza que deseja excluir esta entrada?", isPresented: $isShowingDeleteConfirmation, titleVisibility: .visible) {
                        Button("Excluir", role: .destructive) {
                            modelContext.delete(entry)
                            try? modelContext.save()
                            dismiss()
                        }
                        Button("Cancelar", role: .cancel) {}
                    }
                }
            }
            .navigationTitle("Nova Entrada")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        let df = DateFormatter()
                        df.dateFormat = "yy-MM"
                        let referenceMonth = dueDate.formatted(.dateTime.year(.twoDigits).month(.twoDigits))
                        
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
                        dismiss()
                    } label: {
                       Image(systemName: "checkmark")
                   }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NewMonthlyEntrySheet()
        .modelContainer(for: MonthlyEntry.self)
}
