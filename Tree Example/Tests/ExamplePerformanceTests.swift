//
//  Tree_ExampleTests.swift
//  Tree ExampleTests
//
//  Created by  Jeffrey Hurray on 9/13/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import XCTest
@testable import Tree_Example
import Ladybug

class ExamplePerformanceTests: XCTestCase {
    
    var jsonData: Data!
    
    override func setUp() {
        super.setUp()
        jsonData = treeJSON.data(using: .utf8)!
    }
    
    func loop(_ times: Int, block: () -> ()) {
        (0...times).forEach {_ in block()}
    }
    
    func testCodableDecodingPerformance() {
        
        self.measure {
            loop(100) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy"
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted(dateFormatter)
                _ = try! decoder.decode(Tree_Codable.self, from: jsonData)
            }
        }
    }
    
    func testCodableEncodingPerformance() {
        
        let _dateFormatter = DateFormatter()
        _dateFormatter.dateFormat = "MM-dd-yyyy"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(_dateFormatter)
        let tree = try! decoder.decode(Tree_Codable.self, from: jsonData)
        self.measure {
            loop(100) {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM-dd-yyyy"
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .formatted(dateFormatter)
                _ = try! encoder.encode(tree)
            }
        }
    }
    
    func testJSONCodableDecodingPerformance() {
        
        self.measure {
            loop(100) {
                _ = try! Tree_JSONCodable(data: jsonData)
            }
        }
    }
    
    func testJSONCodableEncodingPerformance() {
        
        let tree = try! Tree_JSONCodable(data: jsonData)
        self.measure {
            loop(100) {
                _ = try! tree.toData()
            }
        }
    }
    
}
