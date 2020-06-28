//
//  CoreDataStack.swift
//  Ambar
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation
import CoreData

@available(iOS 8.4, watchOS 3.0, tvOS 10.0, *)
public final class CoreDataStack {
	public typealias Callback = () -> Void

	/// Until this is true, data store is not available.
	///	Do **not** attempt to access any of the Core Data objects until `isReady=true`
	public private(set) var isReady: Bool = false

	/// Managed Model instance used by the stack
	public private(set) var dataModel: NSManagedObjectModel!

	/// Full URL to the location of the SQLite file.
	///	It's `nil` if you use in-memory storage type.
	public private(set) var storeURL: URL?

	///	Type of Core Data store. It's indirectly chosen by the initializer you're using.
	///	By default, it's SQLite.
	public private(set) var storeType: String

	///	If `false`, it means that `writerCoordinator` is the same as `mainCoordinator`.
	///	If `true`, then writerCoordinator is wholy separate NSPSC instance. (This is default).
	///
	///	Prior to iOS 10, the PSC could only handle one request at a time,
	/// which could impact reading performance if you do a lot of writes (imports) in background MOCs.
	///	In iOS 10 and later, NSPSC maintains a connection pool to SQLite and can execute one write and multiple read requests simultaneously.
	public private(set) var isUsingSeparatePersistentStoreCoordinators: Bool

	/// Instantiates the whole stack with SQLite backing, giving you full control over what model to use and where the resulting file should be.
	///
	/// - parameter storeType: String, with possible values: `NSSQLiteStoreType` or `NSInMemoryStoreType`
	/// - parameter dataModelName: String representing the name (without extension) of the model file to use. If not supplied,
	/// - parameter storeURL: Full URL where to create the .sqlite file. Must include the file at the end as well (can't be just directory). If not supplied, user's Documents directory will be used + alphanumerics from app's name. Possible use: when you want to setup the store file into completely custom location. Like say shared container in App Group. Omit or supply `nil` when using `NSInMemoryStoreType` store type.
	/// - parameter usingSeparatePSCs: (see discussion about `isUsingSeparatePersistentStoreCoordinators` property)
	/// - parameter callback: A block to call once setup is completed. RTCoreDataStack.isReady is set to true before callback is executed.
	///
	/// - returns: Instance of RTCoreDataStack
	public init(storeType: String = NSSQLiteStoreType,
				withDataModelNamed dataModel: String? = nil,
				storeURL: URL? = nil,
				usingSeparatePSCs: Bool = true,
				callback: @escaping Callback = {})
	{
		self.storeType = storeType
		self.isUsingSeparatePersistentStoreCoordinators = usingSeparatePSCs

		DispatchQueue.main.async { [unowned self] in
			self.setup(withDataModelNamed: dataModel, storeURL: storeURL, callback: callback)
		}
	}

	/// Instance of PersistentStoreCoordinator intended for main thread's contexts
	public private(set) var mainCoordinator: NSPersistentStoreCoordinator!

	/// Instance of PersistentStoreCoordinator intended for background thread's importing.
	public private(set) var writerCoordinator: NSPersistentStoreCoordinator!

	/// Main MOC, connected to mainCoordinator. Use it for all the UI
	public private(set) var mainContext: NSManagedObjectContext!
	///	Alias for `mainContext`
	public var viewContext: NSManagedObjectContext { return mainContext }

	/// Make main MOC read-only and thus prevent
	public var isMainContextReadOnly: Bool = false {
		didSet {
			if !isReady { return }
			if isMainContextReadOnly == oldValue { return }
			mainContext.mergePolicy = (isMainContextReadOnly) ? NSRollbackMergePolicy : NSMergeByPropertyStoreTrumpMergePolicy
		}
	}

	/// Enable or disable automatic merge between importer MOCs and main MOC.
	public var shouldMergeIncomingSavedObjects: Bool = true

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	private var callback: Callback?
	private var setupFlags: SetupFlags = []
}


///	There are several async steps performed to setup the library
///	These flags are used to wait until all are performed and only then call the callback
///	and set the isReady to true
private struct SetupFlags: OptionSet {
	public let rawValue: Int
	public init(rawValue:Int) {
		self.rawValue = rawValue
	}

