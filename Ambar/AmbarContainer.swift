//
//  CoreDataStack.swift
//  Ambar
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation
import CoreData

public final class AmbarContainer: NSPersistentContainer {
	/// Full URL to the location of the SQLite file.
	///	It's `nil` if you use in-memory storage type.
	public private(set) var storeURL: URL?

	/// Instantiates the whole stack with SQLite backing, giving you full control over what model to use and where the resulting file should be.
	///
	/// - parameter storeType: `NSPersistentStore.StoreType`
	/// - parameter dataModelName: String representing the name (without extension) of the model file to use. If not supplied, Ambar will merge all .momd found in the bundle.
	/// - parameter storeURL: Full URL where to create the `.sqlite` file. Must include the file at the end as well (can't be just directory). If not supplied, user's Documents directory will be used + alphanumerics from app's name. Possible use: when you want to setup the store file into completely custom location. Like say shared container in App Group. Omit or supply `nil` when using `.inMemory` store type.
	///
	/// - returns: Instance of `CoreDataStack`
	public init(storeType: NSPersistentStore.StoreType = .sqlite,
				withDataModelNamed dataModelName: String? = nil,
				storeURL: URL? = nil
	) throws {
		
		let url: URL
		if let storeURL = storeURL {
			//	if the target URL is supplied
			//	then make sure that the path is usable. create all missing directories in the path, if needed
			try Self.verify(storeURL: storeURL)
			url = storeURL
			
		} else {
			//	otherwise build the name using cleaned app name and place in the local app's container
			url = try Self.defaultStoreURL()
			try Self.verify(storeURL: url)
		}
		self.storeURL = url
		
		let appName = try Self.cleanAppName()
		let mom = try Self.managedObjectModel(named: dataModelName)
		super.init(name: dataModelName ?? appName, managedObjectModel: mom)

		try Self.connectStores(storeType: storeType, at: url, toCoordinator: persistentStoreCoordinator)

		switch storeType {
			case .sqlite, .binary:
				writerCoordinator = NSPersistentStoreCoordinator(managedObjectModel: mom)
				try Self.connectStores(storeType: storeType, at: url, toCoordinator: writerCoordinator)

			default:	//.inMemory
				writerCoordinator = persistentStoreCoordinator
		}

		//	finally — setup DidSaveNotification handling
		setupNotifications()
	}

	/// Instance of PersistentStoreCoordinator intended for background thread's importing.
	public private(set) var writerCoordinator: NSPersistentStoreCoordinator!

	///	By default it's `false` which means that `mergePolicy` is `NSMergePolicy.mergeByPropertyStoreTrump`.
	///
	///	If set to true, it switches to `NSMergePolicy.rollback`.
	public var isMainContextReadOnly: Bool = false {
		didSet {
			if isMainContextReadOnly == oldValue { return }
			viewContext.mergePolicy = (isMainContextReadOnly) ? NSMergePolicy.rollback : NSMergePolicy.mergeByPropertyStoreTrump
		}
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}
}

public extension AmbarContainer {
	/// Returns String representing only alphanumerics from app's name.
	static func cleanAppName() throws -> String {
		guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
			let log = String(format: "%@ | Unable to fetch CFBundleName from main bundle", #function)
			throw AmbarError.setupBlocker(log)
		}
		return appName.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
	}

	nonisolated static func defaultStoreFileName() throws -> String {
		let name = try cleanAppName()
		return "\( name ).sqlite"
	}

	nonisolated static func defaultStoreURL() throws -> URL {
		let folder = Self.defaultDirectoryURL()
		let file = try defaultStoreFileName()
		return folder.appendingPathComponent(file)
	}
}


//	MARK: - Setup

private extension AmbarContainer {
	/// Attach the persistent stores to the supplied Persistent Store Coordinator.
	///
	/// - parameter psc:         Instance of PSC
	/// - parameter postConnect: Optional closure to execute after successful add (of the stores)
	static func connectStores(storeType: NSPersistentStore.StoreType, at url: URL, toCoordinator psc: NSPersistentStoreCoordinator) throws {
		let options: [AnyHashable: Any] = [
			NSMigratePersistentStoresAutomaticallyOption: NSNumber(booleanLiteral: true),
			NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)
		]
		
