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

	}
}
