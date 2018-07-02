// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Company.swift instead.

import CoreData

public extension Company {

	public struct Attributes {
		static let industry = "industry"
		static let name = "name"
		static let symbol = "symbol"
	}

	public struct Relationships {
		static let stockupdates = "stockupdates"
	}

    // MARK: - Properties

	public var industry: IndustryType {
		get {
			let key = Company.Attributes.industry
			willAccessValue(forKey: key)
			defer { didAccessValue(forKey: key) }

			if let primitiveValue = primitiveValue(forKey: key) as? IndustryType.CoreDataBaseType, let value = IndustryType(coredataValue: primitiveValue) {
				return value
			}
			return IndustryType.coredataFallback
		}
		set {
			let key = Company.Attributes.industry
			willChangeValue(forKey: key)
			defer { didChangeValue(forKey: key) }

			setPrimitiveValue(newValue.coredataValue, forKey: key)
		}
	}

    @NSManaged public var name: String

    @NSManaged public var symbol: String

    // MARK: - Relationships

    @NSManaged public var stockupdates: Set<StockUpdate>

}
