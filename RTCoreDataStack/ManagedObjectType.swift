//
//  ManagedObjectType.swift
//  RTSwiftCoreDataStack
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation
import CoreData


public protocol ManagedObjectType: NSFetchRequestResult {}

public extension ManagedObjectType where Self: NSManagedObject {

	public static var entityName: String {
		return String(describing: self)
	}

	///	There‘s no sense to do anything in Core Data if `NSEntityDescription` can‘t be instantiated.
	///	Thus this method hard-crashes if object creation is not possible.
	///
	/// - Parameters:
	///   - context: valid `NSManagedObjectContext` instance
	/// - Returns: instance of `NSEntityDescription`
	public static func entity(managedObjectContext: NSManagedObjectContext) -> NSEntityDescription {
		return NSEntityDescription.entity(forEntityName: entityName, in: managedObjectContext)!
	}



	//MARK: - Fetch properties

	/// Fetches a set of values for the given property.
	///
	/// - Parameters:
	///   - property: `String` representing the property name
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	/// - Returns: a `Set` of values with appropriate type
	public static func fetch<T>(property: String, context: NSManagedObjectContext, predicate: NSPredicate? = nil) -> Set<T> {
		let entity = Self.entity(managedObjectContext: context)

		let fetchRequest = NSFetchRequest<NSDictionary>(entityName: Self.entityName)
		fetchRequest.predicate = predicate
		fetchRequest.resultType = .dictionaryResultType
		fetchRequest.returnsDistinctResults = true
		fetchRequest.propertiesToFetch = [entity.attributesByName[property] as Any]

		guard let results = try? context.fetch(fetchRequest) else { return [] }

		let arr = results.flatMap( { $0[property] as? T } )
		return Set<T>(arr)
	}


	/// Fetches a list of given properties and then uses provided `init` closure
	///	to instantiate elements and return them as an array
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	///   - initWith:	A closure that is essentially an initializer for the resulting type. Accepts NSDictionary coming out of Core Data Fetch
	/// - Returns: an Array of objects
	public static func fetch<T>(properties: [String],
	                  context: NSManagedObjectContext,
	                  predicate: NSPredicate? = nil,
	                  initWith: (NSDictionary) -> T?) -> [T] {
		let entity = Self.entity(managedObjectContext: context)

		let fetchRequest = NSFetchRequest<NSDictionary>(entityName: Self.entityName)
		fetchRequest.predicate = predicate
		fetchRequest.resultType = .dictionaryResultType
		fetchRequest.returnsDistinctResults = true

		let p = properties.map({ entity.attributesByName[$0] as Any })
		fetchRequest.propertiesToFetch = p

		guard let results = try? context.fetch(fetchRequest) else { return [] }

		let arr = results.flatMap({ initWith($0) })
		return arr
	}



	//MARK: - Fetch objects

	/// Creates `NSFetchRequest` for the type of the current object
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - includePending: Bool to set includePendingChanges. Defaults to `true`.
	///   - predicate: `NSPredicate` condition to apply to the fetch. Defaults to `nil`.
	///   - sortDescriptors: array of `NSSortDescriptor`s to apply. Defaults to `nil`.
	/// - Returns: Instance of `NSFetchRequest` with appropriate type
	public static func fetchRequest(in context: NSManagedObjectContext,
	                         includePending: Bool = true,
	                         predicate: NSPredicate? = nil,
	                         sortedWith sortDescriptors: [NSSortDescriptor]? = nil
		) -> NSFetchRequest<Self> {

		let fetchRequest = NSFetchRequest<Self>(entityName: entityName)
		fetchRequest.includesPendingChanges = includePending
		fetchRequest.predicate = predicate
		fetchRequest.sortDescriptors = sortDescriptors

		return fetchRequest
	}
	
	/// Fetches count of objects of given type, **including** any pending changes in the context
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	///   - sortDescriptors: (optional) array of `NSSortDescriptio`s to apply to the fetched results
	/// - Returns: an Array of Entity objects of appropriate type
	public static func count(in context: NSManagedObjectContext,
	                  includePending: Bool = true,
	                  predicate: NSPredicate? = nil
		) -> Int {

		let fetchRequest = NSFetchRequest<NSNumber>(entityName: Self.entityName)
		fetchRequest.predicate = predicate
		fetchRequest.includesPendingChanges = includePending
		fetchRequest.resultType = .countResultType
		fetchRequest.returnsDistinctResults = true
		guard let num = try? context.count(for: fetchRequest) else { return 0 }
		return num
	}
	
	/// Fetches objects of given type, **including** any pending changes in the context
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	///   - sortDescriptors: (optional) array of `NSSortDescriptio`s to apply to the fetched results
	/// - Returns: an Array of Entity objects of appropriate type
	public static func fetch(in context: NSManagedObjectContext,
	                  includePending: Bool = true,
	                  predicate: NSPredicate? = nil,
	                  sortedWith sortDescriptors: [NSSortDescriptor]? = nil
		) -> [Self] {

		let fr = fetchRequest(in: context, includePending: includePending, predicate: predicate, sortedWith: sortDescriptors)
		guard let results = try? context.fetch(fr) else { return [] }
		return results
	}



	//MARK:	- NSFetchedResultsController

	/// Creates Fetched Results Controller for the current object’s type.
	///	If you supply the `sectionNameKeyPath`, make sure that same keypath is set as first in the `sortDescriptors`
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - sectionNameKeyPath:	`String` representing the keypath to create the sections
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	///   - sortDescriptors: (optional) array of `NSSortDescriptio`s to apply
	/// - Returns: Instance of `NSFetchedResultsController` with appropriate type
	public static func fetchedResultsController(in context: NSManagedObjectContext,
	                                     includePending: Bool = true,
	                                     sectionNameKeyPath: String? = nil,
	                                     predicate: NSPredicate? = nil,
	                                     sortedWith sortDescriptors: [NSSortDescriptor]? = nil
		) -> NSFetchedResultsController<Self> {

		let fr = fetchRequest(in: context, includePending: includePending, predicate: predicate, sortedWith: sortDescriptors)
		let frc: NSFetchedResultsController<Self> = NSFetchedResultsController(fetchRequest: fr,
		                                                                       managedObjectContext: context,
		                                                                       sectionNameKeyPath: sectionNameKeyPath,
		                                                                       cacheName: nil)
		return frc
	}
}

