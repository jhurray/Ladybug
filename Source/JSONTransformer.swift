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
    
    /// The string representation of the property to which the JSON value is being mapped
    var propertyName: String { get }
    /// Key path that points to the JSON value that is being mapped
    var keyPath: JSONKeyPath { get }
    
    // Alters a JSON object to prepare for decoding
    func transform(_ json: inout [String: Any])
}

/// Maps a JSON value at a given key path to a property of an object conforming to JSONCodoable
public struct KeyPathTransformer: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    
    public init(propertyName: String, keyPath: JSONKeyPath) {
        self.propertyName = propertyName
        self.keyPath = keyPath
    }
    
    public func transform(_ json: inout [String: Any]) {
        json[propertyName] = json[jsonKeyPath: keyPath]
    }
}

/// Supplies a default value for a given property. Can be used for Migrations and API changes.
public struct DefaultValueTransformer: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    private let value: Any
    private let override: Bool
    
    /**
     Supplies a default value for a given property
     
     - Parameter propertyName: The string representation of the property to which the json value is being mapped
     - Parameter value: The default value that will be assigned to the property
     - Parameter override: If a value exists at the `propertyName` key and override == true, the existing value will be replaced with value supplied
     */
    init(propertyName: String, value: Any, override: Bool = false) {
        self.propertyName = propertyName
        self.keyPath = JSONKeyPath(propertyName)
        self.value = value
        self.override = override
    }
    
    public func transform(_ json: inout [String: Any]) {
        guard json[propertyName] == nil || override else {
            return
        }
        json[propertyName] = value
    }
}

/// Maps a JSON object to a type conforming to JSONCodable
public struct NestedObjectTransformer<Type: JSONCodable>: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    
    /**
     Maps the nested type to the given property of type `Type`
     
     - Parameter propertyName: the string representation of the property to which the json value is being mapped
     */
    public init(propertyName: String) {
        let keyPath = JSONKeyPath(propertyName)
        self.init(propertyName: propertyName, keyPath: keyPath)
    }
    
    /**
     Maps the JSON value at the given key path to the given property of type `Type`
     
     - Parameter propertyName: The string representation of the property to which the json value is being mapped
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     */
    public init(propertyName: String, keyPath: JSONKeyPath) {
        self.propertyName = propertyName
        self.keyPath = keyPath
    }

    public func transform(_ json: inout [String: Any]) {
        guard var nestedJSON = json[jsonKeyPath: keyPath] as? [String: Any] else {
            return
        }
        Type.alter(&nestedJSON)
        json[propertyName] = nestedJSON
    }
}

/// Maps a JSON array to an array of a type conforming to JSONCodable
public struct NestedListTransformer<Type: JSONCodable>: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    
    /**
     Maps an array to the given property of type `[Type]`
     
     - Parameter propertyName: the string representation of the property to which the json array is being mapped
     */
    public init(propertyName: String) {
        let keyPath = JSONKeyPath(propertyName)
        self.init(propertyName: propertyName, keyPath: keyPath)
    }
    
    /**
     Maps the JSON value at the given key path to the given property of type `[Type]`
     
     - Parameter propertyName: The string representation of the property to which the json array is being mapped
     - Parameter keyPath: Key path that points to the JSON array that is being mapped
     */
    public init(propertyName: String, keyPath: JSONKeyPath) {
        self.propertyName = propertyName
        self.keyPath = keyPath
    }
    
    public func transform(_ json: inout [String: Any]) {
        guard let nestedJSONList = json[jsonKeyPath: keyPath] as? [[String: Any]] else {
            return
        }
        var alteredJSONList: [[String: Any]] = []
        for var nestedJSON in nestedJSONList {
            Type.alter(&nestedJSON)
            alteredJSONList.append(nestedJSON)
        }
        json[propertyName] = alteredJSONList
    }
}

