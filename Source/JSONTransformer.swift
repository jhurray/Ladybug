//
//  JSONTransformer.swift
//  Ladybug iOS
//
//  Created by Jeff Hurray on 7/31/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

/// A protocol that facilitates transforming of JSON objects. Used by objects conforming to JSONCodable
public protocol JSONTransformer {
    
    /// Key path that points to the JSON value that is being mapped.
    /// If `nil` the keypath is assumed to be the `propertyKey` passed to the `transform` method.
    var keyPath: JSONKeyPath? { get }
    
    // Alters a JSON object to prepare for decoding
    func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey)
    
    // Alters a JSON object to prepare for encoding
    func reverseTransform(_ json: inout [String: Any], mappingFrom propertyKey: PropertyKey)
}

/// Maps a JSON value at this key path to a `Codable` property of an object conforming to `JSONCodable`
extension JSONKeyPath: JSONTransformer {
    
    public var keyPath: JSONKeyPath? {
        return self
    }
    
    public func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey) {
        if let value = json[jsonKeyPath: self] {
            json[propertyKey] = value
        }
    }
}

/// `String` can act as a `JSONKeyPath`
extension String: JSONTransformer {
    
    public var keyPath: JSONKeyPath? {
        return JSONKeyPath(self)
    }
    
    public func transform(_ json: inout [String : Any], mappingTo propertyKey: PropertyKey) {
        keyPath?.transform(&json, mappingTo: propertyKey)
    }
    
    public func reverseTransform(_ json: inout [String: Any], mappingFrom propertyKey: PropertyKey) {
        keyPath?.reverseTransform(&json, mappingFrom: propertyKey)
    }
}

/// Supplies a default value for a given property. Can be used for Migrations and API changes.
public struct Default: JSONTransformer {
    
    public var keyPath: JSONKeyPath? { return nil }
    private let value: Any
    private let override: Bool
    
    /**
     Supplies a default value for a given property
     
     - Parameter value: The default value that will be assigned to the property
     - Parameter override: If a value exists at the mapped-to `propertyKey` and override == true, the existing value will be replaced with value supplied
     */
    init(value: Any, override: Bool = false) {
        self.value = value
        self.override = override
    }
    
    public func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey) {
        guard json[propertyKey] == nil || override else {
            return
        }
        json[propertyKey] = value
    }
}

/// Used to map JSON values to a Codable property of type `MappedToType`
public struct Map<MappedToType: Codable>: JSONTransformer {
    
    public let keyPath: JSONKeyPath?
    private let map: (Any?) -> MappedToType?
    
    /**
     Used to map JSON values to a Codable property of type `MappedToType`
     
     - Parameter map: A closure that transforms the JSON value to a value of type `MappedToType`
     */
    public init(map: @escaping (Any?) -> MappedToType?) {
        self.keyPath = nil
        self.map = map
    }
    
    /**
     Used to map JSON values to a Codable property of type `MappedToType`
     
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     - Parameter map: A closure that transforms the JSON value to a value of type `MappedToType`
     */
    public init(keyPath: JSONKeyPath, map: @escaping (Any?) -> MappedToType?) {
        self.keyPath = keyPath
        self.map = map
    }
    
    public func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey) {
        let keyPath = resolvedKeyPath(propertyKey)
        if let mappedValue = map(json[jsonKeyPath: keyPath]) {
            json[propertyKey] = mappedValue
        }
    }
}

/// Maps a JSON object to a type conforming to JSONCodable
internal struct NestedObjectTransformer<Type: JSONCodable>: JSONTransformer {
    
    public let keyPath: JSONKeyPath?
    
    /**
     Maps the JSON value at the given key path to the given property of type `Type`
     
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     */
    public init(keyPath: JSONKeyPath? = nil) {
        self.keyPath = keyPath
    }
    
    private func alterNestedJSON(_ json: inout [String: Any], propertyKey: PropertyKey, alteration: (inout [String: Any]) -> ()) {
        let keyPath = resolvedKeyPath(propertyKey)
        guard var nestedJSON = json[jsonKeyPath: keyPath] as? [String: Any] else {
            return
        }
        alteration(&nestedJSON)
        json[propertyKey] = nestedJSON
    }
    
    public func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey) {
        alterNestedJSON(&json, propertyKey: propertyKey, alteration: Type.alterForDecoding)
    }
    
    public func reverseTransform(_ json: inout [String : Any], mappingFrom propertyKey: PropertyKey) {
        alterNestedJSON(&json, propertyKey: propertyKey, alteration: Type.alterForEncoding)
    }
}

/// Maps a JSON array to an array of a type conforming to JSONCodable
internal struct NestedListTransformer<Type: JSONCodable>: JSONTransformer {
    
    public let keyPath: JSONKeyPath?
    
    /**
     Maps the JSON value at the given key path to the given property of type `[Type]`
     
     - Parameter keyPath: Key path that points to the JSON array that is being mapped
     */
    public init(keyPath: JSONKeyPath? = nil) {
        self.keyPath = keyPath
    }
    
    private func alterNestedJSON(_ json: inout [String: Any], propertyKey: PropertyKey, alteration: (inout [String: Any]) -> ()) {
        let keyPath = resolvedKeyPath(propertyKey)
        guard let nestedJSONList = json[jsonKeyPath: keyPath] as? [[String: Any]] else {
            return
        }
        var alteredJSONList: [[String: Any]] = []
        for var nestedJSON in nestedJSONList {
            alteration(&nestedJSON)
            alteredJSONList.append(nestedJSON)
        }
        json[propertyKey] = alteredJSONList
    }
    
    public func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey) {
        alterNestedJSON(&json, propertyKey: propertyKey, alteration: Type.alterForDecoding)
    }
    
    public func reverseTransform(_ json: inout [String : Any], mappingFrom propertyKey: PropertyKey) {
        alterNestedJSON(&json, propertyKey: propertyKey, alteration: Type.alterForEncoding)
    }
}

internal struct CompositeTransformer: JSONTransformer {
    
    let transformers: [JSONTransformer]
    
    init(transformers: JSONTransformer...) {
        self.transformers = transformers
    }
    
    public var keyPath: JSONKeyPath? {
        return nil
    }
    
    func transform(_ json: inout [String : Any], mappingTo propertyKey: PropertyKey) {
        transformers.forEach {
            $0.transform(&json, mappingTo: propertyKey)
        }
    }
    
    func reverseTransform(_ json: inout [String : Any], mappingFrom propertyKey: PropertyKey) {
        transformers.forEach {
            $0.reverseTransform(&json, mappingFrom: propertyKey)
        }
    }
}

internal extension JSONTransformer {
    
    internal func resolvedKeyPath(_ propertyKey: PropertyKey) -> JSONKeyPath {
        return keyPath ?? JSONKeyPath(propertyKey)
    }
}

public extension JSONTransformer {
    
    func reverseTransform(_ json: inout [String: Any], mappingFrom propertyKey: PropertyKey) {
        // Default Implementation - Override point
    }
}
