//
//  JSONCodable.swift
//  Ladybug
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

public protocol JSONCodable: Codable {
    
    init(json: [String: Any]) throws
    
    static var transformers: [JSONTransformer] { get }
}

public extension Array where Element: JSONCodable {
    
    init(jsonList: [[String: Any]]) throws {
        var list: [Element] = []
        for json in jsonList {
            let object = try Element(json: json)
            list.append(object)
        }
        self = list
    }
}

public extension JSONCodable {
    
    public init(json: [String: Any]) throws {
        var json = json
        Self.alter(&json)
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let instance = try decoder.decode(Self.self, from: jsonData)
        self = instance
    }
    
    internal static func alter(_ json: inout [String: Any]) {
        for transformer in Self.transformers {
            transformer.transform(&json)
        }
    }
    
    public static var transformers: [JSONTransformer] {
        return []
    }
}
