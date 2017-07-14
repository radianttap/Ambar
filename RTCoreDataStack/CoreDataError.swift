//
//  CoreDataError.swift
//  RTSwiftCoreDataStack
//
//  Created by Aleksandar Vacić on 25.6.17..
//  Copyright © 2017. Radiant Tap. All rights reserved.
//

import Foundation

public enum CoreDataError: Error {
	case saveFailed(Error)
	case deleteFailed(Error)
}
