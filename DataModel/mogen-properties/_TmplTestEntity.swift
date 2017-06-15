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

	//	no-scalar-available
    @NSManaged public var amountOptional: NSDecimalNumber?

	//	uses-scalar-type == true
	public var counterOptionalScalar: Int64? {
		get {
			willAccessValue(forKey: TmplTestEntityAttributes.counterOptionalScalar)
			defer { didAccessValue(forKey: TmplTestEntity.Attributes.counterOptionalScalar) }

			return primitiveValue(forKey: TmplTestEntity.Attributes.counterOptionalScalar) as? Int64
		}
		set {
			willChangeValue(forKey: TmplTestEntity.Attributes.counterOptionalScalar)
			defer { didChangeValue(forKey: TmplTestEntity.Attributes.counterOptionalScalar) }

			guard let value = newValue else {
				setPrimitiveValue(nil, forKey: TmplTestEntity.Attributes.counterOptionalScalar)
				return
			}
			setPrimitiveValue(value, forKey: TmplTestEntity.Attributes.counterOptionalScalar)
		}
	}

	//	no-scalar-available
    @NSManaged public var dateLastAccessedOptional: Date?

	//	no-scalar-available
    @NSManaged public var dateReleasedOptionalScalar: Date?

	//	no-scalar-available
    @NSManaged public var hintOptional: String?

	//	non-optional
	@NSManaged public var isActiveScalar: Bool

	//	uses-scalar-type == true
	public var isCorrectOptionalScalar: Bool? {
		get {
			willAccessValue(forKey: TmplTestEntityAttributes.isCorrectOptionalScalar)
			defer { didAccessValue(forKey: TmplTestEntity.Attributes.isCorrectOptionalScalar) }

			return primitiveValue(forKey: TmplTestEntity.Attributes.isCorrectOptionalScalar) as? Bool
		}
		set {
			willChangeValue(forKey: TmplTestEntity.Attributes.isCorrectOptionalScalar)
			defer { didChangeValue(forKey: TmplTestEntity.Attributes.isCorrectOptionalScalar) }

			guard let value = newValue else {
				setPrimitiveValue(nil, forKey: TmplTestEntity.Attributes.isCorrectOptionalScalar)
				return
			}
			setPrimitiveValue(value, forKey: TmplTestEntity.Attributes.isCorrectOptionalScalar)
		}
	}

	//	non-optional
	@NSManaged public var isShownTransient: Bool

	//	no-scalar-available
    @NSManaged public var name: String

	//	no-scalar-available
    @NSManaged public var priceScalar: NSDecimalNumber

	//	uses-scalar-type == false
	@NSManaged public var viewsCountOptional: NSNumber?

    // MARK: - Relationships

}
