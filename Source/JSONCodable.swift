//
//  JSONCodable.swift
//  Ladybug
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

public protocol JSONCodable: Codable {
    
    init(json: Any) throws
    
    static var transformers: [JSONTransformer] { get }
}

public enum JSONCodableError: Swift.Error {
    case badType(expectedType: Any.Type, receivedType: Any.Type)
}

public extension Array where Element: JSONCodable {
    
    init(json: Any) throws {
        guard let objectList = json as? [Any] else {
            throw JSONCodableError.badType(expectedType: [Any].self, receivedType: type(of: json))
        }
        guard let jsonList = objectList as? [[String: Any]] else {
            throw JSONCodableError.badType(expectedType: [[String: Any]].self, receivedType: type(of: objectList))
        }
        var list: [Element] = []
        for json in jsonList {
            let object = try Element(json: json)
            list.append(object)
        }
        self = list
    }
}

public extension JSONCodable {
    
    public init(json: Any) throws {
        guard var jsonDictionary = json as? [String: Any] else {
            throw JSONCodableError.badType(expectedType: [String: Any].self, receivedType: type(of: json))
        }
        Self.alter(&jsonDictionary)
        let jsonData = try JSONSerialization.data(withJSONObject: jsonDictionary, options: [])
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
