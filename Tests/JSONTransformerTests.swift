//
//  JSONTransformerTests.swift
//  Ladybug Tests
//
//  Created by Jeff Hurray on 8/9/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import XCTest
@testable import Ladybug

class JSONTransformerTests: XCTestCase {
    
    let jsonDictionary: [String: Any] = [
        "key": "value",
        "list_key": [
            [
                "name": "john",
                "age": 24
            ],
            [
                "name": "jane",
                "age": 30
            ]
        ],
        "object_key": [
            "hello": "world"
        ],
        "date_key": "Sunday, Oct 25, 1992"
    ]
    
    let formatString = "EEEE, MMM d, yyyy"
    
    struct Dummy: JSONCodable {}
    
    func testTransform<T>(with transformer: JSONTransformer, expectedValue: T) {
        var jsonDictionary = self.jsonDictionary
        transformer.transform(&jsonDictionary)
        XCTAssertEqual(String(describing: jsonDictionary[transformer.propertyName]!), String(describing: expectedValue))
        XCTAssertEqual(String(describing: jsonDictionary[jsonKeyPath: transformer.keyPath]!), String(describing: expectedValue))
    }
    
    func testTransformDate(with transformer: JSONDateTransformer, expectedDate: Date) {
        var jsonDictionary = self.jsonDictionary
        transformer.transform(&jsonDictionary)
        let secondsSince1970 = TimeInterval(jsonDictionary[transformer.propertyName] as! Int / 1000)
        XCTAssertEqual(expectedDate, Date(timeIntervalSince1970: secondsSince1970))
    }
    
    func testKeyPathTransformer() {
        let transformer = JSONKeyPathTransformer(propertyName: "myKey", keyPath: JSONKeyPath("key"))
        testTransform(with: transformer, expectedValue: "value")
    }
    
    func testNestedObjectTransformer() {
        let transformer = JSONNestedObjectTransformer<Dummy>(propertyName: "objectKey", keyPath: JSONKeyPath("object_key"))
        testTransform(with: transformer, expectedValue: ["hello": "world"])
    }
    
    func testNestedListTransformer() {
        let transformer = JSONNestedListTransformer<Dummy>(propertyName: "listKey", keyPath: JSONKeyPath("list_key"))
        let expectedValue = [["name": "john","age": 24], ["name": "jane", "age": 30]]
        testTransform(with: transformer, expectedValue: expectedValue)
    }
    
    func testDateTransformer() {
        let format = JSONDateTransformer.DateFormat.custom(format: formatString)
        let transformer = JSONDateTransformer(propertyName: "date", keyPath: JSONKeyPath("date_key"), dateFormat: format)
        let formatter = DateFormatter()
        formatter.dateFormat = formatString
        let date = formatter.date(from: jsonDictionary["date_key"] as! String)
        testTransformDate(with: transformer, expectedDate: date!)
    }
    
    func testCustomDateTransformer() {
        let transformer = JSONDateTransformer(propertyName: "date", keyPath: JSONKeyPath("date_key")) { (object) -> Date? in
            guard let dateString = object as? String else {
                return Date()
            }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d, yyyy"
            let date = formatter.date(from: dateString)!
            return date
        }
        let formatter = DateFormatter()
        formatter.dateFormat = formatString
        let date = formatter.date(from: jsonDictionary["date_key"] as! String)
        testTransformDate(with: transformer, expectedDate: date!)
    }
    
    func testDateFormats() {
        XCTAssertEqual(JSONDateTransformer.DateFormat.secondsSince1970, JSONDateTransformer.DateFormat.secondsSince1970)
        XCTAssertEqual(JSONDateTransformer.DateFormat.millisecondsSince1970, JSONDateTransformer.DateFormat.millisecondsSince1970)
        XCTAssertEqual(JSONDateTransformer.DateFormat.iso8601, JSONDateTransformer.DateFormat.iso8601)
        XCTAssertEqual(JSONDateTransformer.DateFormat.custom(format: "ok kewl"), JSONDateTransformer.DateFormat.custom(format: "ok kewl"))
    }
    
    func testDefaultValueTransformer() {
        let value = 78
        let transformer = JSONDefaultValueTransformer(propertyName: "defaultProperty", value: value)
        testTransform(with: transformer, expectedValue: value)
    }
}
