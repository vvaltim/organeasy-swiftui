import Foundation

enum OrganEasyStrings {
    enum Home {
        static let title = String(localized: "home.title")
        static let recurrenceMenuTitle = String(localized: "home.recurrence.menu.title")
        static let applyRecurrences = String(localized: "home.recurrence.apply")
        static let moreOptionsA11y = String(localized: "home.more_options")
        static let addEntryA11y = String(localized: "home.add_entry")
        static let previousMonthA11y = String(localized: "home.previous_month")
        static let nextMonthA11y = String(localized: "home.next_month")
        static let referenceLabel = String(localized: "home.reference")
        static let noneItem = String(localized: "home.none_item")
        static let emptyTitle = String(localized: "home.empty.title")
        static let emptyDescription = String(localized: "home.empty.description")
    }

    enum Form {
        static let newEntry = String(localized: "form.new_entry")
        static let editEntry = String(localized: "form.edit_entry")
        static let valuePlaceholder = String(localized: "form.value")
        static let descriptionPlaceholder = String(localized: "form.description")
        static let dueDate = String(localized: "form.due_date")
        static let type = String(localized: "form.type")
        static let typeIncome = String(localized: "form.type.income")
        static let typeExpense = String(localized: "form.type.expense")
        static let addPaymentDate = String(localized: "form.add_payment_date")
        static let payment = String(localized: "form.payment")
        static let recurrent = String(localized: "form.recurrent")
        static let deleteEntry = String(localized: "form.delete_entry")
        static let deleteConfirmTitle = String(localized: "form.delete_confirm.title")
        static let delete = String(localized: "common.delete")
        static let cancel = String(localized: "common.cancel")
    }

    enum Row {
        static let markPaid = String(localized: "row.mark_paid")
        static let unmark = String(localized: "row.unmark")
    }

    enum Template {
        static let deactivate = String(localized: "template.deactivate")
        static let activate = String(localized: "template.activate")
    }

    enum Summary {
        static let incomes = String(localized: "summary.incomes")
        static let expenses = String(localized: "summary.expenses")
        static let balance = String(localized: "summary.balance")
        static let a11yLabel = String(localized: "summary.a11y_label")
    }

    enum Common {
        static let ok = String(localized: "common.ok")
    }
}