		do {
			let _ = try psc.addPersistentStore(type: storeType, at: url, options: options)

		} catch let err {
			throw AmbarError.setupError(err)
		}
	}

	/// Verifies that store URL path exists. It will create all the intermediate directories specified in the path.
	/// If that fails, it throws `AmbarError.setupError`
	///
	/// - parameter url: URL to verify. Must include the file segment at the end; this method will remove last path component and then use the rest as directory path
	static func verify(storeURL url: URL) throws {
		let directoryURL = url.deletingLastPathComponent()

		var isFolder: ObjCBool = true
		let isExists = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isFolder)
		if isExists && isFolder.boolValue {
			return
		}

		do {
			try FileManager.default.createDirectory(
				at: directoryURL,
				withIntermediateDirectories: true,
				attributes: nil
			)

		} catch let err {
			throw AmbarError.setupError(err)
		}
	}

	/// Instantiates NSManagedObjectModel. If it can't create one, it will crash the app
	///
	/// - parameter name: optional name of the Model file. Useful when you want to creates two stacks and copy data between them
	///
	/// - returns: NSManagedObjectModel instance, ready to create PSC
	static func managedObjectModel(named name: String? = nil) throws -> NSManagedObjectModel {
		if name == nil {
			guard let mom = NSManagedObjectModel.mergedModel(from: nil) else {
				throw AmbarError.setupBlocker("Unable to create ManagedObjectModel by merging all models in the main bundle")
			}
			return mom
		}

		guard
			let url = Bundle.main.url(forResource: name, withExtension: "momd"),
			let mom = NSManagedObjectModel(contentsOf: url)
		else {
			let log = String(format: "Unable to create ManagedObjectModel using name: %@", name ?? "")
			throw AmbarError.setupBlocker(log)
		}
		return mom
	}
}




//	MARK: - Notifications

private extension AmbarContainer {
	//	Subscribe Ambar to any context's DidSaveNotification
	func setupNotifications() {
		NotificationCenter.default.addObserver(
			self,
		    selector: #selector(AmbarContainer.handle(notification:)),
		    name: .NSManagedObjectContextDidSave,
		    object: nil
		)
	}

	/// Automatically merges all new, deleted and changed objects from background importerContexts into the viewContext
	///
	/// - parameter notification: must be NSManagedObjectContextDidSave notification
	@objc func handle(notification: Notification) {
		//	only deal with notifications coming from MOC
		guard let savedContext = notification.object as? NSManagedObjectContext else { return }

		// ignore change notifications from the main MOC
		if savedContext === viewContext { return }

		// ignore change notifications from the direct child of the viewContext. this merges automatically when save is invoked
		if let parentContext = savedContext.parent {
			if parentContext === viewContext { return }
		}

		// ignore stuff from unknown PSCs
		if let coordinator = savedContext.persistentStoreCoordinator {
			if coordinator !== persistentStoreCoordinator && coordinator !== writerCoordinator { return }
		}

		viewContext.perform {
			[unowned self] in
			self.viewContext.mergeChanges(fromContextDidSave: notification)
		}
	}
}


//	MARK: - Contexts

public extension AmbarContainer {
	/// Importer MOC is your best path to import large amounts of data in the background. 
	/// Its `mergePolicy` is set to favor objects in memory versus those in the store, thus in case of conflicts newly imported data will trump whatever is on disk.
	///
	/// - returns: Newly created MOC with concurrency=NSPrivateQueueConcurrencyType and mergePolicy=NSMergeByPropertyObjectTrumpMergePolicy
	func importerContext() -> NSManagedObjectContext {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.persistentStoreCoordinator = writerCoordinator
		moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		return moc
	}

