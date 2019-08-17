//
//  SQLiteTable.swift
//  Spot
//
//  Created by Shawn Clovie on 30/1/2018.
//  Copyright © 2018 Shawn Clovie. All rights reserved.
//

public struct SQLiteTable {
	public let name: String
	public let fields: [SQLiteField]
	public let primaryKeys: [SQLiteField]
	/// key: index name, value: field names
	public let indics: [String: [String]]
	
	public init(_ name: String, _ fields: [SQLiteField], primaryKeys: [SQLiteField], indics: [String: [String]] = [:]) {
		self.name = name
		self.fields = fields
		self.primaryKeys = primaryKeys
		self.indics = indics
	}
	
	public func createQuery(ifNotExist: Bool = false) -> String {
		var ql = "CREATE TABLE"
		if ifNotExist {
			ql += " IF NOT EXISTS"
		}
		ql += " `\(name)`("
		var qlFields: [String] = []
		for field in fields {
			qlFields.append(field.createStatement)
		}
		ql += qlFields.joined(separator: ",")
		if !primaryKeys.isEmpty {
			ql += ",PRIMARY KEY (" +
				primaryKeys.map {"`\($0.name)`"}.joined(separator: ",") + ")"
		}
		for it in indics {
			ql += ",INDEX \(it.key) (`\(it.value.joined(separator: "`,`"))`)"
		}
		ql += ")"
		return ql
	}
	
	public func updateQueryParameters(values: [SQLiteField: SQLParameter], where: [SQLiteField: SQLParameter]) -> (String, [SQLParameter]) {
		var params: [SQLParameter] = []
		var qlValues: [String] = []
		for it in values {
			params.append(it.value)
			qlValues.append("`\(it.key.name)`=?")
		}
		var ql = "UPDATE `\(name)` SET " + qlValues.joined(separator: ",")
		if !`where`.isEmpty {
			var qlWhere: [String] = []
			for it in `where` {
				params.append(it.value)
				qlWhere.append("`\(it.key.name)`=?")
			}
			ql += " WHERE " + qlWhere.joined(separator: " AND ")
		}
		return (ql, params)
	}
	
	public var replaceQuery: String {
		"REPLACE INTO `\(name)` VALUES (" + SQLiteDB.sqlPlaceholder(for: fields) + ")"
	}
	
	public func replaceParameters(values: [SQLiteField: SQLParameter]) -> [SQLParameter] {
		fields.map {values[$0]!}
	}
	
	public func deleteQueryParameters(where: [SQLiteField: SQLParameter]) -> (String, [SQLParameter]) {
		var params: [SQLParameter] = []
		var ql = "DELETE FROM `\(name)`"
		if !`where`.isEmpty {
			var qlWhere: [String] = []
			for it in `where` {
				params.append(it.value)
				qlWhere.append("`\(it.key.name)`=?")
			}
			ql += " WHERE " + qlWhere.joined(separator: " AND ")
		}
		return (ql, params)
	}
}
