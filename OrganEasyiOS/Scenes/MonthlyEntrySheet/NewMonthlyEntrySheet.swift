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
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(entryToEdit == nil ? "Nova Entrada" : "Editar Entrada")) {
                    TextField("Nome", text: $title)
                        .textContentType(.name)
                        .autocapitalization(.words)
                    
                    TextField("Valor", text: $textAmount)
                        .keyboardType(.decimalPad)
                        .onChange(of: textAmount) { oldValue, newValue in
                            let cleanString = newValue
                                .replacingOccurrences(of: "[^0-9,]", with: "", options: .regularExpression)
                                .replacingOccurrences(of: ",", with: ".")
                            
                            if let number = Double(cleanString) {
                                amount = number
                            }
                        }
                        .onAppear {
                            textAmount = currencyFormatter.string(for: amount as NSNumber) ?? ""
                        }
                    
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
