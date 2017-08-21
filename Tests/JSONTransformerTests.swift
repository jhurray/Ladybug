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
        "date_key": "Sunday, Oct 25, 1992",
        "map_key": "4"
    ]
    
    let formatString = "EEEE, MMM d, yyyy"
    
    struct Dummy: JSONCodable {}
    
    func testTransform<T>(with transformer: JSONTransformer, expectedValue: T) {
        var jsonDictionary = self.jsonDictionary
        transformer.transform(&jsonDictionary)
        XCTAssertEqual(String(describing: jsonDictionary[transformer.propertyName]!), String(describing: expectedValue))
        XCTAssertEqual(String(describing: jsonDictionary[jsonKeyPath: transformer.keyPath]!), String(describing: expectedValue))
    }
    
    func testTransformDate(with transformer: DateTransformer, expectedDate: Date) {
        var jsonDictionary = self.jsonDictionary
        transformer.transform(&jsonDictionary)
        let secondsSince1970 = TimeInterval(jsonDictionary[transformer.propertyName] as! Int / 1000)
        XCTAssertEqual(expectedDate, Date(timeIntervalSince1970: secondsSince1970))
    }
    
    func testKeyPathTransformer() {
        let transformer = KeyPathTransformer(propertyName: "myKey", keyPath: JSONKeyPath("key"))
        testTransform(with: transformer, expectedValue: "value")
    }
    
    func testNestedObjectTransformer() {
        let transformer = NestedObjectTransformer<Dummy>(propertyName: "objectKey", keyPath: JSONKeyPath("object_key"))
        testTransform(with: transformer, expectedValue: ["hello": "world"])
    }
    
    func testNestedListTransformer() {
        let transformer = NestedListTransformer<Dummy>(propertyName: "listKey", keyPath: JSONKeyPath("list_key"))
        let expectedValue = [["name": "john","age": 24], ["name": "jane", "age": 30]]
        testTransform(with: transformer, expectedValue: expectedValue)
    }
    
    func testDateTransformer() {
        let format = DateTransformer.DateFormat.custom(format: formatString)
        let transformer = DateTransformer(propertyName: "date", keyPath: JSONKeyPath("date_key"), dateFormat: format)
        let formatter = DateFormatter()
        formatter.dateFormat = formatString
        let date = formatter.date(from: jsonDictionary["date_key"] as! String)
        testTransformDate(with: transformer, expectedDate: date!)
    }
    
    func testCustomDateTransformer() {
        let transformer = DateTransformer(propertyName: "date", keyPath: JSONKeyPath("date_key")) { (object) -> Date? in
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
        XCTAssertEqual(DateTransformer.DateFormat.secondsSince1970, DateTransformer.DateFormat.secondsSince1970)
        XCTAssertEqual(DateTransformer.DateFormat.millisecondsSince1970, DateTransformer.DateFormat.millisecondsSince1970)
        XCTAssertEqual(DateTransformer.DateFormat.iso8601, DateTransformer.DateFormat.iso8601)
        XCTAssertEqual(DateTransformer.DateFormat.custom(format: "ok kewl"), DateTransformer.DateFormat.custom(format: "ok kewl"))
    }
    
    func testDefaultValueTransformer() {
        let value = 78
        let transformer = DefaultValueTransformer(propertyName: "defaultProperty", value: value)
        testTransform(with: transformer, expectedValue: value)
    }
    
    func testMapTransformer() {
        let transformer = MapTransformer<Int>(propertyName:"mapKey", keyPath: "map_key") { value in
            return Int(value as! String)
        }
        testTransform(with: transformer, expectedValue: 4)
    }
}
