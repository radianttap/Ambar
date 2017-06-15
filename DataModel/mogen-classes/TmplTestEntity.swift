import Foundation
import CoreData

@objc(TmplTestEntity)
public class TmplTestEntity: NSManagedObject {

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

	required public init?(managedObjectContext moc: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entity(forEntityName: "TmplTestEntity", in: moc) else { return nil }
		super.init(entity: entity, insertInto: moc)
	}
}
