//
//  CodableTests.swift
//  Ladybug Tests
//
//  Created by Jeff Hurray on 8/9/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import XCTest
@testable import Ladybug

let leaf1JSON = """
{"size":"small","is_attached":false}
"""

let leaf2JSON = """
{"size":"medium","is_attached":true}
"""

let leaf3JSON = """
{"size":"large","is_attached":true}
"""

let treeJSON = """
{"name":"pine","family":1,"leaves":[\(leaf1JSON),\(leaf2JSON),\(leaf3JSON)]}
"""

struct Tree: JSONCodable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let leaves: [Leaf]
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
        "leaves": NestedListTransformer<Leaf>()
    ]
    
    struct Leaf: JSONCodable {
        
        enum Size: String, Codable {
            case small, medium, large
        }
        
        let size: Size
        let isAttached: Bool
        
        static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
            "isAttached": JSONKeyPath("is_attached"),
        ]
    }
}

extension Tree.Leaf: Equatable {
    static func == (lhs: Tree.Leaf, rhs: Tree.Leaf) -> Bool {
        return lhs.size == rhs.size && lhs.isAttached == rhs.isAttached
    }
}

extension Tree: Equatable {
    
    static func == (lhs: Tree, rhs: Tree) -> Bool {
        return lhs.family == rhs.family && lhs.name == rhs.name && lhs.leaves == rhs.leaves
    }
}

class EncodableTests: XCTestCase {
    
    var tree: Tree!
    
    override func setUp() {
        super.setUp()
        let leaf1 = Tree.Leaf(size: .small, isAttached: false)
        let leaf2 = Tree.Leaf(size: .medium, isAttached: true)
        let leaf3 = Tree.Leaf(size: .large, isAttached: true)
        tree = Tree(name: "pine", family: .coniferous, leaves: [leaf1, leaf2, leaf3])
    }
    
    func testEncodeObject() {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode(tree)
            let jsonObject = try JSONSerialization.jsonObject(with: treeJSON.data(using: .utf8)!)
            let treeFromJSON = try Tree(json: jsonObject)
            let encodedJSONData = try treeFromJSON.toData()
            XCTAssertEqual(encodedData, encodedJSONData)
        }
        catch let error {
            XCTFail("Caught error: \(error)")
        }
    }
    
    func testEncodeList() {
        do {
            let encoder = JSONEncoder()
            let encodedData = try encoder.encode([tree, tree])
            let jsonObject = try JSONSerialization.jsonObject(with: treeJSON.data(using: .utf8)!)
            let treeFromJSON = try Tree(json: jsonObject)
            let encodedJSONData = try [treeFromJSON, treeFromJSON].toData()
            XCTAssertEqual(encodedData, encodedJSONData)
        }
        catch let error {
            XCTFail("Caught error: \(error)")
        }
    }
}

class DecodableTests: XCTestCase {
    
    var tree: Tree!
    
    override func setUp() {
        super.setUp()
        let leaf1 = Tree.Leaf(size: .small, isAttached: false)
        let leaf2 = Tree.Leaf(size: .medium, isAttached: true)
        let leaf3 = Tree.Leaf(size: .large, isAttached: true)
        tree = Tree(name: "pine", family: .coniferous, leaves: [leaf1, leaf2, leaf3])
        
    }
    
    func testDecodeObject() {
        do {
            let encodedData = try! JSONEncoder().encode(tree)
            let decoder = JSONDecoder()
            let decodedTree = try decoder.decode(Tree.self, from: encodedData)
            let jsonObject = try JSONSerialization.jsonObject(with: treeJSON.data(using: .utf8)!)
            let treeFromJSON = try Tree(json: jsonObject)
            XCTAssertEqual(decodedTree, treeFromJSON)
        }
        catch let error {
            XCTFail("Caught error: \(error)")
        }
    }
    
    func testDecodeList() {
        do {
            let encodedData = try! JSONEncoder().encode([tree, tree])
            let decoder = JSONDecoder()
            let decodedTreeList = try decoder.decode([Tree].self, from: encodedData)
            let json = try JSONSerialization.jsonObject(with: "[\(treeJSON), \(treeJSON)]".data(using: .utf8)!)
            let treeListFromJSON = try Array<Tree>(json: json)
            XCTAssertEqual(decodedTreeList, treeListFromJSON)
        }
        catch let error {
            XCTFail("Caught error: \(error)")
        }
    }
}