	static let base = SetupFlags(rawValue: 1)
	static let mainPSC = SetupFlags(rawValue: 2)
	static let writePSC = SetupFlags(rawValue: 4)
	static let mainMOC = SetupFlags(rawValue: 8)

	static let done : SetupFlags = [.base, .mainPSC, .writePSC, .mainMOC]
}


public extension CoreDataStack {
	/// Returns URL for the user's Documents folder
	static var defaultStoreFolderURL: URL {
		let searchPathOption: FileManager.SearchPathDirectory
		#if os(tvOS)
		searchPathOption = .cachesDirectory
		#else
		searchPathOption = .applicationSupportDirectory
		#endif

		guard let url = FileManager.default.urls(for: searchPathOption, in: .userDomainMask).first else {
			let log = String(format: "E | %@:%@/%@ Could not fetch Application Support directory",
							 String(describing: self), #file, #line)
			fatalError(log)
		}
		return url
	}

	/// Returns String representing only alphanumerics from app's name
	private static var cleanAppName: String {
		guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
			let log = String(format: "E | %@:%@/%@ Unable to fetch CFBundleName from main bundle",
							 String(describing: self), #file, #line)
			fatalError(log)
		}
		return appName.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
	}

	static var defaultStoreFileName: String {
		return "\( cleanAppName ).sqlite"
	}

	static var defaultStoreURL: URL {
		return defaultStoreFolderURL.appendingPathComponent(defaultStoreFileName)
	}
}


//MARK:- Setup
@available(iOS 8.4, watchOS 3.0, tvOS 10.0, *)
private extension CoreDataStack {

	/// Called only once, when the entire setup is done and ready
	func setupDone(flags: SetupFlags) {
		setupFlags.insert(flags)

		if setupFlags != .done { return }
		//	if done, execute the callback and clear it
		isReady = true
		if let callback = callback {
			callback()
			self.callback = nil
		}
	}

	/// Sets up the the whole stack, giving you full control over what model to use and where the resulting file should be.
	///
	/// - parameter dataModelName: String representing the name (without extension) of the model file to use. If not supplied,
	/// - parameter storeURL: Full URL where to create the .sqlite file. Must include the file at the end as well (can't be just directory). If not supplied, user's Documents directory will be used + alphanumerics from app's name. Possible use: when you want to setup the store file into completely custom location. Like say shared container in App Group.
	/// - parameter callback: A block to call once setup is completed. RTCoreDataStack.isReady is set to true before callback is executed.
	func setup(withDataModelNamed dataModelName: String? = nil,
			   storeURL: URL? = nil,
			   callback: @escaping Callback = {})
	{
		self.callback = callback

		if storeType == NSSQLiteStoreType {
			let url: URL
			if let storeURL = storeURL {	//	if the target URL is supplied
				//	then make sure that the path is usable. create all missing directories in the path, if needed
				CoreDataStack.verify(storeURL: storeURL)
				url = storeURL
			} else {	//	otherwise build the name using cleaned app name and place in the local app's container
				url = CoreDataStack.defaultStoreURL
				CoreDataStack.verify(storeURL: url)
			}
			self.storeURL = url
		}

		let mom = managedObjectModel(named: dataModelName)
		self.dataModel = mom

		//	setup persistent store coordinators
		setupPersistentStoreCoordinators(using: mom)

		//	setup DidSaveNotification handling
		setupNotifications()

		//	report back
		setupDone(flags: .base)
	}

	func setupPersistentStoreCoordinators(using mom: NSManagedObjectModel) {
		self.mainCoordinator = {
			let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
			connectStores(toCoordinator: psc, andExecute: { [unowned self] in
				DispatchQueue.main.async { [unowned self] in
					self.setupMainContext()
				}
				self.setupDone(flags: .mainPSC)
			})
			return psc
		}()

		switch storeType {
		case NSSQLiteStoreType:
			if isUsingSeparatePersistentStoreCoordinators {
				self.writerCoordinator = {
					let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
					connectStores(toCoordinator: psc) { [unowned self] in
						self.setupDone(flags: .writePSC)
					}
					return psc
				}()

			} else {
				self.writerCoordinator = self.mainCoordinator
				self.setupDone(flags: .writePSC)
			}

		case NSInMemoryStoreType:
			//	use the same coordinator, since in-memory store is one and only
			//	no files on disk and thus no coordination to care about
			self.writerCoordinator = self.mainCoordinator
			self.setupDone(flags: .writePSC)

		default:
			break
		}

	}

