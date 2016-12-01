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

@available(iOS 8.4, watchOS 2.0, tvOS 9.0, *)
public final class RTCoreDataStack {
	public typealias Callback = () -> Void

	/// Until this is true, data store is not available. Do not attempt to access any of the Core Data objects until isReady=true
	public fileprivate(set) var isReady: Bool = false

	/// Managed Model instance used by the stack
	public fileprivate(set) var dataModel: NSManagedObjectModel!

	/// Full URL to the location of the SQLite file
	public fileprivate(set) var storeURL: URL!

	/// Instantiates the whole stack, giving you full control over what model to use and where the resulting file should be.
	///
	/// - parameter dataModelName: String representing the name (without extension) of the model file to use. If not supplied,
	/// - parameter storeURL: Full URL where to create the .sqlite file. Must include the file at the end as well (can't be just directory). If not supplied, user's Documents directory will be used + alphanumerics from app's name. Possible use: when you want to setup the store file into completely custom location. Like say shared container in App Group.
	/// - parameter callback: A block to call once setup is completed. RTCoreDataStack.isReady is set to true before callback is executed.
	///
	/// - returns: Instance of RTCoreDataStack
	public init(withDataModelNamed dataModel: String? = nil, storeURL: URL? = nil, callback: @escaping Callback = {_ in}) {
		DispatchQueue.main.async { [unowned self] in
			self.setup(withDataModelNamed: dataModel, storeURL: storeURL, callback: callback)
		}
	}

	/// Instance of PersistentStoreCoordinator intended for main thread's contexts
	public fileprivate(set) var mainCoordinator: NSPersistentStoreCoordinator!

	/// Instance of PersistentStoreCoordinator intended for background thread's importing.
	public fileprivate(set) var writerCoordinator: NSPersistentStoreCoordinator!

	/// Main MOC, connected to mainCoordinator. Use it for all the UI
	public fileprivate(set) var mainContext: NSManagedObjectContext!

	/// Make main MOC read-only and thus prevent
	public var isMainContextReadOnly: Bool = false {
		didSet {
			if !isReady { return }
			if isMainContextReadOnly == oldValue { return }
			mainContext.mergePolicy = (isMainContextReadOnly) ? NSRollbackMergePolicy : NSMergeByPropertyStoreTrumpMergePolicy
		}
	}

	/// Enable or disable automatic merge between importerMOCs and mainMOC
	public var shouldMergeIncomingSavedObjects: Bool = true

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	fileprivate var callback: Callback?
	fileprivate var setupFlags: SetupFlags = .none
}


///	There are several async steps performed to setup the library
///	These flags are used to wait until all are performed and only then call the callback
///	and set the isReady to true
private struct SetupFlags: OptionSet {
	public let rawValue: Int
	public init(rawValue:Int) {
		self.rawValue = rawValue
	}

	static let none = SetupFlags(rawValue: 0)
	static let base = SetupFlags(rawValue: 1)
	static let mainPSC = SetupFlags(rawValue: 2)
	static let writePSC = SetupFlags(rawValue: 4)
	static let mainMOC = SetupFlags(rawValue: 8)

	static let done : SetupFlags = [.base, .mainPSC, .writePSC, .mainMOC]
}




