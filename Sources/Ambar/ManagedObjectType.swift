//
//  ManagedObjectType.swift
//  Ambar
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation
import CoreData

public protocol ManagedObjectType: NSFetchRequestResult {}

public extension ManagedObjectType where Self: NSManagedObject {
	static var entityName: String {
		return String(describing: self)
	}
	
	///	There‘s no sense to do anything in Core Data if `NSEntityDescription` can‘t be instantiated.
	///	Thus this method hard-crashes if object creation is not possible.
	///
	/// - Parameters:
	///   - context: valid `NSManagedObjectContext` instance
	/// - Returns: instance of `NSEntityDescription`
	static func entity(in context: NSManagedObjectContext) -> NSEntityDescription {
		return NSEntityDescription.entity(forEntityName: entityName, in: context)!
	}
	
	
	/// Updates all the attributes in the receiving object with values in the passed object
	///
	/// - Parameter object: Another instance of the same type as receiver
	func updateMatchingValues(from object: Self) {
		let attributeNames = object.entity.attributesByName.map { $0.key }
		for key in attributeNames {
			setValue(object.value(forKey: key), forKey: key)
		}
	}
	
	
	
	//	MARK: - Fetch properties
	
	/// Fetches a set of values for the given property.
	///
	/// - Parameters:
	///   - property: `String` representing the property name
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	/// - Returns: a `Set` of values with appropriate type
	/// - Throws: `AmbarError.coreDataError` if Core Data raises an error during the fetch.
	static func fetchThrowing<T>(property: String, context: NSManagedObjectContext, predicate: NSPredicate? = nil) throws(AmbarError) -> Set<T> {
		let entity = Self.entity(in: context)

		let fetchRequest = NSFetchRequest<NSDictionary>(entityName: Self.entityName)
		fetchRequest.predicate = predicate
		fetchRequest.resultType = .dictionaryResultType
		fetchRequest.returnsDistinctResults = true
		fetchRequest.propertiesToFetch = [entity.attributesByName[property] as Any]

		do {
			let results = try context.fetch(fetchRequest)
			let arr = results.compactMap { $0[property] as? T }
			return Set<T>(arr)

		} catch {
			throw AmbarError.coreDataError(error)
		}
	}

	@available(*, deprecated, renamed: "fetchThrowing(property:context:predicate:)", message: "Errors are now propagated; use fetchThrowing(...) and handle thrown AmbarError.")
	static func fetch<T>(property: String, context: NSManagedObjectContext, predicate: NSPredicate? = nil) -> Set<T> {
		(try? fetchThrowing(property: property, context: context, predicate: predicate)) ?? []
	}


	/// Fetches a list of given properties and then uses provided `init` closure
	///	to instantiate elements and return them as an array
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	///   - initWith:	A closure that is essentially an initializer for the resulting type. Accepts NSDictionary coming out of Core Data Fetch
	/// - Returns: an Array of objects
	/// - Throws: `AmbarError.coreDataError` if Core Data raises an error during the fetch.
	static func fetchThrowing<T>(
		properties: [String],
		context: NSManagedObjectContext,
		predicate: NSPredicate? = nil,
		initWith: (NSDictionary) -> T?
	) throws(AmbarError) -> [T] {
		let entity = Self.entity(in: context)

		let fetchRequest = NSFetchRequest<NSDictionary>(entityName: Self.entityName)
		fetchRequest.predicate = predicate
		fetchRequest.resultType = .dictionaryResultType
		fetchRequest.returnsDistinctResults = true

		let p = properties.map({ entity.attributesByName[$0] as Any })
		fetchRequest.propertiesToFetch = p

		do {
			let results = try context.fetch(fetchRequest)
			let arr = results.compactMap({ initWith($0) })
			return arr

		} catch {
			throw AmbarError.coreDataError(error)
		}
	}

	@available(*, deprecated, renamed: "fetchThrowing(properties:context:predicate:initWith:)", message: "Errors are now propagated; use fetchThrowing(...) and handle thrown AmbarError.")
	static func fetch<T>(
		properties: [String],
		context: NSManagedObjectContext,
		predicate: NSPredicate? = nil,
		initWith: (NSDictionary) -> T?
	) -> [T] {
		(try? fetchThrowing(properties: properties, context: context, predicate: predicate, initWith: initWith)) ?? []
	}
	
	
	
	//	MARK: - Fetch objects
	
