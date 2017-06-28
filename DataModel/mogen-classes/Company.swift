import Foundation
import CoreData
import RTCoreDataStack

@objc(Company)
public class Company: NSManagedObject {

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

	required public init?(managedObjectContext moc: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entity(forEntityName: "Company", in: moc) else { return nil }
		super.init(entity: entity, insertInto: moc)
	}
}

extension Company: ManagedObjectType {}