@available(iOS 8.4, watchOS 2.0, tvOS 9.0, *)
fileprivate typealias Setup = RTCoreDataStack
@available(iOS 8.4, watchOS 2.0, tvOS 9.0, *)
fileprivate extension Setup {

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
	func setup(withDataModelNamed dataModelName: String? = nil, storeURL: URL? = nil, callback: @escaping Callback = {_ in}) {
		self.callback = callback

		let url: URL
		if let storeURL = storeURL {	//	if the target URL is supplied
			//	then make sure that the path is usable. create all missing directories in the path, if needed
			verify(storeURL: storeURL)
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
				DispatchQueue.main.async { [unowned self] in
					self.setupMainContext()
				}
				self.setupDone(flags: .mainPSC)
			})
			return psc
		}()

		self.writerCoordinator = {
			let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
			connectStores(toCoordinator: psc) { [unowned self] in
				self.setupDone(flags: .writePSC)
			}
			return psc
		}()

		//	setup DidSaveNotification handling
		setupNotifications()

		//	report back
		setupDone(flags: .base)
	}

	/// Attach the persistent stores to the supplied Persistent Store Coordinator.
	///
	/// - parameter psc:         Instance of PSC
	/// - parameter postConnect: Optional closure to execute after successful add (of the stores)
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
		setupDone(flags: .mainMOC)
	}

	@available(iOS 10.0, *)
	var storeDescription: NSPersistentStoreDescription {
		let sd = NSPersistentStoreDescription(url: storeURL)
		//	use options that allow automatic model migrations
		sd.setOption(true as NSObject?, forKey: NSMigratePersistentStoresAutomaticallyOption)
		sd.shouldInferMappingModelAutomatically = true
		return sd
	}

	/// Returns URL for the user's Documents folder
	var defaultStoreURL: URL {
		guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			let log = String(format: "E | %@:%@/%@ Could not fetch Documents directory",
			                 String(describing: self), #file, #line)
			fatalError(log)
		}
		return documentsURL
	}

	/// Verifies that store URL path exists. It will create all the intermediate directories specified in the path.
	/// If that fails, it will crash the app.
	///
	/// - parameter url: URL to verify. Must include the file segment at the end; this method will remove last path component and then use the rest as directory path
	func verify(storeURL url: URL) {
		let directoryURL = url.deletingLastPathComponent()
		do {
			try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
		} catch(let error) {
			let log = String(format: "E | %@:%@/%@ Error verifying (creating) full URL path %@:\n%@",
			                 String(describing: self), #file, #line, directoryURL.path, error.localizedDescription)
			fatalError(log)
		}
	}

	/// Returns String representing only alphanumerics from app's name
	var cleanAppName: String {
		guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
			let log = String(format: "E | %@:%@/%@ Unable to fetch CFBundleName from main bundle",
			                 String(describing: self), #file, #line)
			fatalError(log)
		}
		return appName.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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




@available(iOS 8.4, watchOS 2.0, tvOS 9.0, *)
fileprivate typealias Notifications = RTCoreDataStack
@available(iOS 8.4, watchOS 2.0, tvOS 9.0, *)
fileprivate extension Notifications {

	//	Subscribe the stack to any context's DidSaveNotification
	func setupNotifications() {

		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(Notifications.handle(notification:)),
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


@available(iOS 8.4, watchOS 2.0, tvOS 9.0, *)
fileprivate typealias Contexts = RTCoreDataStack
@available(iOS 8.4, watchOS 2.0, tvOS 9.0, *)
public extension Contexts {
	/// Importer MOC is your best path to import large amounts of data in the background. Its `mergePolicy` is set to favor objects in memory versus those in the store, thus in case of conflicts newly imported data will trump whatever is on disk.
	///
	/// - returns: Newly created MOC with concurrency=NSPrivateQueueConcurrencyType and mergePolicy=NSMergeByPropertyObjectTrumpMergePolicy
	public func importerContext() -> NSManagedObjectContext {
		let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
		moc.persistentStoreCoordinator = writerCoordinator
		moc.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
		return moc
	}

	/// Use temporary MOC is for cases where you need short-lived managed objects. Whatever you do in here is never saved, as its `mergePolicy` is set to NSRollbackMergePolicy. Which means all `save()` calls will silently fail
	///
	/// - returns: Newly created MOC with concurrency=NSPrivateQueueConcurrencyType and mergePolicy=NSRollbackMergePolicy, with the same PSC as `mainContext`
	public func temporaryContext() -> NSManagedObjectContext {
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
	public func editorContext() -> NSManagedObjectContext {
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
