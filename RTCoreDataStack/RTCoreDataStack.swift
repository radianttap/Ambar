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

	fileprivate(set) var isReady: Bool = false

	fileprivate(set) var dataModel: NSManagedObjectModel!

	fileprivate(set) var storeURL: URL!

	init(withDataModelNamed dataModel: String? = nil, storeURL: URL? = nil, callback: @escaping Callback = {_ in}) {
		DispatchQueue.main.async { [unowned self] in
			self.setup(withDataModelNamed: dataModel, storeURL: storeURL, callback: callback)
		}
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

	var shouldMergeIncomingSavedObjects: Bool = true

	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}




fileprivate typealias Setup = RTCoreDataStack
fileprivate extension Setup {
	func setup(withDataModelNamed dataModelName: String? = nil, storeURL: URL? = nil, callback: Callback = {_ in}) {

		let url: URL
		if let storeURL = storeURL {	//	if the target URL is supplied
			//	then make sure that the path is usable. create all missing directories in the path, if needed
			url = storeURL
		} else {	//	otherwise build the name using cleaned app name and place in the local app's container
			url = defaultStoreURL.appendingPathComponent(cleanAppName).appendingPathExtension("sqlite")
		}
		let mom = managedObjectModel(named: dataModelName)

		self.storeURL = url
		self.dataModel = mom

		//	setup persistent store coordinators

		self.mainCoordinator = {
			let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
			connectStores(toCoordinator: psc, andExecute: { [unowned self] in
				self.setupMainContext()
			})
			return psc
		}()

		self.writerCoordinator = {
			let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
			connectStores(toCoordinator: psc)
			return psc
		}()

		//	setup DidSaveNotification handling
		setupNotifications()

		//	report back
		callback()
	}

	func connectStores(toCoordinator psc: NSPersistentStoreCoordinator, andExecute postConnect: (()-> Void)? = nil) {
		if #available(iOS 10.0, *) {
			psc.addPersistentStore(with: storeDescription, completionHandler: { [unowned self] (sd, error) in
				if let error = error {
					let log = String(format: "E | %@:%@/%@ Error adding persistent stores to coordinator %@:\n%@",
					                 String(describing: self), #file, #line, String(describing: psc), error.localizedDescription)
					fatalError(log)
				}
				if let postConnect = postConnect {
					postConnect()
				}
			})
		} else {
			//	fallback for < iOS 10
			let options = [
				NSMigratePersistentStoresAutomaticallyOption: true,
				NSInferMappingModelAutomaticallyOption: true
			]
			do {
				try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
				if let postConnect = postConnect {
					postConnect()
				}
			} catch (let error) {
				let log = String(format: "E | %@:%@/%@ Error adding persistent stores to coordinator %@:\n%@",
				                 String(describing: self), #file, #line, String(describing: psc), error.localizedDescription)
				fatalError(log)
			}
		}
	}

	func setupMainContext() {
		let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
		moc.persistentStoreCoordinator = mainCoordinator
		moc.mergePolicy = (isMainContextReadOnly) ? NSRollbackMergePolicy : NSMergeByPropertyStoreTrumpMergePolicy

		mainContext = moc
	}

	@available(iOS 10.0, *)
	var storeDescription: NSPersistentStoreDescription {
		let sd = NSPersistentStoreDescription(url: storeURL)
		//	use options that allow automatic model migrations
		sd.setOption(true as NSObject?, forKey: NSMigratePersistentStoresAutomaticallyOption)
		sd.shouldInferMappingModelAutomatically = true
		return sd
	}

	var defaultStoreURL: URL {
		guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			let log = String(format: "E | %@:%@/%@ Could not fetch Documents directory",
			                 String(describing: self), #file, #line)
			fatalError(log)
		}
		return documentsURL
	}

	var cleanAppName: String {
		guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
			let log = String(format: "E | %@:%@/%@ Unable to fetch CFBundleName from main bundle",
			                 String(describing: self), #file, #line)
			fatalError(log)
		}
		return appName.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
	}

	func managedObjectModel(named name: String? = nil) -> NSManagedObjectModel {
		if name == nil {
			guard let mom = NSManagedObjectModel.mergedModel(from: nil) else {
				let log = String(format: "E | %@:%@/%@ Unable to create ManagedObjectModel by merging all models in the main bundle",
				                 String(describing: self), #file, #line)
				fatalError(log)
			}
			return mom
		}

		guard
			let url = Bundle.main.url(forResource: name, withExtension: "momd"),
			let mom = NSManagedObjectModel(contentsOf: url)
		else {
			let log = String(format: "E | %@:%@/%@ Unable to create ManagedObjectModel using name %@",
			                 String(describing: self), #file, #line, name!)
			fatalError(log)
		}

		return mom
	}

}




fileprivate typealias Notifications = RTCoreDataStack
fileprivate extension Notifications {

	func setupNotifications() {

		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(Notifications.handle(notification:)),
		                                       name: .NSManagedObjectContextDidSave,
		                                       object: nil)
	}

	@objc func handle(notification: Notification) {
		if !shouldMergeIncomingSavedObjects { return }

		let inserted = notification.userInfo?[NSInsertedObjectsKey] as? [NSManagedObject] ?? []
		let deleted = notification.userInfo?[NSDeletedObjectsKey] as? [NSManagedObject] ?? []
		let updated = notification.userInfo?[NSUpdatedObjectsKey] as? [NSManagedObject] ?? []
		//	is there anything to do?
		if inserted.count == 0 && deleted.count == 0 && updated.count == 0 { return }
		//	only deal with notifications coming from MOC
		guard let savedContext = notification.object as? NSManagedObjectContext else { return }

		// ignore change notifications from the main MOC
		if savedContext === mainContext { return }

		// ignore change notifications from the direct child of the mainContext. this merges automatically when save is invoked
		if let parentContext = savedContext.parent {
			if parentContext === mainContext { return }
		}

		// ignore stuff from unknown PSCs
		if let coordinator = savedContext.persistentStoreCoordinator {
			if coordinator !== mainCoordinator && coordinator !== writerCoordinator { return }
		}

		mainContext.perform({ [unowned self] in
			self.mainContext.mergeChanges(fromContextDidSave: notification)
		})
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
