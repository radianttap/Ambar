//
//  NSManagedObjectContext-Extensions.swift
//  Ambar
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation
import CoreData

public extension NSManagedObjectContext {
	/// Takes NSManagedObject instance from any MOC and creates valid instance of the same object in this MOC.
	///
	/// - Parameter mo: NSManagedObject instance, from any context.
	/// - Returns: NSManagedObject instance in current context.
	/// - Throws: `AmbarError.other` if casting into `T` is no successful or Core Data exceptions thrown by either `existingObject(with:)` or `object(with:)`.

	func localInstance<T>(of mo: T) throws -> T where T: NSManagedObject & ManagedObjectType {
		guard let otherMOC = mo.managedObjectContext else {
			throw AmbarError.other("Missing ManagedObjectContext on the managed object: \(mo)")
		}

		//	if this is the same MOC, just refresh it with values from the store and return

		if otherMOC == self {
			refresh(mo, mergeChanges: true)
			return mo
		}

		//	ok, we need proper NSManagedObjectID
		let objectID: NSManagedObjectID

		if persistentStoreCoordinator != otherMOC.persistentStoreCoordinator {
			//	if PSC is not the same, need to get ManagedObjectID in current PSC
			let uri = mo.objectID.uriRepresentation()
			guard let localObjectID = otherMOC.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri) else {
				throw AmbarError.other("Failed to acquire ManagedObjectID in our PersistentStoreCoordinator, corresponding to the one from the other PSC: \( uri )")
			}
			objectID = localObjectID

		} else {
			//	otherwise simply take the value
			objectID = mo.objectID
		}

		//	get the proper object, valid in this MOC

		if let obj = try existingObject(with: objectID) as? T {
			return obj
		} else if let obj = object(with: objectID) as? T {
			return obj
		}

		throw AmbarError.other("Failed to load \( T.self ) with ManagedObjectID: \( objectID )")
	}
}