	/// Use temporary MOC is for cases where you need short-lived managed objects. 
	/// Whatever you do in here is never saved, as its `mergePolicy` is set to NSRollbackMergePolicy.
	/// Which means all `save()` calls will silently fail.
	///
	/// - returns: Newly created MOC with concurrency=NSPrivateQueueConcurrencyType and mergePolicy=NSRollbackMergePolicy, with the same PSC as `viewContext`
	func temporaryContext() -> NSManagedObjectContext {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.persistentStoreCoordinator = persistentStoreCoordinator
		moc.mergePolicy = NSMergePolicy.rollback
		return moc
	}

	/// Use this MOC for all cases where you need to allow the customer to create new objects that will be saved to disk. 
	/// For example, to "add new" / "edit existing" contact in contact management app.
	///
	/// It is always set to use viewContext as its `parentContext`, so any saves are transfered to the `viewContext` and thus available to the UI.
	/// You must make sure that `viewContext` is not read-only when calling this method (assert is run and if it is read-only your app will crash).
	///
	/// - returns: Newly created MOC with concurrency=NSPrivateQueueConcurrencyType and mergePolicy=NSMergeByPropertyObjectTrumpMergePolicy and parentContext=mainManagedObjectContext
	func editorContext() -> NSManagedObjectContext {
		if isMainContextReadOnly {
			let log = String(format: "E | %@:%@/%@ Can't create editorContext when isMainContextReadOnly=true.\nHint: you can set it temporary to false, make the changes, save them using save(callback:) and revert to true inside the callback block.",
			                 String(describing: self), #file, #line)
			preconditionFailure(log)
		}

		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.parent = viewContext
		moc.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
		return moc
	}
}

//	MARK: Migration

public extension AmbarContainer {
	convenience init(storeType: NSPersistentStore.StoreType = .sqlite,
					 withDataModelNamed dataModelName: String? = nil,
					 migratingFrom oldStoreURL: URL? = nil,
					 to storeURL: URL
	) async throws {
		let fm = FileManager.default

		//	what's the old URL?
		let oldURL: URL = try oldStoreURL ?? (try Self.defaultStoreURL())

		//	is there a core data store file at the old url?
		let shouldMigrate = fm.fileExists(atPath: oldURL.path)

		//	if nothing to migrate, then just start with new URL
		if !shouldMigrate {
			try self.init(storeType: storeType, withDataModelNamed: dataModelName, storeURL: storeURL)
			return
		}

		//	is there a file at new URL?
		//	(maybe migration was already done and deleting old file failed originally)
		if fm.fileExists(atPath: storeURL.path) {
			//	init with new URL
			try self.init(storeType: storeType, withDataModelNamed: dataModelName, storeURL: storeURL)

			//	attempt to delete old file again
			deleteDocumentAtUrl(url: oldURL)
			return
		}


		//	ok, we need to migrate.

		//	new storeURL must be full file URL, not directory URL
		try Self.verify(storeURL: storeURL)

		//	build Model
		let mom = try Self.managedObjectModel(named: dataModelName)

		//	migration options
		let options: [AnyHashable: Any] = [
			NSMigratePersistentStoresAutomaticallyOption: NSNumber(booleanLiteral: true),
			NSInferMappingModelAutomaticallyOption: NSNumber(booleanLiteral: true)
		]

		//	setup temporary migration PSC
		let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
		
		do {
			//	connect old store
			let store = try psc.addPersistentStore(type: storeType, at: oldURL, options: options)

			//	migrate to new URL
			let _ = try psc.migratePersistentStore(store, to: storeURL, options: options, type: storeType)
			
			try self.init(storeType: storeType, withDataModelNamed: dataModelName, storeURL: storeURL)

			//	delete file at old URL
			deleteDocumentAtUrl(url: oldURL)

		} catch let err {
			throw AmbarError.setupError(err)
		}
	}

	private func deleteDocumentAtUrl(url: URL){
		let fileCoordinator = NSFileCoordinator(filePresenter: nil)

		fileCoordinator.coordinate(writingItemAt: url, options: .forDeleting, error: nil, byAccessor: {
			(urlForModifying) -> Void in

			do {
				try FileManager.default.removeItem(at: urlForModifying)
			} catch let error {
				print("Failed to remove item with error: \(error as NSError )")
			}
		})
	}
}


