//
//  LadybugTests.swift
//  Ladybug Tests
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import XCTest
@testable import Ladybug

class LadybugTests: XCTestCase {
    
    var json: [String: Any]!
    
    override func setUp() {
        super.setUp()
        let data = Person.jsonString.data(using: .utf8)
        XCTAssertNotNil(data)
        json = (try? JSONSerialization.jsonObject(with: data!, options: [])) as? [String: Any]
        XCTAssertNotNil(json)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testInit() {
        do {
            let person = try Person(json: json)
            let pet = person.pet
            XCTAssertNotNil(pet)
        } catch let error {
            XCTFail("Unsuccesful initialization: \(error)")
        }
    }
    
}
