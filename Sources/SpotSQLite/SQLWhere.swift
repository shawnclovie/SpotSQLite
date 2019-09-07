//
//  SQLWhere.swift
//  
//
//  Created by Shawn Clovie on 7/9/2019.
//

import Foundation

public struct SQLWhere: CustomStringConvertible {
	let statement: String
	
	init(_ s: String) {
		statement = s
	}
	
	init(_ field: SQLiteField, _ op: String, _ value: String) {
		statement = "\(field)\(op)\(value)"
	}
	
	public func not() -> Self {.init("NOT \(statement)")}
	
	public func bracket() -> Self {.init("(\(statement))")}
	
	public var description: String {statement}
}

public func &&(l: SQLWhere, r: SQLWhere) -> SQLWhere {
	.init("\(l.statement) AND \(r.statement)")
}

public func ||(l: SQLWhere, r: SQLWhere) -> SQLWhere {
	.init("\(l.statement) OR \(r.statement)")
}

extension SQLiteField {
	public func eq(_ q: SQLParameter) -> SQLWhere {
		.init(self, "=", q.statement)
	}

	public func neq(_ q: SQLParameter) -> SQLWhere {
		.init(self, "!=", q.statement)
	}

	public func less(_ q: SQLParameter) -> SQLWhere {
		.init(self, "<", q.statement)
	}

	public func great(_ q: SQLParameter) -> SQLWhere {
		.init(self, ">", q.statement)
	}

	/// Make where statement: **{field}** IN (**{multiple placeholder ? as the count}**)
	public func `in`(count: Int) -> SQLWhere {
		.init(self, " IN ", "(\(SQLiteDB.sqlPlaceholder(count: count)))")
	}
	
	/// Make where statement: **{field}** IN (**{embed values}**)
	public func `in`(_ vs: [SQLParameter]) -> SQLWhere {
		let q = vs.map{$0.statement}.joined(separator: ",")
		return .init(self, " IN ", "(\(q))")
	}
}
