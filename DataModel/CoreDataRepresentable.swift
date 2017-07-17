//
//  CoreDataRepresentable.swift
//  RTSwiftCoreDataStack
//
//  Copyright © 2017 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation

///	Should be implemented by custom types used in Core Data
protocol CoreDataRepresentable {
	associatedtype CoreDataBaseType

	///	This is the base type for the attribute. Say Int16 for simple enum values
	var coredataValue: CoreDataBaseType { get }

	///	Must be able to build the custom type using the provided value
	init?(coredataValue: CoreDataBaseType)

	///	Fallback value to use if the previous init? fails to return a value
	static var coredataFallback: Self { get }
}

//	Int*-based enums can easily support this

extension RawRepresentable where Self: CoreDataRepresentable {
	var coredataValue: Self.RawValue { return self.rawValue }

	init?(coredataValue: CoreDataBaseType) {
		self.init(rawValue: coredataValue as! Self.RawValue)
	}

	//	You only need to pick what‘s default value in the actual enum
}

