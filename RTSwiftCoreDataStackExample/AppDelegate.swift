//
//  AppDelegate.swift
//  RTSwiftCoreDataStack
//
//  Created by Aleksandar Vacić on 24.10.16..
//  Copyright © 2016. Radiant Tap. All rights reserved.
//

import UIKit
import RTCoreDataStack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate {

	var window: UIWindow?
	var coreDataStack: RTCoreDataStack!

	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

		window = UIWindow(frame: UIScreen.main.bounds)
		window?.rootViewController = TmplTestController()

		coreDataStack = RTCoreDataStack {
			[unowned self] in
			print("RTCoreDataStack is ready")

			if let vc = self.window?.rootViewController as? TmplTestController {
				vc.moc = self.coreDataStack.mainContext
			}
		}

		return true
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		window?.makeKeyAndVisible()
		return true
	}

}

