//
//  CoreDataError.swift
//  Ambar
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation

public enum CoreDataError: Error {
	case readFailed(String?)
	case saveFailed(Error)
	case deleteFailed(Error)
}

extension CoreDataError: CustomStringConvertible {
	public var description: String {
		switch self {
			case .readFailed:
				return "Failed to read from CoreData store."

			case .saveFailed:
				return "Failed to save into CoreData store."

			case .deleteFailed:
				return "Failed to delete in the CoreData store."
		}
	}
}

extension CoreDataError: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
			case .readFailed(let str):
				return "CoreData read failed:\n\( str )"

			case .saveFailed(let err):
				return "CoreData save failed:\n\( err )"

			case .deleteFailed(let err):
				return "CoreData delete failed:\n\( err )"
		}
	}
}

extension CoreDataError: LocalizedError {
	///	Description to display to customer.
	///
	///	If you have an instance of `Error` object, say `someError`, then this string will be shown if you call `someError.localizedDescription`
	public var errorDescription: String? {
		switch self {
			case .readFailed:
				return NSLocalizedString("Failed to read desired data from local storage.", comment: "CoreDataError.readFailed")

			case .saveFailed:
				return NSLocalizedString("Failed to save data changes into local storage.", comment: "CoreDataError.saveFailed")

			case .deleteFailed:
				return NSLocalizedString("Failed to delete data in the local storage", comment: "CoreDataError.deleteFailed")
		}
	}

	public var failureReason: String? {
		return debugDescription
	}
}
