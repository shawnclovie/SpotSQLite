//
//  SQLParameter.swift
//  Spot
//
//  Created by Shawn Clovie on 1/9/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation

public protocol SQLParameter {
}

extension SQLParameter {
	var statement: String {
		switch self {
		case let it as String:
			return "'\(it.replacingOccurrences(of: "'", with: "\\'"))'"
		case let it as Substring:
			return "'\(it.replacingOccurrences(of: "'", with: "\\'"))'"
		case let it as Data:
			return "'\(String(data: it, encoding: .utf8) ?? "")'"
		case let it as Date:
			let cal = Calendar.current
			let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: it)
			return "'\(comps.year ?? 0)-\(comps.month ?? 0))-\(comps.day ?? 0)) \(comps.hour ?? 0)):\(comps.minute ?? 0)):\(comps.second ?? 0))'"
		case let it as SQLSpecialOperator:
			return it.statement
		default:
			return "\(self)"
		}
	}
}

extension String: SQLParameter {}
extension Substring: SQLParameter {}
extension Data: SQLParameter {}
extension Date: SQLParameter {}
extension Bool: SQLParameter {}
extension Double: SQLParameter {}
extension Float: SQLParameter {}
extension Int: SQLParameter {}
extension Int64: SQLParameter {}

public var SQLPlaceholder: SQLSpecialOperator {.init(statement: "?")}
public var SQLStar: SQLSpecialOperator {.init(statement: "*")}

public struct SQLSpecialOperator: SQLParameter {
	let statement: String
}
