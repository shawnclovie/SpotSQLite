//
//  SQLiteStatement.swift
//  Spot
//
//  Created by Shawn Clovie on 10/8/2017.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import Foundation
import SQLite3

extension SQLiteDB {
	
	public static let Null = NullType()
	
	public final class NullType: SQLParameter {
		fileprivate init() {}
	}

	public final class Statement {
		
		private let stmt: OpaquePointer
		private var fieldTypes: [CInt] = []
		private var fieldNames: [String] = []
		private var fieldNameIndex: [String: Int] = [:]

		private lazy var dateFormatter: DateFormatter = {
			let formatter = DateFormatter()
			formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
			return formatter
		}()

		init(stmt: OpaquePointer) {
			self.stmt = stmt
		}
		
		deinit {
			sqlite3_finalize(stmt)
		}
		
		/// Execute statement.
		///
		/// - Parameter parameters: Parameters to replace ? in prepared SQL.
		/// - Throws:
		///   - Prepare parameter issue: count invalid or any parameter prepare failed.
		///   - Execute failed: Call SQLiteDB.lastErrorMessage for detail.
		public func execute(_ parameters: [SQLParameter] = []) throws {
			try prepare(parameters)
			if sqlite3_step(stmt) != SQLITE_DONE {
				throw SQLiteError.executeFailed
			}
		}
		
		public func queryAll(_ parameters: [SQLParameter] = []) throws -> [[AnyHashable: Any]] {
			_ = try query(parameters)
			var items: [[AnyHashable: Any]] = []
			while next() {
				items.append(values())
			}
			return items
		}
		
		/// Query with parameters.
		///
		/// - Parameters:
		///   - parameters: Parameters to replace ? in prepared SQL.
		/// - Returns: QueryResult
		/// - Throws: Prepare parameter issue - count invalid or any parameter prepare failed.
		public func query(_ parameters: [SQLParameter] = []) throws -> Self {
			try prepare(parameters)
			fieldTypes.removeAll()
			fieldNames.removeAll()
			fieldNameIndex.removeAll()
			return self
		}
		
		public func next() -> Bool {
			let success = sqlite3_step(stmt) == SQLITE_ROW
			if success && fieldTypes.isEmpty {
				let count = sqlite3_column_count(stmt)
				for index in 0..<count {
					fieldTypes.append(sqlite3_column_type(stmt, index))
					var name = ""
					if let cName = sqlite3_column_name(stmt, index),
						let str = String(validatingUTF8: cName) {
						name = str
					}
					fieldNames.append(name)
					fieldNameIndex[name] = Int(index)
				}
			}
			return success
		}
		
		public func values() -> [Any] {
			var values = Array<Any>(repeating: Null, count: fieldTypes.count)
			for (index, type) in fieldTypes.enumerated() {
				values[index] = value(atColume: CInt(index), by: type)
			}
			return values
		}
		
		public func values() -> [AnyHashable: Any] {
			var values: [AnyHashable: Any] = [:]
			for (index, type) in fieldTypes.enumerated() {
				values[fieldNames[index]] = value(atColume: CInt(index), by: type)
			}
			return values
		}
		
		public func value(of field: SQLiteField) -> SQLiteValue {
			.init(field: field, value: value(of: field.name))
		}
		
		public func value(of name: String) -> Any? {
			guard let index = fieldNameIndex[name] else {
				return nil
			}
			return value(atColume: CInt(index), by: fieldTypes[index])
		}
		
		public func value(at index: Int) -> Any? {
			guard index < fieldTypes.count else {
				return nil
			}
			return value(atColume: CInt(index), by: fieldTypes[index])
		}
		
		/// Query single value from first row in result.
		public func queryScalar(_ parameters: [SQLParameter] = []) throws -> Any? {
			try prepare(parameters)
			switch sqlite3_step(stmt) {
			case SQLITE_ROW:
				let count = sqlite3_column_count(stmt)
				guard count > 0 else {
					return nil
				}
				return value(atColume: 0, by: sqlite3_column_type(stmt, 0))
			case SQLITE_DONE:
				return nil
			default:
				throw SQLiteError.executeFailed
			}
		}

		/// Prepare SQL statement before executing.
		private func prepare(_ parameters: [SQLParameter]) throws {
			let paramCount = parameters.count
			if sqlite3_bind_parameter_count(stmt) != CInt(paramCount) {
				throw SQLiteError.parameterCountInvalid
			}
			sqlite3_reset(stmt)
			guard paramCount > 0 else {
				return
			}
			var flag: CInt = 0
			// Text & BLOB values passed to a C-API do not work correctly if they are not marked as transient.
			for (index, param) in parameters.enumerated() {
				// Check for data types
				let sqlIndex = CInt(index + 1)
				switch param {
				case let txt as String:
					flag = sqlite3_bind_text(stmt, sqlIndex, txt, -1, Self.transient)
				case let val as Substring:
					flag = sqlite3_bind_text(stmt, sqlIndex, String(val), -1, Self.transient)
				case let data as Data:
					try data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
						guard let addr = bytes.baseAddress else {
							throw SQLiteError.parameterPrepareFailed(index: index)
						}
						flag = sqlite3_bind_blob(stmt, sqlIndex, addr, CInt(data.count), Self.transient)
					}
				case let date as Date:
					let txt = dateFormatter.string(from: date)
					flag = sqlite3_bind_text(stmt, sqlIndex, txt, -1, Self.transient)
				case let val as Bool:
					let num = val ? 1 : 0
					flag = sqlite3_bind_int(stmt, sqlIndex, CInt(num))
				case let val as Double:
					flag = sqlite3_bind_double(stmt, sqlIndex, CDouble(val))
				case let val as Float:
					flag = sqlite3_bind_double(stmt, sqlIndex, CDouble(val))
				case let val as Int:
					flag = sqlite3_bind_int(stmt, sqlIndex, CInt(val))
				case let val as Int64:
					flag = sqlite3_bind_int64(stmt, sqlIndex, val)
				case is NullType:
					flag = sqlite3_bind_null(stmt, sqlIndex)
				default:
					throw SQLiteError.parameterPrepareFailed(index: index)
				}
				// Check for errors
				if flag != SQLITE_OK {
					throw SQLiteError.parameterPrepareFailed(index: index)
				}
			}
		}
		
		private static let transient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
		
		/// Get column value
		///
		/// - Parameters:
		///   - index: The 0-based index of the column
		///   - type: The declared SQLite data type for the column
		/// - Returns: Value for the column if the data is of a recognized SQLite data type, or SQLiteDB.Null.
		private func value(atColume index: CInt, by type: CInt) -> Any {
			if type == SQLITE_INTEGER {
				let val = sqlite3_column_int64(stmt, index)
				return Int64(val)
			}
			if type == SQLITE_FLOAT {
				let val = sqlite3_column_double(stmt, index)
				return Double(val)
			}
			if type == SQLITE_BLOB, let data = sqlite3_column_blob(stmt, index) {
				let size = sqlite3_column_bytes(stmt, index)
				let val = Data(bytes: data, count: Int(size))
				return val
			}
			if type == SQLITE_NULL {
				return Null
			}
			// If nothing works, return a string representation
			return textValue(atColume: index) ?? Null
		}
		
		private func textValue(atColume index: CInt) -> String? {
			if let ptr = UnsafeRawPointer(sqlite3_column_text(stmt, index)) {
				let uptr = ptr.bindMemory(to: CChar.self, capacity: 0)
				return String(validatingUTF8: uptr)
			}
			return nil
		}
	}
}
