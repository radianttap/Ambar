//
//  TmplTestController.swift
//  RTSwiftCoreDataStack
//
//  Created by Aleksandar Vacić on 15.6.17..
//  Copyright © 2017. Radiant Tap. All rights reserved.
//

import UIKit
import CoreData

final class TmplTestController: UIViewController {

	var moc: NSManagedObjectContext? {
		didSet {
//			if !self.isViewLoaded { return }
			testDataSource()
		}
	}

}


fileprivate extension TmplTestController {

	func testDataSource() {
		guard let moc = moc else { return }

		if let mo = TmplTestEntity(managedObjectContext: moc) {
			mo.counterOptionalScalar = 100
			mo.isActiveScalar = false
		}

		moc.save {
			[unowned self] saveError in
			guard let saveError = saveError else {
				self.readTestRecords()
				return
			}
			print(saveError)
		}
	}


	func readTestRecords() {
		guard let moc = moc else { return }

		let arr = TmplTestEntity.fetch(in: moc)
		print(arr)
	}
}
