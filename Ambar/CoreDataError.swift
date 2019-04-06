//
//  CoreDataError.swift
//  Ambar
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation

public enum CoreDataError: Error {
	case readFailed
	case saveFailed(Error)
	case deleteFailed(Error)
}