/// Used to map JSON values to a Codable property of type `MappedToType`
public struct MapTransformer<MappedToType: Codable>: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    private let map: (Any?) -> MappedToType?
    
    /**
     Used to map JSON values to a Codable property of type `MappedToType`
     
     - Parameter propertyName: The string representation of the property to which the JSON value is being mapped
     - Parameter map: A closure that transforms the JSON value to a value of type `MappedToType`
     */
    public init(propertyName: String, map: @escaping (Any?) -> MappedToType?) {
        self.init(propertyName: propertyName, keyPath: JSONKeyPath(propertyName), map: map)
    }
    
    /**
     Used to map JSON values to a Codable property of type `MappedToType`
     
     - Parameter propertyName: The string representation of the property to which the JSON value is being mapped
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     - Parameter map: A closure that transforms the JSON value to a value of type `MappedToType`
     */
    public init(propertyName: String, keyPath: JSONKeyPath, map: @escaping (Any?) -> MappedToType?) {
        self.propertyName = propertyName
        self.keyPath = keyPath
        self.map = map
    }
    
    public func transform(_ json: inout [String: Any]) {
        if let mappedValue = map(json[jsonKeyPath: keyPath]) {
            json[propertyName] = mappedValue
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
    public enum DateFormat: Hashable {
        /// Decode the `Date` as a UNIX timestamp from a JSON number.
        case secondsSince1970
        /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
        case millisecondsSince1970
        /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
        /// Decode the `Date` with a custom date format string
        case custom(format: String)
        
        public static func == (lhs: DateFormat, rhs: DateFormat) -> Bool {
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
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    private let dateFormat: DateFormat
    private let customAdapter: ((Any?) -> Date?)?
    
    /**
     Used to transform raw JSON values in the given format to Date object
     
     - Parameter propertyName: The string representation of the property to which the json value is being mapped
     - Parameter dateFormat: The expected format of the raw JSON value
     */
    public init(propertyName: String, dateFormat: DateFormat) {
        let keyPath = JSONKeyPath(propertyName)
        self.init(propertyName: propertyName, keyPath: keyPath, dateFormat: dateFormat)
    }
    
    /**
     Used to transform raw JSON values in the given format to Date object
     
     - Parameter propertyName: The string representation of the property to which the json value is being mapped
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     - Parameter dateFormat: The expected format of the raw JSON value
     */
    public init(propertyName: String, keyPath: JSONKeyPath, dateFormat: DateFormat) {
        self.propertyName = propertyName
        self.keyPath = keyPath
        self.dateFormat = dateFormat
        self.customAdapter = nil
    }
    
    /**
     Used to transform raw JSON values in the given format to Date object
     
     - Parameter propertyName: The string representation of the property to which the json value is being mapped
     - Parameter customAdapter: A closure that is passed the raw JSON value and returns a `Date` object
     */
    public init(propertyName: String, customAdapter: @escaping (Any?) -> Date?) {
        let keyPath = JSONKeyPath(propertyName)
        self.init(propertyName: propertyName, keyPath: keyPath, customAdapter: customAdapter)
    }
    
    /**
     Used to transform raw JSON values in the given format to Date object
     
     - Parameter propertyName: The string representation of the property to which the json value is being mapped
     - Parameter keyPath: Key path that points to the JSON value that is being mapped
     - Parameter customAdapter: A closure that is passed the raw JSON value and returns a `Date` object
     */
    public init(propertyName: String, keyPath: JSONKeyPath, customAdapter: @escaping (Any?) -> Date?) {
        self.propertyName = propertyName
        self.keyPath = keyPath
        self.dateFormat = .secondsSince1970
        self.customAdapter = customAdapter
    }
    
    public func transform(_ json: inout [String : Any]) {
        if let customAdapter = customAdapter {
            guard let date = customAdapter(json[jsonKeyPath: keyPath]) else {
                // If `date` is nil and the property being transformed is explicitly non-optional
                // JSONDecoder will throw an error and initialization will fail
                return
            }
            let dateFormatter = DateFormat.millisecondsSince1970.dateFormatter
            json[propertyName] = Int(dateFormatter.string(from: date))
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
        guard dateFormat != .millisecondsSince1970 else {
            json[propertyName] = Int(dateString)
            return
        }
        if let millisecondsSince1970String = DateFormatAdapter.shared.convert(dateString, fromFormat: dateFormat, toFormat: .millisecondsSince1970) {
            json[propertyName] = Int(millisecondsSince1970String)
        }
    }
}
