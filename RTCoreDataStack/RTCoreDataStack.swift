//
//  RTCoreDataStack.swift
//  RTCoreDataStack
//
//  Created by Aleksandar Vacić on 24.10.16..
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation
import CoreData

@available(iOS 8.4, *)
public final class RTCoreDataStack {
	typealias Callback = () -> Void

	static let shared = RTCoreDataStack()

	fileprivate(set) var isReady: Bool = false

	fileprivate(set) var dataModel: NSManagedObjectModel!

	fileprivate(set) var storeURL: URL!

	init(withDataModelNamed dataModel: String? = nil, storeURL: URL? = nil, callback: Callback? = nil) {
		setup(withDataModelNamed: dataModel, storeURL: storeURL, callback: callback)
	}

	fileprivate(set) var mainCoordinator: NSPersistentStoreCoordinator!

	fileprivate(set) var writerCoordinator: NSPersistentStoreCoordinator!

	fileprivate(set) var mainContext: NSManagedObjectContext!

	var isMainContextReadOnly: Bool = false {
		didSet {
			if !isReady { return }
			if isMainContextReadOnly == oldValue { return }
			mainContext.mergePolicy = (isMainContextReadOnly) ? NSRollbackMergePolicy : NSMergeByPropertyStoreTrumpMergePolicy
		}
	}

}




fileprivate typealias Setup = RTCoreDataStack
fileprivate extension Setup {
	func setup(withDataModelNamed dataModel: String? = nil, storeURL: URL? = nil, callback: Callback? = nil) {

	}


	func setupMainContext() {
		let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		moc.persistentStoreCoordinator = mainCoordinator
		moc.mergePolicy = (isMainContextReadOnly) ? NSRollbackMergePolicy : NSMergeByPropertyStoreTrumpMergePolicy

		mainContext = moc
	}

	var defaultStoreURL: URL {
		guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			let log = String(format: "E | %@:%@/%@ Could not fetch Documents directory",
			                 String(describing: self), #file, #line)
			fatalError(log)
		}
		return documentsURL
	}
}



fileprivate typealias Contexts = RTCoreDataStack
public extension Contexts {
	func importerContext() -> NSManagedObjectContext {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.persistentStoreCoordinator = writerCoordinator
		moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		return moc
	}

	func temporaryContext() -> NSManagedObjectContext {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.persistentStoreCoordinator = mainCoordinator
		moc.mergePolicy = NSRollbackMergePolicy
		return moc
	}

	func editorContext() -> NSManagedObjectContext {
		if isMainContextReadOnly {
			let log = String(format: "E | %@:%@/%@ Can't create editorContext when isMainContextReadOnly=true.\nHint: you can set it temporary to false, make the changes, save them using save(callback:) and revert to true inside the callback block.",
			                 String(describing: self), #file, #line)
			fatalError(log)
		}

		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.parent = mainContext
		moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		return moc
	}
}
