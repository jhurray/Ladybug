//
//  JSONTransformer.swift
//  Ladybug iOS
//
//  Created by Jeff Hurray on 7/31/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

public protocol JSONTransformer {
    
    var propertyName: String { get }
    var keyPath: JSONKeyPath { get }
    
    func transform(_ json: inout [String: Any])
}

public struct JSONKeyPathTransformer: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    
    public func transform(_ json: inout [String: Any]) {
        json[propertyName] = json[jsonKeyPath: keyPath]
    }
}

public struct JSONDefaultValueTransformer: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    private let value: Any
    private let override: Bool
    
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

public struct JSONNestedObjectTransformer<Type: JSONCodable>: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    
    public init(propertyName: String) {
        let keyPath = JSONKeyPath(propertyName)
        self.init(propertyName: propertyName, keyPath: keyPath)
    }
    
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

public struct JSONNestedListTransformer<Type: JSONCodable>: JSONTransformer {
    
    public let propertyName: String
    public let keyPath: JSONKeyPath
    
    public init(propertyName: String) {
        let keyPath = JSONKeyPath(propertyName)
        self.init(propertyName: propertyName, keyPath: keyPath)
    }
    
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

public struct JSONDateTransformer: JSONTransformer {
    
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
    
    public init(propertyName: String, dateFormat: DateFormat) {
        let keyPath = JSONKeyPath(propertyName)
        self.init(propertyName: propertyName, keyPath: keyPath, dateFormat: dateFormat)
    }
    
    public init(propertyName: String, keyPath: JSONKeyPath, dateFormat: DateFormat) {
        self.propertyName = propertyName
        self.keyPath = keyPath
        self.dateFormat = dateFormat
        self.customAdapter = nil
    }
    
    public init(propertyName: String, customAdapter: @escaping (Any?) -> Date?) {
        let keyPath = JSONKeyPath(propertyName)
        self.init(propertyName: propertyName, keyPath: keyPath, customAdapter: customAdapter)
    }
    
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
