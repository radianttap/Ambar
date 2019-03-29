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
	/// - Throws: `CoreDataError.readFailed` if casting into `T` is no successful or Core Data exceptions thrown by either `existingObject(with:)` or `object(with:)`.
	func localInstance<T>(of mo: T) throws -> T
		where T: NSManagedObject & ManagedObjectType
	{
		if mo.managedObjectContext == self {
			refresh(mo, mergeChanges: true)
			return mo
		}

		if let obj = try existingObject(with: mo.objectID) as? T {
			return obj
		} else if let obj = object(with: mo.objectID) as? T {
			return obj
		}

		throw CoreDataError.readFailed
	}
	/// Performs save on the given context. Automatically saves its parentContext if available.
	///	If any errors occur, it will return them in the optional callback.
	///
	///	Thus you can simply call this as `moc.save()`
	///
	/// - parameter callback: closure to be informed about possible errors during save. Or simply as pingback so you know where the save is completed.
	///
	func save(_ callback: @escaping (CoreDataError?) -> Void = {_ in}) {
		if !self.hasChanges {
			callback(nil)
			return
		}

		//	async save, to not block the thread it's called on
		self.performAndWait {
			do {
				try self.save()

				//	if there's a parentContext, save that one too
				if let parentContext = self.parent {
					parentContext.save(callback)
					return;
				}

				callback(nil)

			} catch(let error) {
//				let log = String(format: "E | %@:%@/%@ Error saving context:\n%@",
//				                 String(describing: self), #file, #line, error.localizedDescription)
//				print(log)
				callback( CoreDataError.saveFailed(error) )
			}
		}
	}
}
