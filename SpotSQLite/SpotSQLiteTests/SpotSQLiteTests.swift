//
//  SpotSQLiteTests.swift
//  SpotSQLiteTests
//
//  Created by Shawn Clovie on 17/8/2019.
//  Copyright © 2019 Spotlit.club. All rights reserved.
//

import XCTest
@testable import SpotSQLite

class SpotSQLiteTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

	
	func testSQLite() {
		let timeStart = Date().timeIntervalSince1970
		var timeInsert: TimeInterval = 0
		let path = URL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!)
			.appendingPathComponent("test.db").path
		let db = try! SQLiteDB(path: path)
		do {
			defer {
				print(db.lastErrorMessage ?? "done")
			}
			try db.prepare("DROP TABLE test").execute()
			try db.prepare("CREATE TABLE IF NOT EXISTS test (id INT NOT NULL,name TEXT NOT NULL,i64 INT NOT NULL,r REAL NOT NULL)")
				.execute()
			let stmtInsert = try db.prepare("INSERT INTO test (id,name,i64,r) VALUES(?,?,?,?)")
			let base: Int64 = 894879898139627520
			for i in 0..<10 {
				try stmtInsert.execute([i, "\(arc4random())", base + Int64(i), Float(i) / 10 + Float(base)])
			}
			timeInsert = Date().timeIntervalSince1970 - timeStart
			
			let stmt = try db.prepare("SELECT id,name,i64,r FROM test WHERE id>?")
				.query([0])
			while stmt.next() {
				print("id=\(stmt.value(of: "id")!), name=\(stmt.value(of: "name")!), i64=\(stmt.value(of: "i64")!), r=\(stmt.value(of: "r")!)")
			}
			let id3Name = try db.prepare("SELECT name FROM test WHERE id=?")
				.queryScalar([3])
			print("id3Name=", id3Name ?? -1)
		} catch {
			print(error, db.lastPreparedSQL)
		}
		print("\ntotal cost(s):", Date().timeIntervalSince1970 - timeStart, "\ninsert cost(s):", timeInsert)
	}
}