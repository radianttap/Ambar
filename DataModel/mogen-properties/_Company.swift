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

	//	Error: Property cannot be marked @NSManaged because its type cannot be represented in Objective-C
//	@NSManaged public var int: Int?

	//	So let's workaround this problem.
	//	We will implement getter/setter on our own
	public var int: Int64? {
		get {
			willAccessValue(forKey: "int")
			defer { didAccessValue(forKey: "int") }

			return primitiveValue(forKey: "int") as? Int64
		}
		set {
			willChangeValue(forKey: "int")
			defer { didChangeValue(forKey: "int") }

			guard let value = newValue else {
				setPrimitiveValue(nil, forKey: "int")
				return
			}
			setPrimitiveValue(value, forKey: "int")
		}
	}

    // MARK: - Relationships

    @NSManaged public var stockupdates: Set<StockUpdate>

}
