// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to TmplTestEntity.swift instead.

import CoreData

public extension TmplTestEntity {

	public struct Attributes {
		static let amountOptional = "amountOptional"
		static let counterOptionalScalar = "counterOptionalScalar"
		static let dateLastAccessedOptional = "dateLastAccessedOptional"
		static let dateReleasedOptionalScalar = "dateReleasedOptionalScalar"
		static let hintOptional = "hintOptional"
		static let isActiveScalar = "isActiveScalar"
		static let isCorrectOptionalScalar = "isCorrectOptionalScalar"
		static let isShownTransient = "isShownTransient"
		static let name = "name"
		static let priceScalar = "priceScalar"
		static let viewsCountOptional = "viewsCountOptional"
	}

    // MARK: - Properties

    @NSManaged public var amountOptional: NSDecimalNumber?

	public var counterOptionalScalar: Int64? {
		get {
			let key = TmplTestEntity.Attributes.counterOptionalScalar
			willAccessValue(forKey: key)
			defer { didAccessValue(forKey: key) }

			return primitiveValue(forKey: key) as? Int64
		}
		set {
			let key = TmplTestEntity.Attributes.counterOptionalScalar
			willChangeValue(forKey: key)
			defer { didChangeValue(forKey: key) }

			guard let value = newValue else {
				setPrimitiveValue(nil, forKey: key)
				return
			}
			setPrimitiveValue(value, forKey: key)
		}
	}

    @NSManaged public var dateLastAccessedOptional: Date?

    @NSManaged public var dateReleasedOptionalScalar: Date?

    @NSManaged public var hintOptional: String?

	@NSManaged public var isActiveScalar: Bool

	public var isCorrectOptionalScalar: Bool? {
		get {
			let key = TmplTestEntity.Attributes.isCorrectOptionalScalar
			willAccessValue(forKey: key)
			defer { didAccessValue(forKey: key) }

			return primitiveValue(forKey: key) as? Bool
		}
		set {
			let key = TmplTestEntity.Attributes.isCorrectOptionalScalar
			willChangeValue(forKey: key)
			defer { didChangeValue(forKey: key) }

			guard let value = newValue else {
				setPrimitiveValue(nil, forKey: key)
				return
			}
			setPrimitiveValue(value, forKey: key)
		}
	}

	@NSManaged public var isShownTransient: Bool

    @NSManaged public var name: String

    @NSManaged public var priceScalar: NSDecimalNumber

	@NSManaged public var viewsCountOptional: NSNumber?

    // MARK: - Relationships

}
