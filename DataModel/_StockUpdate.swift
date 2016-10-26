// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to StockUpdate.swift instead.

import Foundation
import CoreData

public enum StockUpdateAttributes: String {
    case ask = "ask"
    case bid = "bid"
    case change = "change"
    case date = "date"
}

public enum StockUpdateRelationships: String {
    case company = "company"
}

open class _StockUpdate: NSManagedObject {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "StockUpdate"
    }

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _StockUpdate.entity(managedObjectContext: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var ask: NSDecimalNumber!

    @NSManaged open
    var bid: NSDecimalNumber!

    @NSManaged open
    var change: NSDecimalNumber!

    @NSManaged open
    var date: Date!

    // MARK: - Relationships

    @NSManaged open
    var company: Company

}

