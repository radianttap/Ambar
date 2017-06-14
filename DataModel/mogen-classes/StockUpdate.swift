import Foundation
import CoreData

@objc(StockUpdate)
public class StockUpdate: NSManagedObject {

    public override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

	required public init?(managedObjectContext moc: NSManagedObjectContext) {
		guard let entity = NSEntityDescription.entity(forEntityName: "StockUpdate", in: moc) else { return nil }
		super.init(entity: entity, insertInto: moc)
	}
}
