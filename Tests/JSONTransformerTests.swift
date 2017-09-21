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
    
    func testTransform<T>(with transformer: JSONTransformer, propertyKey: PropertyKey, expectedValue: T) {
        var jsonDictionary = self.jsonDictionary
        transformer.transform(&jsonDictionary, mappingTo: propertyKey)
        XCTAssertEqual(String(describing: jsonDictionary[propertyKey]!), String(describing: expectedValue))
        XCTAssertEqual(String(describing: jsonDictionary[jsonKeyPath: transformer.keyPath ?? JSONKeyPath(propertyKey)]!), String(describing: expectedValue))
    }
    
    func testTransformDate(with transformer: JSONTransformer, propertyKey: PropertyKey, expectedDate: Date) {
        var jsonDictionary = self.jsonDictionary
        transformer.transform(&jsonDictionary, mappingTo: propertyKey)
        let secondsSince1970 = TimeInterval(jsonDictionary[propertyKey] as! Int / 1000)
        XCTAssertEqual(expectedDate, Date(timeIntervalSince1970: secondsSince1970))
    }
    
    func testKeyPathTransformer() {
        let transformer = JSONKeyPath("key")
        testTransform(with: transformer, propertyKey:"myKey", expectedValue: "value")
    }
    
    func testNestedObjectTransformer() {
        let transformer = NestedObjectTransformer<Dummy>(keyPath: JSONKeyPath("object_key"))
        testTransform(with: transformer, propertyKey:"objectKey", expectedValue: ["hello": "world"])
    }
    
    func testNestedListTransformer() {
        let transformer = NestedListTransformer<Dummy>(keyPath: JSONKeyPath("list_key"))
        let expectedValue = [["name": "john","age": 24], ["name": "jane", "age": 30]]
        testTransform(with: transformer, propertyKey:"listKey", expectedValue: expectedValue)
    }
    
    func testCompositeTransformer() {
        let transformer1 = JSONKeyPath("key")
        let transformer2 = Default(value: 3, override: true)
        let transformer = transformer1 <- transformer2
        testTransform(with: transformer, propertyKey: "myKey", expectedValue: 3)
    }
    
    func testDateTransformer() {
        let transformer = JSONKeyPath("date_key") <- format(formatString)
        let formatter = DateFormatter()
        formatter.dateFormat = formatString
        let date = formatter.date(from: jsonDictionary["date_key"] as! String)
        testTransformDate(with: transformer, propertyKey:"date", expectedDate: date!)
    }
    
    func testCustomDateTransformer() {
        let transformer = JSONKeyPath("date_key") <- custom { object in
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
        testTransformDate(with: transformer, propertyKey:"date", expectedDate: date!)
    }
    
    func testDateFormats() {
        XCTAssertEqual(DateFormat.secondsSince1970, DateFormat.secondsSince1970)
        XCTAssertEqual(DateFormat.millisecondsSince1970, DateFormat.millisecondsSince1970)
        XCTAssertEqual(DateFormat.iso8601, DateFormat.iso8601)
        XCTAssertEqual(DateFormat.format("ok kewl"), DateFormat.format("ok kewl"))
    }
    
    func testDefaultValueTransformer() {
        let value = 78
        let transformer = Default(value: value)
        testTransform(with: transformer, propertyKey:"defaultProperty", expectedValue: value)
    }
    
    func testMapTransformer() {
        let transformer = Map<Int>(keyPath: "map_key", map: { value in
            return Int(value as! String)
        })
        testTransform(with: transformer, propertyKey:"mapKey", expectedValue: 4)
    }
}
