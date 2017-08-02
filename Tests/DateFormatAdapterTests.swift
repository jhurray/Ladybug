//
//  DateFormatAdapterTests.swift
//  Ladybug Tests
//
//  Created by Jeff Hurray on 8/1/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import XCTest
@testable import Ladybug

class DateFormatAdapterTests: XCTestCase {
    
    let adapter = DateFormatAdapter.shared
    var timeIntervalString: String!
    
    override func setUp() {
        super.setUp()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let date = dateFormatter.date(from: "10/25/1992")!
        let timeInterval = date.timeIntervalSince1970
        timeIntervalString = String(Int(timeInterval))
    }
    
    override func tearDown() {
        timeIntervalString = nil
        super.tearDown()
    }
    
    func testSecondsSince1970() {
        XCTAssertNotNil(timeIntervalString)
        let convertedDateString = adapter.convert(timeIntervalString, fromFormat: .secondsSince1970, toFormat: .secondsSince1970)
        XCTAssertNotNil(convertedDateString)
        XCTAssertEqual(convertedDateString!, timeIntervalString)
    }
    
    func testMillisecondsSince1970() {
        XCTAssertNotNil(timeIntervalString)
        let convertedDateString = adapter.convert(timeIntervalString, fromFormat: .secondsSince1970, toFormat: .millisecondsSince1970)
        XCTAssertNotNil(convertedDateString)
        XCTAssertEqual(convertedDateString!, "\(timeIntervalString!)000")
    }
    
    func testCustomFormat() {
        XCTAssertNotNil(timeIntervalString)
        let convertedDateString = adapter.convert(timeIntervalString, fromFormat: .secondsSince1970, toFormat: .custom(format: "MMM-dd-yyyy"))
        XCTAssertNotNil(convertedDateString)
        XCTAssertEqual(convertedDateString!, "Oct-25-1992")
    }
    
    //2017-08-02T03:33:19+0000
    func test_iso8601Format() {
        XCTAssertNotNil(timeIntervalString)
        let convertedDateString = adapter.convert(timeIntervalString, fromFormat: .secondsSince1970, toFormat: .iso8601)
        XCTAssertNotNil(convertedDateString)
        XCTAssertEqual(convertedDateString!, "1992-10-25T07:00:00+0000")
    }
}
