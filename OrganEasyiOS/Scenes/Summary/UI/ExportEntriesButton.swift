import SwiftData
import SwiftUI

struct ExportEntriesButton: View {
    @Query private var entries: [MonthlyEntry]

    private var file: EntriesCSVFile {
        EntriesCSVFile(rows: entries.map {
            .init(date: $0.dueDate, name: $0.name, amount: $0.amount, type: $0.type, paymentDate: $0.paymentDate)
        })
    }

    var body: some View {
        ShareLink(item: file, preview: SharePreview("OrganEasy.csv")) {
            Label("Exportar dados", systemImage: Icon.squareAndArrowUp.rawValue)
        }
        .disabled(entries.isEmpty)
    }
}
