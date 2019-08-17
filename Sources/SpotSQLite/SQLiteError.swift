//
//  SQLiteError.swift
//  Spot
//
//  Created by Shawn Clovie on 7/10/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

public enum SQLiteError: Error {
	case openFailed(message: String)
	case encodingFailed
	case statementPrepareFailed
	case parameterCountInvalid
	case parameterPrepareFailed(index: Int)
	case executeFailed
}
