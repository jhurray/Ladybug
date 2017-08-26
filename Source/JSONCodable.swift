//
//  JSONCodable.swift
//  Ladybug
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

/// A typealias of string. In future versions may be `AnyKeyPath`.
public typealias PropertyKey = String

/// A protocol that provides Codable conformance and supports initialization from JSON and JSON Data
public protocol JSONCodable: Codable {
    
    /**
     Initialize an object with JSON Data
     
     - Parameter data: JSON Data that will be serialized and mapped to the conforming object
     */
    init(data: Data) throws
    
    /**
     Initialize an object with a JSON object
     
     - Parameter json: JSON object that will be mapped to the conforming object
     */
    init(json: Any) throws
    
    /// Supplies an array of transformers used to map JSON values to properties of the conforming object
    static var transformersByPropertyKey: [PropertyKey: JSONTransformer] { get }
}

/// Exception type thrown by objects conforming to JSONCodable
public enum JSONCodableError: Swift.Error {
    /// Thrown when an object conforming to JSONCodable expects a certain type, but receives another
    case badType(expectedType: Any.Type, receivedType: Any.Type)
}

public extension Array where Element: JSONCodable {
    
    /**
     Initialize an array of objects conforming to JSONCodable with JSON Data
     
     - Parameter data: JSON Data that will be serialized and mapped to the list of objects conforming to JSONCodable
     */
    init(data: Data) throws {
        let json = try JSONSerialization.jsonObject(with: data)
        try self.init(json: json)
    }
    
    /**
     Initialize an array of objects conforming to JSONCodable with a JSON object
     
     - Parameter json: JSON object that will mapped to the list of objects conforming to JSONCodable
     */
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
    
    init(data: Data) throws {
        let json = try JSONSerialization.jsonObject(with: data)
        try self.init(json: json)
    }
    
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
        for (propertyKey, transformer) in Self.transformersByPropertyKey {
            transformer.transform(&json, mappingTo: propertyKey)
        }
        let reflection = Mirror(reflecting: self)
        reflection.children.forEach { (label, value) in
            guard let propertyKey = label else { return }
            let keyPath = JSONKeyPath(propertyKey)
            if let jsonCodableValue = value as? JSONCodable {
                guard var nestedJSON = json[jsonKeyPath: keyPath] as? [String: Any] else {
                    return
                }
                type(of: jsonCodableValue).alter(&nestedJSON)
                json[propertyKey] = nestedJSON
            }
            if let jsonCodableValue = value as? Array<JSONCodable>.Element {
                guard let nestedJSONList = json[jsonKeyPath: keyPath] as? [[String: Any]] else {
                    return
                }
                var alteredJSONList: [[String: Any]] = []
                alteredJSONList.reserveCapacity(nestedJSONList.count)
                for var json in nestedJSONList {
                    type(of: jsonCodableValue).alter(&json)
                    alteredJSONList.append(json)
                }
                json[propertyKey] = alteredJSONList 
            }
        }
    }
    
    public static var transformersByPropertyKey: [PropertyKey: JSONTransformer] {
        return [:]
    }
}
