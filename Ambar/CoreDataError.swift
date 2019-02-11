//
//  CoreDataError.swift
//  RTSwiftCoreDataStack
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation

public enum CoreDataError: Error {
	case saveFailed(Error)
	case deleteFailed(Error)
}
