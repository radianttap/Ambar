//
//  CoreDataError.swift
//  Ambar
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

import Foundation

public enum AmbarError: Error {
	case setupError(any Error)
	case setupBlocker(String)

	case coreDataError(any Error)
	case other(String)
}

extension AmbarError: CustomStringConvertible {
	public var description: String {
		switch self {
			case .setupBlocker(let s), .other(let s):
				return s
				
			case .setupError(let err), .coreDataError(let err):
				return String(describing: err)
		}
	}
}

extension AmbarError: CustomDebugStringConvertible {
	public var debugDescription: String {
		switch self {
			case .setupBlocker(let s), .other(let s):
				return s
				
			case .setupError(let err), .coreDataError(let err):
				return String(reflecting: err)
		}
	}
}

extension AmbarError: LocalizedError {
	///	Description to display to customer.
	///
	///	If you have an instance of `Error` object, say `someError`, then this string will be shown if you call `someError.localizedDescription`
	public var errorDescription: String? {
		switch self {
			case .setupBlocker(let s), .other(let s):
				return s
				
			case .setupError(let err), .coreDataError(let err):
				return err.localizedDescription
		}
	}

	///	Outputs `debugDescription` which should include all possible information needed to debug the issue.
	public var failureReason: String? {
		return debugDescription
	}
}
