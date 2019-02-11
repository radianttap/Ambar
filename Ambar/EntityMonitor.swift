//
//  EntityMonitor.swift
//  Ambar
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation
import CoreData

///	Monitors for any kind of changes – insert, update, delete – for objects of particular type.
public final class EntityMonitor<T>: NSObject where T: NSManagedObject {
	///	Each argument is set of: inserted, updated, deleted objects
	public typealias Callback = (Set<T>, Set<T>, Set<T>) -> Void

	private var callback: Callback = {_, _, _ in}
	private var moc: NSManagedObjectContext
	private var predicate: NSPredicate?

	private init(context: NSManagedObjectContext) {
		self.moc = context
		super.init()
	}

	deinit {
		let nc = NotificationCenter.default
		nc.removeObserver(self)
	}
}

extension EntityMonitor {
	///	Supply `Callback` to get informed when objects representing entity `T` are inserted, updated, deleted from given `NSManagedObjectContext`.
	public convenience init(context: NSManagedObjectContext, predicate: NSPredicate? = nil, callback: @escaping Callback) {
		self.init(context: context)
		self.callback = callback
		self.predicate = predicate

		observe()
	}

	private func observe() {
		let nc = NotificationCenter.default
		let name = Notification.Name.NSManagedObjectContextObjectsDidChange

		nc.addObserver(forName: name, object: moc, queue: OperationQueue.main) {
			[weak self] note in
			guard
				let self = self,
				let userInfo = note.userInfo as? [String: Any]
			else { return }

			var insertedSet: Set<T> = []
			var updatedSet: Set<T> = []
			var deletedSet: Set<T> = []

			if let insertedObjects = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject> {
				//	filter-out anything that's not T
				let set: Set<T> = Set(insertedObjects.compactMap { return $0 as? T })
				insertedSet = set
			}

			if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
				//	filter-out anything that's not T
				let set: Set<T> = Set(updatedObjects.compactMap { return $0 as? T })
				updatedSet = set
			}

			if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
				//	filter-out anything that's not T
				let set: Set<T> = Set(deletedObjects.compactMap { return $0 as? T })
				deletedSet = set
			}

			if let predicate = self.predicate {
				insertedSet = insertedSet.filter { predicate.evaluate(with: $0) }
				updatedSet = updatedSet.filter { predicate.evaluate(with: $0) }
				deletedSet = deletedSet.filter { predicate.evaluate(with: $0) }
			}

			//	report back
			if insertedSet.count > 0 || updatedSet.count > 0 || deletedSet.count > 0 {
				self.callback(insertedSet, updatedSet, deletedSet)
			}
		}
	}
}
