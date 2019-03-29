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
	/// - parameter shouldPropagate: if `true`, save will propagate through parentContexts chain all the way to the store; otherwise it just save the current context. Default is `true`.
	/// - parameter callback: closure to be informed about possible errors during save. Or simply as pingback so you know where the save is completed.
	///
	func save(shouldPropagate propagated: Bool = true, callback: @escaping (CoreDataError?) -> Void = {_ in}) {
		if !hasChanges {
			callback(nil)
			return
		}

		if concurrencyType == .mainQueueConcurrencyType {
			//	in main MOC, perform async save, to avoid blocking the app
			perform {
				[unowned self] in
				self.actualSave(shouldPropagate: propagated, callback: callback)
			}
		} else {
			//	in background MOCs, perform sync save
			performAndWait {
				[unowned self] in
				self.actualSave(shouldPropagate: propagated, callback: callback)
			}
		}
	}

	private func actualSave(shouldPropagate propagated: Bool = true, callback: @escaping (CoreDataError?) -> Void = {_ in}) {
		do {
			try self.save()

			//	if there's a parentContext, save that one too
			if let parentContext = self.parent, propagated {
				parentContext.save(shouldPropagate: propagated, callback: callback)
				return
			}

			callback(nil)

		} catch let error {
			callback( CoreDataError.saveFailed(error) )
		}
	}
}
