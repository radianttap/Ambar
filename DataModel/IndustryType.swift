//
//  IndustryType.swift
//  RTSwiftCoreDataStack
//
//  Created by Aleksandar Vacić on 7/2/18.
//  Copyright © 2018 Radiant Tap. All rights reserved.
//

import Foundation
import RTCoreDataStack

@objc public enum IndustryType: Int16 {
	case any
	case security
	case food
	case medical
	case mechanics
	case entertainment
}

extension IndustryType: CoreDataRepresentable {
	public static let coredataFallback = IndustryType.any
}

