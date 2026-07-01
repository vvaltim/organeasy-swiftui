import Foundation
import SwiftData

@Model
final class RecurringEntryTemplate {
    
    var id: UUID = UUID()
    
    var dueDay: Int = 0
    
    var enabled: Bool = true
    
    var name: String = ""
    
    var type: EntryType = EntryType.expense
    
    init(
        dueDay: Int,
        enabled: Bool,
        name: String,
        type: EntryType
    ) {
        self.id = UUID()
        self.dueDay = dueDay
        self.enabled = enabled
        self.name = name
        self.type = type
    }
    
}

