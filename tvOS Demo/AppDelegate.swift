//
//  AppDelegate.swift
//  tvOS Demo
//
//  Created by Aleksandar Vacić on 9/7/18.
//  Copyright © 2018 Radiant Tap. All rights reserved.
//

import UIKit
import RTCoreDataStack

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var coreDataStack: RTCoreDataStack!


	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

		coreDataStack = RTCoreDataStack {
			print("RTCoreDataStack is ready")
		}

		return true
	}

}

