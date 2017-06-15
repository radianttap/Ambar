// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Company.swift instead.

import CoreData

public extension Company {

	public struct Attributes {
		static let name = "name"
		static let symbol = "symbol"
	}

	public struct Relationships {
		static let stockupdates = "stockupdates"
	}

    // MARK: - Properties

    @NSManaged public var name: String

    @NSManaged public var symbol: String

    // MARK: - Relationships

    @NSManaged public var stockupdates: Set<StockUpdate>

}
