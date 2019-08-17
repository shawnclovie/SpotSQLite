//
//  SQLiteField.swift
//  Spot
//
//  Created by Shawn Clovie on 30/1/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

public enum SQLiteType: String {
	case integer, text, real, blob
}

public func ==(l: SQLiteField, r: SQLiteField) -> Bool {
	l.name == r.name
}

public struct SQLiteField: Equatable, Hashable {
	public let name: String
	public let type: SQLiteType
	public let nullable: Bool
	public let defaultValue: Any?
	
	public init(_ name: String, _ type: SQLiteType, nullable: Bool = false, `default`: Any? = nil) {
		self.name = name
		self.type = type
		self.nullable = nullable
		defaultValue = `default`
	}
	
	public var createStatement: String {
		var def = "`\(name)` \(type.rawValue.uppercased())"
		if !nullable {
			def += " NOT NULL"
		}
		if let defVal = defaultValue {
			def += " DEFAULT "
			if defVal is String || defVal is Substring {
				def += "'" + String(describing: defVal).replacingOccurrences(of: "'", with: "\\'") + "'"
			}
		}
		return def
	}
	
	public func hash(into hasher: inout Hasher) {
		name.hash(into: &hasher)
	}
}

extension Sequence where Iterator.Element == SQLiteField {
	public var selectStatementFields: String {
		map {$0.name}.joined(separator: ",")
	}
}
