//
//  ClassConformanceTests.swift
//  Ladybug Tests
//
//  Created by Jeff Hurray on 8/9/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import XCTest
@testable import Ladybug

class Shirt1: JSONCodable {
    
    static let jsonString: String = """
    {
    "cost": 19.99,
    "size": "large"
    }
    """
    
    enum Size: String, Codable {
        case small, medium, large
    }
    
    var cost: Double = 0
    var size: Size = .small
}

class Shirt2: JSONCodable {
    
    static let jsonString: String = """
    {
    "cost": 19.99,
    "size": "large"
    }
    """
    
    enum Size: String, Codable {
        case small, medium, large
    }
    
    let cost: Double
    let size: Size
    
    init() {
        cost = 0
        size = .small
    }
}

class ClassConformanceTests: XCTestCase {
    
    func testCreationWithVars() {
        let data = Shirt1.jsonString.data(using: .utf8)!
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            let shirt = try Shirt1(json: json)
            XCTAssertEqual(shirt.cost, 19.99)
            XCTAssertEqual(shirt.size, .large)
        }
        catch let error {
            XCTFail("Caught exception: \(error)")
        }
    }
    
    func testCreationWithInit() {
        let data = Shirt2.jsonString.data(using: .utf8)!
        do {
            let json = try JSONSerialization.jsonObject(with: data)
            let shirt = try Shirt2(json: json)
            XCTAssertEqual(shirt.cost, 19.99)
            XCTAssertEqual(shirt.size, .large)
        }
        catch let error {
            XCTFail("Caught exception: \(error)")
        }
    }
}
