//
//  SQLiteValue.swift
//  Spot
//
//  Created by Shawn Clovie on 4/7/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

public struct SQLiteValue {
	
	public let field: SQLiteField
	public let value: Any?
	
	public var string: String? {
		value as? String
	}
	
	public var double: Double? {
		switch value {
		case let v as Double:
			return v
		case let v as Int64:
			return Double(v)
		default:
			return nil
		}
	}
	
	public var integer: Int64? {
		switch value {
		case let v as Int64:
			return v
		case let v as Double:
			return Int64(v)
		default:
			return nil
		}
	}
}
