//
//  SQLiteDB.swift
//  Spot
//
//  Created by Shawn Clovie on 8/10/17.
//  Copyright © 2017 Shawn Clovie. All rights reserved.
//

import SQLite3
import Dispatch

/// Basic SQLite database access wrapper
/// All DB operation should invoke in a sync thread (queue).
public final class SQLiteDB {
	/// - VACUUM - Repack the DB to take advantage of deleted data
	/// - ANALYZE - Gather information about the tables and indices so that the query optimizer can use the information to make queries work better.
	public static let SQLClean = "VACUUM; ANALYZE"
	
	/// Generate placeholder list for SQL, e.g. ?,?,?
	public static func sqlPlaceholder(for arguments: [Any]) -> String {
		sqlPlaceholder(count: arguments.underestimatedCount)
	}
	
	public static func sqlPlaceholder(count: Int) -> String {
		Array<String>(repeating: "?", count: max(0, count))
			.joined(separator: ",")
	}
	
	public private(set) var isInTransaction = false
	public private(set) var lastPreparedSQL = ""
	
	private let db: OpaquePointer
	private let path: String
	private let lock = DispatchSemaphore(value: 1)

	public init(path: String) throws {
		guard let cpath = path.cString(using: .utf8) else {
			throw SQLiteError.encodingFailed
		}
		var db: OpaquePointer?
		let error = sqlite3_open(cpath, &db)
		if error != SQLITE_OK {
			var message = ""
			if let msg = sqlite3_errmsg(db),
				let str = String(validatingUTF8: msg) {
				message = str
			}
			sqlite3_close(db)
			throw SQLiteError.openFailed(message: message)
		}
		self.db = db!
		self.path = path
	}
	
	deinit {
		sqlite3_close(db)
	}
	
	/// Access DB version, default by 0
	public var version: Int {
		get {
			try! prepare("PRAGMA user_version").queryScalar() as? Int ?? 0
		}
		set {
			_ = try! prepare("PRAGMA user_version=\(newValue)").execute()
		}
	}
	
	public var lastErrorCode: Int32 {
		sqlite3_errcode(db)
	}
	
	public var lastErrorMessage: String? {
		let code = sqlite3_errcode(db)
		return code == SQLITE_OK || code == SQLITE_DONE ? nil : String(validatingUTF8: sqlite3_errmsg(db))
	}
	
	public var lastInsertRowID: Int64 {
		Int64(sqlite3_last_insert_rowid(db))
	}
	
	public var lastAffectRowCount: Int32 {
		sqlite3_changes(db)
	}
	
	public func sync<T>(_ operation: () throws -> T) rethrows -> T {
		lock.wait()
		let r = try operation()
		lock.signal()
		return r
	}
	
	/// Prepare SQL Statement
	///
	/// - Parameter sql: SQL Statement
	/// - Returns: Statement object to query (SELECT) or execute (CREATE, INSERT, DELETE, DROP, etc.).
	/// - Throws: Error if SQL format or encoding convert issue.
	public func prepare(_ sql: String) throws -> Statement {
		lastPreparedSQL = sql
		guard let cSql = sql.cString(using: .utf8) else {
			throw SQLiteError.encodingFailed
		}
		var stmt: OpaquePointer?
		let result = sqlite3_prepare_v2(db, cSql, -1, &stmt, nil)
		if result != SQLITE_OK {
			sqlite3_finalize(stmt)
			throw SQLiteError.statementPrepareFailed
		}
		return Statement(stmt: stmt!)
	}
	
	public func beginTransaction(deferred: Bool = false) throws {
		let sql = deferred ? "begin deferred transaction" : "begin exclusive transaction"
		try prepare(sql).execute()
		isInTransaction = true
	}
	
	public func commitTransaction() throws {
		try prepare("commit transaction").execute()
		isInTransaction = false
	}
	
	public func rollbackTransaction() throws {
		try prepare("rollback transaction").execute()
		isInTransaction = false
	}
}
