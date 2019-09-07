//
//  SpotSQLiteTests.swift
//  SpotSQLiteTests
//
//  Created by Shawn Clovie on 17/8/2019.
//  Copyright © 2019 Spotlit.club. All rights reserved.
//

import XCTest
@testable import SpotSQLite

private let fieldID = SQLiteField("id", .integer)
private let fieldName = SQLiteField("name", .text)
private let fieldI64 = SQLiteField("i64", .integer)
private let fieldR = SQLiteField("r", .real)

private let tableTest = SQLiteTable("test", [
	fieldID, fieldName, fieldI64, fieldR,
], primaryKeys: [])

class SpotSQLiteTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }
	
	func testSQLWhere() {
		print((fieldName.eq(SQLPlaceholder) && fieldID.neq(SQLPlaceholder)).bracket().not()
			|| fieldI64.eq(340).not()
			|| fieldI64.eq(SQLPlaceholder)
			|| fieldR.in([3.42, 0x5a, "abc", SQLPlaceholder])
			&& fieldID.in(count: 3))
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
			do {
				try db.prepare(tableTest.deleteQuery(where: fieldID.great(SQLPlaceholder))).execute([8])
				print(db.lastPreparedSQL)
				let (ql, args) = tableTest.deleteQueryParameters(where: [fieldID: 6])
				try db.prepare(ql).execute(args)
				print(db.lastPreparedSQL)
			}
			try db.prepare(tableTest.dropQuery(ifExists: true)).execute()
			try db.prepare(tableTest.createQuery(ifNotExist: true)).execute()
			let count = 10
			do {
				let stmt = try db.prepare(tableTest.insertQuery([fieldID, fieldName, fieldI64, fieldR]))
				let base: Int64 = 894879898139627520
				for i in 0..<count {
					try stmt.execute([i, "0\(i)", base + Int64(i), Float(i) / 10 + Float(base)])
				}
			}
			let queryedCount = try db.prepare("SELECT COUNT(*) FROM \(tableTest)").queryScalar() as! Int64
			XCTAssertEqual(queryedCount, Int64(count))
			
			timeInsert = Date().timeIntervalSince1970 - timeStart
			do {
				let (upQL, upArgs) = tableTest.updateQueryParameters(values: [fieldI64: 999], where: (fieldID.eq(SQLPlaceholder), [0]))
				try db.prepare(upQL).execute(upArgs)
				print(db.lastPreparedSQL)
			}
			let stmt = try db.prepare("SELECT \(fieldID),name,i64,r FROM \(tableTest) WHERE \(fieldID.eq(SQLPlaceholder))")
				.query([0])
			while stmt.next() {
				XCTAssertEqual(stmt.value(of: fieldI64).integer, 999)
				XCTAssertEqual(stmt.value(of: fieldID).integer, 0)
				print("id=\(stmt.value(of: "id")!), name=\(stmt.value(of: "name")!), i64=\(stmt.value(of: "i64")!), r=\(stmt.value(of: "r")!)")
			}
			let id3Name = try db.prepare("SELECT \(fieldName) FROM \(tableTest) WHERE \(fieldID.eq(SQLPlaceholder))")
				.queryScalar([3])
			XCTAssertEqual(id3Name as? String, "03")
		} catch {
			XCTFail("lastSQL=\"\(db.lastPreparedSQL)\"\n\(error)\n\(db.lastErrorMessage as Any)")
		}
		print("\ntotal cost(s):", Date().timeIntervalSince1970 - timeStart, "\ninsert cost(s):", timeInsert)
	}
}