	/// Attach the persistent stores to the supplied Persistent Store Coordinator.
	///
	/// - parameter psc:         Instance of PSC
	/// - parameter postConnect: Optional closure to execute after successful add (of the stores)
	func connectStores(toCoordinator psc: NSPersistentStoreCoordinator, andExecute postConnect: (()-> Void)? = nil) {
		if #available(iOS 10.0, tvOS 10.0, *) {
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
				try psc.addPersistentStore(ofType: storeType, configurationName: nil, at: storeURL, options: options)
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
		setupDone(flags: .mainMOC)
	}

	@available(iOS 10.0, tvOS 10.0, *)
	var storeDescription: NSPersistentStoreDescription {
		switch storeType {
		case NSSQLiteStoreType:
			guard let storeURL = storeURL else { fatalError("E | StoreURL missing. It's required when using SQLiteStoreType.")}
			let sd = NSPersistentStoreDescription(url: storeURL)
			//	use options that allow automatic model migrations
			sd.setOption(true as NSObject?, forKey: NSMigratePersistentStoresAutomaticallyOption)
			sd.shouldInferMappingModelAutomatically = true
			return sd

		case NSInMemoryStoreType:
			let sd = NSPersistentStoreDescription()
			sd.type = storeType
			//	use options that allow automatic model migrations
			sd.setOption(true as NSObject?, forKey: NSMigratePersistentStoresAutomaticallyOption)
			sd.shouldInferMappingModelAutomatically = true
			return sd

		default:
			fatalError("E | Must use either `NSSQLiteStoreType` (\( NSSQLiteStoreType )) or `NSInMemoryStoreType` (\( NSInMemoryStoreType )) as storeType.")
			break
		}
	}

	/// Verifies that store URL path exists. It will create all the intermediate directories specified in the path.
	/// If that fails, it will crash the app.
	///
	/// - parameter url: URL to verify. Must include the file segment at the end; this method will remove last path component and then use the rest as directory path
	static func verify(storeURL url: URL) {
		let directoryURL = url.deletingLastPathComponent()

		var isFolder: ObjCBool = true
		let isExists = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isFolder)
		if isExists && isFolder.boolValue {
			return
		}

		do {
			try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
		} catch let error {
			let log = String(format: "E | %@:%@/%@ Error verifying (creating) full URL path %@:\n%@",
			                 String(describing: self), #file, #line, directoryURL.path, error.localizedDescription)
			fatalError(log)
		}
	}

	/// Instantiates NSManagedObjectModel. If it can't create one, it will crash the app
	///
	/// - parameter name: optional name of the Model file. Useful when you want to creates two stacks and copy data between them
	///
	/// - returns: NSManagedObjectModel instance, ready to create PSC
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




//MARK:- Notifications
@available(iOS 8.4, watchOS 3.0, tvOS 10.0, *)
private extension CoreDataStack {

	//	Subscribe the stack to any context's DidSaveNotification
	func setupNotifications() {

		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(CoreDataStack.handle(notification:)),
		                                       name: .NSManagedObjectContextDidSave,
		                                       object: nil)
	}

