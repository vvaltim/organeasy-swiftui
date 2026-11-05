import CoreData
import SwiftData
import XCTest
@testable import OrganEasy

@MainActor
final class LegacyDataImporterTests: XCTestCase {
    private var folder: URL!
    private var storeURL: URL!
    private var legacy: NSPersistentContainer!
    private var container: ModelContainer!
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        storeURL = folder.appending(path: "OrganEasy.sqlite")

        legacy = NSPersistentContainer(name: "OrganEasy", managedObjectModel: Self.legacyModel)
        legacy.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        var loadError: Error?
        legacy.loadPersistentStores { _, error in loadError = error }
        if let loadError { throw loadError }

        let schema = Schema([MonthlyEntry.self, RecurringEntryTemplate.self])
        container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        )
        defaults = UserDefaults(suiteName: UUID().uuidString)
    }

    override func tearDownWithError() throws {
        try legacy.persistentStoreCoordinator.persistentStores.forEach(legacy.persistentStoreCoordinator.remove)
        try FileManager.default.removeItem(at: folder)
    }

    func testImportsTransactionsAndRecurringBills() throws {
        let id = UUID()
        let due = Date(timeIntervalSinceReferenceDate: 800_000_000)
        let paid = due.addingTimeInterval(3600)
        insertTransaction(id: id, name: "Aluguel", amount: 1800, due: due, paid: paid, income: false)
        insertTransaction(id: nil, name: "Salário", amount: 5000, due: due, paid: nil, income: true)
        insertBill(name: "Internet", due: due)
        try legacy.viewContext.save()

        let result = try LegacyDataImporter.importStore(at: storeURL, into: container.mainContext)

        XCTAssertEqual(result, .init(entries: 2, templates: 1))
        let entries = try container.mainContext.fetch(FetchDescriptor<MonthlyEntry>())
        let rent = try XCTUnwrap(entries.first { $0.name == "Aluguel" })
        XCTAssertEqual(rent.id, id)
        XCTAssertEqual(rent.amount, 1800)
        XCTAssertEqual(rent.dueDate, due)
        XCTAssertEqual(rent.paymentDate, paid)
        XCTAssertEqual(rent.type, .expense)
        XCTAssertEqual(rent.referenceMonth, due.getReferenceMonth())
        XCTAssertEqual(entries.first { $0.name == "Salário" }?.type, .income)

        let template = try XCTUnwrap(container.mainContext.fetch(FetchDescriptor<RecurringEntryTemplate>()).first)
        XCTAssertEqual(template.name, "Internet")
        XCTAssertEqual(template.dueDay, Calendar.current.component(.day, from: due))
        XCTAssertTrue(template.enabled)
    }

    func testRepeatingImportDoesNotDuplicate() throws {
        insertTransaction(id: nil, name: "Luz", amount: 90, due: .now, paid: nil, income: false)
        insertBill(name: "Internet", due: .now)
        try legacy.viewContext.save()

        try LegacyDataImporter.importStore(at: storeURL, into: container.mainContext)
        let second = try LegacyDataImporter.importStore(at: storeURL, into: container.mainContext)

        XCTAssertEqual(second, .init())
        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<MonthlyEntry>()), 1)
    }

    func testRunsOnceAndKeepsOriginalStore() throws {
        insertTransaction(id: nil, name: "Luz", amount: 90, due: .now, paid: nil, income: false)
        try legacy.viewContext.save()

        LegacyDataImporter.runIfNeeded(into: container.mainContext, storeURL: storeURL, defaults: defaults)
        XCTAssertTrue(defaults.bool(forKey: LegacyDataImporter.completedKey))

        insertTransaction(id: nil, name: "Água", amount: 50, due: .now, paid: nil, income: false)
        try legacy.viewContext.save()
        LegacyDataImporter.runIfNeeded(into: container.mainContext, storeURL: storeURL, defaults: defaults)

        XCTAssertEqual(try container.mainContext.fetchCount(FetchDescriptor<MonthlyEntry>()), 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path(percentEncoded: false)))
    }

    func testMissingStoreIsIgnoredAndCanRunLater() {
        let missing = folder.appending(path: "nada.sqlite")
        LegacyDataImporter.runIfNeeded(into: container.mainContext, storeURL: missing, defaults: defaults)
        XCTAssertFalse(defaults.bool(forKey: LegacyDataImporter.completedKey))
    }

    func testCorruptStoreIsRetriedLater() throws {
        let corrupt = folder.appending(path: "ruim.sqlite")
        try Data(repeating: 7, count: 4096).write(to: corrupt)
        LegacyDataImporter.runIfNeeded(into: container.mainContext, storeURL: corrupt, defaults: defaults)
        XCTAssertFalse(defaults.bool(forKey: LegacyDataImporter.completedKey))
    }

    // MARK: - Banco antigo

    private func insertTransaction(id: UUID?, name: String, amount: Double, due: Date, paid: Date?, income: Bool) {
        let object = NSEntityDescription.insertNewObject(forEntityName: "Transaction", into: legacy.viewContext)
        object.setValue(id, forKey: "id")
        object.setValue(name, forKey: "descriptionText")
        object.setValue(amount, forKey: "amount")
        object.setValue(due, forKey: "dueDate")
        object.setValue(paid, forKey: "paymentDate")
        object.setValue(income, forKey: "isIncome")
    }

    private func insertBill(name: String, due: Date) {
        let object = NSEntityDescription.insertNewObject(forEntityName: "RecurringBill", into: legacy.viewContext)
        object.setValue(name, forKey: "name")
        object.setValue(due, forKey: "dueDate")
    }

    /// Mesmas entidades do modelo da versão 1.x que o importador lê.
    private static let legacyModel: NSManagedObjectModel = {
        func attribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
            let attribute = NSAttributeDescription()
            attribute.name = name
            attribute.attributeType = type
            attribute.isOptional = true
            return attribute
        }

        let transaction = NSEntityDescription()
        transaction.name = "Transaction"
        transaction.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("descriptionText", .stringAttributeType),
            attribute("amount", .doubleAttributeType),
            attribute("dueDate", .dateAttributeType),
            attribute("paymentDate", .dateAttributeType),
            attribute("isIncome", .booleanAttributeType)
        ]

        let bill = NSEntityDescription()
        bill.name = "RecurringBill"
        bill.properties = [
            attribute("id", .UUIDAttributeType),
            attribute("name", .stringAttributeType),
            attribute("amount", .doubleAttributeType),
            attribute("dueDate", .dateAttributeType)
        ]

        let model = NSManagedObjectModel()
        model.entities = [transaction, bill]
        return model
    }()
}
