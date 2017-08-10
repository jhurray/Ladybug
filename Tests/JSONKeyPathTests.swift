//
//  JSONKeyPathTests.swift
//  Ladybug Tests
//
//  Created by Jeff Hurray on 8/9/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import XCTest
@testable import Ladybug

class JSONKeyPathTests: XCTestCase {
    
    let jsonString = """
    {
    "start": [
        "harry",
        "potter",
        {
        "foo": 33.3,
        "bar": ["yes", "no", "maybe"],
        "fizz": {
            "type": "algo",
            "values": [1, 3, 5]
            }
        }
        ]
    }
    """
    
    func testKeyPaths() {
        let paths: [JSONKeyPath] = [
        
            JSONKeyPath("start", 2, "fizz.type"),
            JSONKeyPath("start", 2, "fizz", "type"),
            JSONKeyPath("start", 2, "fizz.values"),
            JSONKeyPath("start", 2, "fizz.values", 1),
        ]
        let expectedValues: [Any?] = [
            
            "algo",
            "algo",
            [1, 3, 5],
            3,
        ]

        XCTAssertEqual(paths.count, expectedValues.count)

        do {
            let jsonDictionary = try JSONSerialization.jsonObject(with: jsonString.data(using: .utf8)!) as! [String: Any]
            
            func testListEquality<T: Equatable>(keyPath: JSONKeyPath, expectedValue: Any?, expectedType: [T].Type) {
                guard let typedExpectedValue = expectedValue as? [T] else {
                    XCTFail("Could not convert \(String(describing: expectedValue)) to \(expectedType)")
                    return
                }
                guard let value = jsonDictionary[jsonKeyPath: keyPath] as? [T] else {
                    XCTFail("value at keyPath \(keyPath) was not of type \(expectedType)")
                    return
                }
                XCTAssertEqual(value, typedExpectedValue)
            }
            
            func testEquality<T: Equatable>(keyPath: JSONKeyPath, expectedValue: Any?, expectedType: T.Type) {
                if expectedValue == nil  {
                    guard jsonDictionary[jsonKeyPath: keyPath] == nil else {
                        XCTFail("Expected value at \(keyPath) to be nil")
                        return
                    }
                }
                else {
                    guard let typedExpectedValue = expectedValue as? T else {
                        XCTFail("Could not convert \(String(describing: expectedValue)) to \(expectedType)")
                        return
                    }
                    guard let value = jsonDictionary[jsonKeyPath: keyPath] as? T else {
                        XCTFail("value at keyPath \(keyPath) was not of type \(expectedType)")
                        return
                    }
                    XCTAssertEqual(value, typedExpectedValue)
                }
            }
            
            testEquality(keyPath: JSONKeyPath(1), expectedValue: nil, expectedType: Int.self)
            testEquality(keyPath: JSONKeyPath("invalid"), expectedValue: nil, expectedType: Int.self)
            testEquality(keyPath: JSONKeyPath("start", 1), expectedValue: "potter", expectedType: String.self)
            testEquality(keyPath: JSONKeyPath("start", 2, "foo"), expectedValue: 33.3, expectedType: Double.self)
            testEquality(keyPath: JSONKeyPath("start", 2, "bar", 0), expectedValue: "yes", expectedType: String.self)
            testEquality(keyPath: JSONKeyPath("start", 2, "bar", 2), expectedValue: "maybe", expectedType: String.self)
            testEquality(keyPath: JSONKeyPath("start", 2, "fizz.type"), expectedValue: "algo", expectedType: String.self)
            testEquality(keyPath: JSONKeyPath("start", 2, "fizz", "type"), expectedValue: "algo", expectedType: String.self)
            testListEquality(keyPath: JSONKeyPath("start", 2, "fizz.values"), expectedValue: [1, 3, 5], expectedType: [Int].self)
            testEquality(keyPath: JSONKeyPath("start", 2, "fizz.values", 1), expectedValue: 3, expectedType: Int.self)
            
        }
        catch let error {
            XCTFail("Caught error: \(error)")
        }
    }
}