	/// Creates `NSFetchRequest` for the type of the current object
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - includePending: Bool to set FetchRequest.includePendingChanges. Defaults to `true` (same as Core Data).
	///   - returnsObjectsAsFaults: Bool to set FetchRequest.returnsObjectsAsFaults. Defaults to `true` (same as Core Data). Set this to `false` if you want your returned objects to be fully populated which is very useful during background imports.
	///   - predicate: `NSPredicate` condition to apply to the fetch. Defaults to `nil`.
	///   - sortDescriptors: array of `NSSortDescriptor`s to apply. Defaults to `nil`.
	/// - Returns: Instance of `NSFetchRequest` with appropriate type
	static func fetchRequest(
		in context: NSManagedObjectContext,
		includePending: Bool = true,
		returnsObjectsAsFaults: Bool = true,
		relationshipKeyPathsForPrefetching: [String]? = nil,
		predicate: NSPredicate? = nil,
		sortedWith sortDescriptors: [NSSortDescriptor]? = nil
	) -> NSFetchRequest<Self> {
		let fetchRequest = NSFetchRequest<Self>(entityName: entityName)
		fetchRequest.includesPendingChanges = includePending
		fetchRequest.returnsObjectsAsFaults = returnsObjectsAsFaults
		fetchRequest.relationshipKeyPathsForPrefetching = relationshipKeyPathsForPrefetching
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
	/// - Throws: `AmbarError.coreDataError` if Core Data raises an error during the count.
	static func countThrowing(in context: NSManagedObjectContext, includePending: Bool = true, predicate: NSPredicate? = nil) throws(AmbarError) -> Int {
		let fetchRequest = NSFetchRequest<NSNumber>(entityName: Self.entityName)
		fetchRequest.predicate = predicate
		fetchRequest.includesPendingChanges = includePending
		fetchRequest.resultType = .countResultType
		fetchRequest.returnsDistinctResults = true

		do {
			return try context.count(for: fetchRequest)

		} catch {
			throw AmbarError.coreDataError(error)
		}
	}

	@available(*, deprecated, renamed: "countThrowing(in:includePending:predicate:)", message: "Errors are now propagated; use countThrowing(...) and handle thrown AmbarError.")
	static func count(in context: NSManagedObjectContext, includePending: Bool = true, predicate: NSPredicate? = nil) -> Int {
		(try? countThrowing(in: context, includePending: includePending, predicate: predicate)) ?? 0
	}
	
	/// Fetches objects of given type, **including** any pending changes in the context
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - includePending: Bool to set FetchRequest.includePendingChanges. Defaults to `true` (same as Core Data).
	///   - returnsObjectsAsFaults: Bool to set FetchRequest.returnsObjectsAsFaults. Defaults to `true` (same as CoreData). Set this to `false` if you want your returned objects to be fully populated which is very useful during background imports.
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	///   - sortDescriptors: (optional) array of `NSSortDescriptio`s to apply to the fetched results
	/// - Returns: an Array of Entity objects of appropriate type
	/// - Throws: `AmbarError.coreDataError` if Core Data raises an error during the fetch.
	static func fetchThrowing(
		in context: NSManagedObjectContext,
		includePending: Bool = true,
		returnsObjectsAsFaults: Bool = true,
		relationshipKeyPathsForPrefetching: [String]? = nil,
		predicate: NSPredicate? = nil,
		sortedWith sortDescriptors: [NSSortDescriptor]? = nil
	) throws(AmbarError) -> [Self] {

		let fr = fetchRequest(
			in: context,
			includePending: includePending,
			returnsObjectsAsFaults: returnsObjectsAsFaults,
			relationshipKeyPathsForPrefetching: relationshipKeyPathsForPrefetching,
			predicate: predicate,
			sortedWith: sortDescriptors
		)

		do {
			return try context.fetch(fr)

		} catch {
			throw AmbarError.coreDataError(error)
		}
	}

	@available(*, deprecated, renamed: "fetchThrowing(in:includePending:returnsObjectsAsFaults:relationshipKeyPathsForPrefetching:predicate:sortedWith:)", message: "Errors are now propagated; use fetchThrowing(...) and handle thrown AmbarError.")
	static func fetch(
		in context: NSManagedObjectContext,
		includePending: Bool = true,
		returnsObjectsAsFaults: Bool = true,
		relationshipKeyPathsForPrefetching: [String]? = nil,
		predicate: NSPredicate? = nil,
		sortedWith sortDescriptors: [NSSortDescriptor]? = nil
	) -> [Self] {
		(try? fetchThrowing(
			in: context,
			includePending: includePending,
			returnsObjectsAsFaults: returnsObjectsAsFaults,
			relationshipKeyPathsForPrefetching: relationshipKeyPathsForPrefetching,
			predicate: predicate,
			sortedWith: sortDescriptors
		)) ?? []
	}
	
	
	/// Looks for an object matching given predicate in the given context.
	///	Only returns the object if it‘s not a fault. This methods does not access persistent store (no Fetch).
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	/// - Returns: Non-faulted object or nil
	///
	///	Note: supplied NSPredicate should be specific enough to yied just one instance.
	///	In case there are multiple objects that satisfy given predicate, this method will return `nil` as it's impossible to generalize how to pick the right object.
	///
	///	(This likely indicates an error in data management, some time earlier in app lifecycle.)
	static func find(in context: NSManagedObjectContext, predicate: NSPredicate) -> Self? {
		let obj = context.registeredObjects.compactMap({ $0 as? Self }).first(where: ({ !$0.isFault && predicate.evaluate(with: $0) }) )
		return obj
	}
	
	
	/// First looks for an object matching given predicate in the given context.
	///	Only returns the object if it's not a fault.
	///	If not found, then goes to the persistent store (makes a Fetch).
	///
	///	If it returns an object, it's guaranteed it‘s not a fault.
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	/// - Returns: Non-faulted object or nil
	/// - Throws: `AmbarError.coreDataError` if Core Data raises an error during the fetch.
	static func findOrFetchThrowing(in context: NSManagedObjectContext, predicate: NSPredicate) throws(AmbarError) -> Self? {
		if let obj = find(in: context, predicate: predicate) { return obj }

		let fr = fetchRequest(in: context, predicate: predicate)
		fr.returnsObjectsAsFaults = false
		fr.fetchLimit = 1

		do {
			let results = try context.fetch(fr)
			return results.first

		} catch {
			throw AmbarError.coreDataError(error)
		}
	}

	@available(*, deprecated, renamed: "findOrFetchThrowing(in:predicate:)", message: "Errors are now propagated; use findOrFetchThrowing(...) and handle thrown AmbarError.")
	static func findOrFetch(in context: NSManagedObjectContext, predicate: NSPredicate) -> Self? {
		(try? findOrFetchThrowing(in: context, predicate: predicate)) ?? nil
	}
	
	
	//	MARK:	- NSFetchedResultsController
	
	/// Creates Fetched Results Controller for the current object’s type.
	///	If you supply the `sectionNameKeyPath`, make sure that same keypath is set as first in the `sortDescriptors`
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the fetch
	///   - sectionNameKeyPath:	`String` representing the keypath to create the sections
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	///   - sortDescriptors: (optional) array of `NSSortDescriptio`s to apply
	/// - Returns: Instance of `NSFetchedResultsController` with appropriate type
	static func fetchedResultsController(
		in context: NSManagedObjectContext,
		includePending: Bool = true,
		relationshipKeyPathsForPrefetching: [String]? = nil,
		sectionNameKeyPath: String? = nil,
		predicate: NSPredicate? = nil,
		sortedWith sortDescriptors: [NSSortDescriptor]? = nil
	) -> NSFetchedResultsController<Self> {
		
		let fr = fetchRequest(
			in: context,
			includePending: includePending,
			relationshipKeyPathsForPrefetching: relationshipKeyPathsForPrefetching,
			predicate: predicate,
			sortedWith: sortDescriptors
		)
		let frc: NSFetchedResultsController<Self> = NSFetchedResultsController(
			fetchRequest: fr,
			managedObjectContext: context,
			sectionNameKeyPath: sectionNameKeyPath,
			cacheName: nil
		)
		return frc
	}
	
	//	MARK:	- Deletes
	
	/// Loads the objects matching the predicate and deletes them, in MOC.
	///	Use the completion block to receive information how many objects were deleted
	///
	/// - Parameters:
	///   - context: `NSManagedObjectContext` in which to perform the batch delete
	///   - predicate: (optional) `NSPredicate` condition to apply to the fetch
	///   - completion: completion block at the end of successful delete.
	@discardableResult
	static func delete(in context: NSManagedObjectContext, predicate: NSPredicate? = nil) throws(AmbarError) -> Int {
		let fr = fetchRequest(in: context, predicate: predicate)
		fr.includesPropertyValues = false
		
		do {
			let objectsToDelete: [Self] = try context.fetch(fr)
			let count = objectsToDelete.count
			if count == 0 {
				return 0
			}
			
			objectsToDelete.forEach { context.delete($0) }
			return count
			
		} catch let error {
			throw AmbarError.coreDataError(error)
		}
	}
}