	/// Automatically merges all new, deleted and changed objects from background importerContexts into the mainContext
	///
	/// - parameter notification: must be NSManagedObjectContextDidSave notification
	@objc func handle(notification: Notification) {
		if !shouldMergeIncomingSavedObjects { return }

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


//MARK:- Contexts
@available(iOS 8.4, watchOS 3.0, tvOS 10.0, *)
public extension CoreDataStack {
	/// Importer MOC is your best path to import large amounts of data in the background. Its `mergePolicy` is set to favor objects in memory versus those in the store, thus in case of conflicts newly imported data will trump whatever is on disk.
	///
	/// - returns: Newly created MOC with concurrency=NSPrivateQueueConcurrencyType and mergePolicy=NSMergeByPropertyObjectTrumpMergePolicy
	func importerContext() -> NSManagedObjectContext {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.persistentStoreCoordinator = writerCoordinator
		moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		return moc
	}

	/// Use temporary MOC is for cases where you need short-lived managed objects. Whatever you do in here is never saved, as its `mergePolicy` is set to NSRollbackMergePolicy. Which means all `save()` calls will silently fail
	///
	/// - returns: Newly created MOC with concurrency=NSPrivateQueueConcurrencyType and mergePolicy=NSRollbackMergePolicy, with the same PSC as `mainContext`
	func temporaryContext() -> NSManagedObjectContext {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.persistentStoreCoordinator = mainCoordinator
		moc.mergePolicy = NSRollbackMergePolicy
		return moc
	}

	/// Use this MOC for all cases where you need to allow the customer to create new objects that will be saved to disk. For example, to "add new" / "edit existing" contact in contact management app.
	///
	/// It is always set to use mainContext as its `parentContext`, so any saves are transfered to the `mainContext` and thus available to the UI.
	/// You must make sure that `mainContext` is not read-only when calling this method (assert is run and if it is read-only your app will crash).
	///
	/// - returns: Newly created MOC with concurrency=NSPrivateQueueConcurrencyType and mergePolicy=NSMergeByPropertyObjectTrumpMergePolicy and parentContext=mainManagedObjectContext
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

//	MARK: Migration

public extension CoreDataStack {
	convenience init(withDataModelNamed dataModel: String? = nil,
					 migratingFrom oldStoreURL: URL? = nil,
					 to storeURL: URL,
					 usingSeparatePSCs: Bool = true,
					 callback: @escaping Callback = {}) {
		let fm = FileManager.default

		//	what's the old URL?
		let oldURL: URL = oldStoreURL ?? CoreDataStack.defaultStoreURL

		//	is there a core data store file at the old url?
		let shouldMigrate = fm.fileExists(atPath: oldURL.path)

		//	if nothing to migrate, then just start with new URL
		if !shouldMigrate {
			self.init(withDataModelNamed: dataModel, storeURL: storeURL, usingSeparatePSCs: usingSeparatePSCs, callback: callback)
			return
		}

		//	is there a file at new URL?
		//	(maybe migration was already done and deleting old file failed originally)
		if fm.fileExists(atPath: storeURL.path) {
			//	init with new URL
			self.init(withDataModelNamed: dataModel, storeURL: storeURL, usingSeparatePSCs: usingSeparatePSCs, callback: callback)

			//	attempt to delete old file again
			deleteDocumentAtUrl(url: oldURL)
			return
		}


		//	ok, we need to migrate.

		//	so first make a dummy instance
		self.init()
		self.isUsingSeparatePersistentStoreCoordinators = usingSeparatePSCs

		//	new storeURL must be full file URL, not directory URL
		CoreDataStack.verify(storeURL: storeURL)

		//	build Model
		let mom = managedObjectModel(named: dataModel)
		self.dataModel = mom

		//	setup temporary migration PSC
		let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
		//	connect old store
		self.storeURL = oldURL
		connectStores(toCoordinator: psc)

		//	ok, now migrate to new location
		var storeOptions = [AnyHashable : Any]()
		storeOptions[NSMigratePersistentStoresAutomaticallyOption] = true
		storeOptions[NSInferMappingModelAutomaticallyOption] = true

		if let store = psc.persistentStore(for: oldURL) {
			do {
				try psc.migratePersistentStore(store, to: storeURL, options: storeOptions, withType: NSSQLiteStoreType)

				//	successful migration, so update the value of store URL
				self.storeURL = storeURL
				self.callback = callback

				//	setup persistent store coordinators
				setupPersistentStoreCoordinators(using: mom)

				//	setup DidSaveNotification handling
				setupNotifications()

				//	report back
				setupDone(flags: .base)

				deleteDocumentAtUrl(url: oldURL)

			} catch let error {
				let log = String(format: "E | %@:%@/%@ Failed to migrate old store to new URL: %@,\n%@",
								 String(describing: self), #file, #line, storeURL.path, error as NSError)
				fatalError(log)
			}
		} else {
			let log = String(format: "E | %@:%@/%@ Failed to migrate due to missing old store",
							 String(describing: self), #file, #line)
			fatalError(log)
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


