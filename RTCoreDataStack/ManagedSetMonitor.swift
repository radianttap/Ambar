//
//  ManagedSetMonitor.swift
//  RTSwiftCoreDataStack
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation
import CoreData

///	Offers real-time observation over a particular NSManagedObject entity.
///	If any changes are observed in the given objects – either update or delete – supplied callback will be called

public final class ManagedSetMonitor<T>: NSObject where T: NSManagedObject {
	///	First argument is a set of NSManagedObjects which were updated in the MOC.
	///	Second argument is a set of NSManagedObjectIDs which were deleted from the MOC.
	public typealias Callback = (Set<T>, Set<NSManagedObjectID>) -> Void

	public private(set) var objects: Set<T>
	public private(set) var objectIDs: Set<NSManagedObjectID>

	private var callback: Callback = {_, _ in}

	private init(objects: Set<T>) {
		self.objects = objects
		self.objectIDs = Set( objects.map{ $0.objectID } )
		super.init()

		observe()
	}
}

extension ManagedSetMonitor {
	///	Supply a set of NSManagedObject instances and a `Callback` to get informed when anything happens with them.
	public convenience init(objects: Set<T>, callback: @escaping Callback) {
		self.init(objects: objects)
		self.callback = callback
	}




	private func observe() {
		let nc = NotificationCenter.default
		let name = Notification.Name.NSManagedObjectContextObjectsDidChange

		nc.addObserver(forName: name, object: nil, queue: OperationQueue.main) {
			[weak self] note in
			guard let self = self else { return }
			guard let userInfo = note.userInfo as? [String: Any] else { return }

			var updatedSet: Set<T> = []
			var deletedSet: Set<NSManagedObjectID> = []

			if let deletedObjects = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObject> {
				//	filter-out anything that's not T
				let deletedTs: Set<T> = Set(deletedObjects.compactMap { return $0 as? T })
				//	pick up just objectIDs
				let deletedObjectIDs = Set(deletedTs.map({ $0.objectID }))
				//	is there any overlap?
				let set = self.objectIDs.intersection(deletedObjectIDs)

				//	if yes, clear deleted objects and their IDs from local watched set
				if set.count > 0 {
					self.objectIDs.subtract(set)
					self.objects.subtract(deletedTs)
				}

				deletedSet = set
			}

			if let updatedObjects = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject> {
				//	filter-out anything that's not T
				let updatedTs: Set<T> = Set(updatedObjects.compactMap { return $0 as? T })
				//	is there any overlap?
				let set = self.objects.intersection(updatedTs)

				updatedSet = set
			}

			//	report back
			if updatedSet.count > 0 || deletedSet.count > 0 {
				self.callback(updatedSet, deletedSet)
			}
		}
	}
}
