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

    @NSManaged public var ask: NSDecimalNumber

    @NSManaged public var bid: NSDecimalNumber

    @NSManaged public var change: NSDecimalNumber

    @NSManaged public var date: Date

    // MARK: - Relationships

    @NSManaged public var company: Company

}
