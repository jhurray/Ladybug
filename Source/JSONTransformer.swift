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
}

/// Maps a JSON value at this key path to a `Codable` property of an object conforming to `JSONCodable`
extension JSONKeyPath: JSONTransformer {
    
    public var keyPath: JSONKeyPath? {
        return self
    }
    
    public func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey) {
        json[propertyKey] = json[jsonKeyPath: self]
    }
}

/// Supplies a default value for a given property. Can be used for Migrations and API changes.
public struct DefaultValueTransformer: JSONTransformer {
    
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

/// Maps a JSON object to a type conforming to JSONCodable
public struct NestedObjectTransformer<Type: JSONCodable>: JSONTransformer {
    
    public let keyPath: JSONKeyPath?
    
    /**
     Maps the JSON value at the given key path to the given property of type `Type`
     
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     */
    public init(keyPath: JSONKeyPath? = nil) {
        self.keyPath = keyPath
    }

    public func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey) {
        let keyPath = resolvedKeyPath(propertyKey)
        guard var nestedJSON = json[jsonKeyPath: keyPath] as? [String: Any] else {
            return
        }
        Type.alter(&nestedJSON)
        json[propertyKey] = nestedJSON
    }
}

/// Maps a JSON array to an array of a type conforming to JSONCodable
public struct NestedListTransformer<Type: JSONCodable>: JSONTransformer {
    
    public let keyPath: JSONKeyPath?

    /**
     Maps the JSON value at the given key path to the given property of type `[Type]`
     
     - Parameter keyPath: Key path that points to the JSON array that is being mapped
     */
    public init(keyPath: JSONKeyPath? = nil) {
        self.keyPath = keyPath
    }
    
    public func transform(_ json: inout [String: Any], mappingTo propertyKey: PropertyKey) {
        let keyPath = resolvedKeyPath(propertyKey)
        guard let nestedJSONList = json[jsonKeyPath: keyPath] as? [[String: Any]] else {
            return
        }
        var alteredJSONList: [[String: Any]] = []
        for var nestedJSON in nestedJSONList {
            Type.alter(&nestedJSON)
            alteredJSONList.append(nestedJSON)
        }
        json[propertyKey] = alteredJSONList
    }
}

/// Used to map JSON values to a Codable property of type `MappedToType`
public struct MapTransformer<MappedToType: Codable>: JSONTransformer {
    
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

/// Used to transform raw JSON values to Date objects
public struct DateTransformer: JSONTransformer {
    
    /**
     An enumerated type used to determine which format JSON dates are in.
     * secondsSince1970
     * millisecondsSince1970
     * iso8601
     * custom(format: String)
    */
    public enum Format: Hashable {
        /// Decode the `Date` as a UNIX timestamp from a JSON number.
        case secondsSince1970
        /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
        case millisecondsSince1970
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
        /// Decode the `Date` with a custom date format string
        case custom(format: String)
        
        public static func == (lhs: Format, rhs: Format) -> Bool {
            switch (lhs, rhs) {
            case (.secondsSince1970, .secondsSince1970),
                 (.millisecondsSince1970, .millisecondsSince1970),
                 (.iso8601, .iso8601):
                return true
            case (.custom(let lhsFormat), .custom(let rhsFormat)):
                return lhsFormat == rhsFormat
            default:
                return false
            }
        }
        
        public var hashValue: Int {
            switch self {
            case .secondsSince1970:
                return "secondsSince1970".hashValue
            case .millisecondsSince1970:
                return "millisecondsSince1970".hashValue
            case .iso8601:
                return "iso8601".hashValue
            case .custom(let format):
                return format.hashValue
            }
        }
    }
    
    public let keyPath: JSONKeyPath?
    private let format: Format
    private let customAdapter: ((Any?) -> Date?)?
    
    /**
     Used to transform raw JSON values in the given format to Date object
     
     - Parameter dateFormat: The expected format of the raw JSON value
     */
    public init(format: Format) {
        self.keyPath = nil
        self.format = format
        self.customAdapter = nil
    }
    
    /**
     Used to transform raw JSON values in the given format to Date object
     
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     - Parameter dateFormat: The expected format of the raw JSON value
     */
    public init(keyPath: JSONKeyPath, format: Format) {
        self.keyPath = keyPath
        self.format = format
        self.customAdapter = nil
    }
    
    /**
     Used to transform raw JSON values in the given format to Date object
     
     - Parameter customAdapter: A closure that is passed the raw JSON value and returns a `Date` object
     */
    public init(customAdapter: @escaping (Any?) -> Date?) {
        self.keyPath = nil
        self.format = .secondsSince1970
        self.customAdapter = customAdapter
    }
    
    /**
     Used to transform raw JSON values in the given format to Date object
     
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     - Parameter customAdapter: A closure that is passed the raw JSON value and returns a `Date` object
     */
    public init(keyPath: JSONKeyPath, customAdapter: @escaping (Any?) -> Date?) {
        self.keyPath = keyPath
        self.format = .secondsSince1970
        self.customAdapter = customAdapter
    }
    
    public func transform(_ json: inout [String : Any], mappingTo propertyKey: PropertyKey) {
        let keyPath = resolvedKeyPath(propertyKey)
        if let customAdapter = customAdapter {
            guard let date = customAdapter(json[jsonKeyPath: keyPath]) else {
                // If `date` is nil and the property being transformed is explicitly non-optional
                // JSONDecoder will throw an error and initialization will fail
                return
            }
            let dateFormatter = Format.millisecondsSince1970.dateFormatter
            json[propertyKey] = Int(dateFormatter.string(from: date))
            return
        }
        
        let possibleDateString: String?
        switch json[jsonKeyPath: keyPath] {
        case let unformattedDateString as String:
            possibleDateString = unformattedDateString
        case let timestamp as TimeInterval:
            possibleDateString = String(timestamp)
        case let timestamp as Int:
            possibleDateString = String(timestamp)
        default:
            return
        }
        guard let dateString = possibleDateString else {
            return
        }
        guard format != .millisecondsSince1970 else {
            json[propertyKey] = Int(dateString)
            return
        }
        if let millisecondsSince1970String = DateFormatAdapter.shared.convert(dateString, fromFormat: format, toFormat: .millisecondsSince1970) {
            json[propertyKey] = Int(millisecondsSince1970String)
        }
    }
}

fileprivate extension JSONTransformer {
    
    fileprivate func resolvedKeyPath(_ propertyKey: PropertyKey) -> JSONKeyPath {
        return keyPath ?? JSONKeyPath(propertyKey)
    }
}
