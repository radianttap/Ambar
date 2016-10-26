// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Company.swift instead.

import Foundation
import CoreData

public enum CompanyAttributes: String {
    case name = "name"
    case symbol = "symbol"
}

public enum CompanyRelationships: String {
    case stockupdates = "stockupdates"
}

open class _Company: NSManagedObject {

    // MARK: - Class methods

    open class func entityName () -> String {
        return "Company"
    }

    open class func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription? {
        return NSEntityDescription.entity(forEntityName: self.entityName(), in: managedObjectContext)
    }

    // MARK: - Life cycle methods

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    public convenience init?(managedObjectContext: NSManagedObjectContext) {
        guard let entity = _Company.entity(managedObjectContext: managedObjectContext) else { return nil }
        self.init(entity: entity, insertInto: managedObjectContext)
    }

    // MARK: - Properties

    @NSManaged open
    var name: String!

    @NSManaged open
    var symbol: String!

    // MARK: - Relationships

    @NSManaged open
    var stockupdates: NSSet

    open func stockupdatesSet() -> NSMutableSet {
        return self.stockupdates.mutableCopy() as! NSMutableSet
    }

}

extension _Company {

    open func addStockupdates(_ objects: NSSet) {
        let mutable = self.stockupdates.mutableCopy() as! NSMutableSet
        mutable.union(objects as Set<NSObject>)
        self.stockupdates = mutable.copy() as! NSSet
    }

    open func removeStockupdates(_ objects: NSSet) {
        let mutable = self.stockupdates.mutableCopy() as! NSMutableSet
        mutable.minus(objects as Set<NSObject>)
        self.stockupdates = mutable.copy() as! NSSet
    }

    open func addStockupdatesObject(_ value: StockUpdate) {
        let mutable = self.stockupdates.mutableCopy() as! NSMutableSet
        mutable.add(value)
        self.stockupdates = mutable.copy() as! NSSet
    }

    open func removeStockupdatesObject(_ value: StockUpdate) {
        let mutable = self.stockupdates.mutableCopy() as! NSMutableSet
        mutable.remove(value)
        self.stockupdates = mutable.copy() as! NSSet
    }

}

