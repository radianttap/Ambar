// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to StockUpdate.swift instead.

import CoreData

public extension StockUpdate {

	public struct Attributes {
		static let ask = "ask"
		static let bid = "bid"
		static let change = "change"
		static let date = "date"
	}

	public struct Relationships {
		static let company = "company"
	}

    // MARK: - Properties

	//	no-scalar-available
    @NSManaged public var ask: NSDecimalNumber

	//	no-scalar-available
    @NSManaged public var bid: NSDecimalNumber

	//	no-scalar-available
    @NSManaged public var change: NSDecimalNumber

	//	no-scalar-available
    @NSManaged public var date: Date

    // MARK: - Relationships

    @NSManaged public var company: Company

}
