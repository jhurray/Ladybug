//
//  DateFormatAdapterTests.swift
//  Ladybug Tests
//
//  Created by Jeff Hurray on 8/1/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import XCTest
@testable import Ladybug

protocol DateFormatAdapterTest {
    
    var fromFormat: DateFormat { get }
    var dateString: String! { get }
    var adapter: DateFormatAdapter { get }
    
    func testSecondsSince1970()
    func testMillisecondsSince1970()
    func testCustomFormat()
    func testISO8601Format()
}

extension DateFormatAdapterTest {
    
    var referenceDate: Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        return dateFormatter.date(from: "10/25/1992")!
    }
    
    func testSecondsSince1970() {
        XCTAssertNotNil(dateString)
        let convertedDateString = adapter.convert(dateString, fromFormat: fromFormat, toFormat: .secondsSince1970)
        XCTAssertNotNil(convertedDateString)
        XCTAssertEqual(convertedDateString!, "\(Int(referenceDate.timeIntervalSince1970))")
    }
    
    func testMillisecondsSince1970() {
        XCTAssertNotNil(dateString)
        let convertedDateString = adapter.convert(dateString, fromFormat: fromFormat, toFormat: .millisecondsSince1970)
        XCTAssertNotNil(convertedDateString)
        XCTAssertEqual(convertedDateString!, "\(Int(referenceDate.timeIntervalSince1970) * 1000)")
    }
    
    func testCustomFormat() {
        XCTAssertNotNil(dateString)
        let convertedDateString = adapter.convert(dateString, fromFormat: fromFormat, toFormat: .format("MMM-dd yy"))
        XCTAssertNotNil(convertedDateString)
        XCTAssertEqual(convertedDateString!, "Oct-25 92")
    }
    
    func testISO8601Format() {
        XCTAssertNotNil(dateString)
        let convertedDateString = adapter.convert(dateString, fromFormat: fromFormat, toFormat: .iso8601)
        XCTAssertNotNil(convertedDateString)
        XCTAssertEqual(convertedDateString!, "1992-10-25T07:00:00+0000")
    }
}

class DateFormatAdapterSecondsSince1970Tests: XCTestCase, DateFormatAdapterTest {
    
    let adapter = DateFormatAdapter.shared
    let fromFormat: DateFormat = .secondsSince1970
    var dateString: String!
    
    override func setUp() {
        super.setUp()
        self.dateString = String(Int(referenceDate.timeIntervalSince1970))
    }
    
    func testAll() {
        testSecondsSince1970()
        testMillisecondsSince1970()
        testCustomFormat()
        testISO8601Format()
    }
}

class DateFormatAdapterMillisecondsSince1970Tests: XCTestCase, DateFormatAdapterTest {
    
    let adapter = DateFormatAdapter.shared
    let fromFormat: DateFormat = .millisecondsSince1970
    var dateString: String!
    
    override func setUp() {
        super.setUp()
        self.dateString = String(Int(referenceDate.timeIntervalSince1970) * 1000)
    }
    
    func testAll() {
        testSecondsSince1970()
        testMillisecondsSince1970()
        testCustomFormat()
        testISO8601Format()
    }
}

class DateFormatAdapterCustomFormatTests: XCTestCase, DateFormatAdapterTest {
    
    let adapter = DateFormatAdapter.shared
    let fromFormat: DateFormat = .format("EEEE, MMM d, yyyy")
    var dateString: String!
    
    override func setUp() {
        super.setUp()
        self.dateString = "Sunday, Oct 25, 1992"
    }
    
    func testAll() {
        testSecondsSince1970()
        testMillisecondsSince1970()
        testCustomFormat()
        testISO8601Format()
    }
}

class DateFormatAdapterISO8601Tests: XCTestCase, DateFormatAdapterTest {
    
    let adapter = DateFormatAdapter.shared
    let fromFormat: DateFormat = .iso8601
    var dateString: String!
    
    override func setUp() {
        super.setUp()
        self.dateString = "1992-10-25T07:00:00+0000"
    }
    
    func testAll() {
        testSecondsSince1970()
        testMillisecondsSince1970()
        testCustomFormat()
        testISO8601Format()
    }
}
