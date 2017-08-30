//
//  DateFormat.swift
//  Ladybug iOS
//
//  Created by Jeff Hurray on 8/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

/**
 Used to transform raw JSON values to Date objects.
 An enumerated type used to determine which format JSON dates are in. Can be used as a JSONTransformer.
 * secondsSince1970
 * millisecondsSince1970
 * iso8601
 * custom(format: String)
 */
public enum DateFormat: Hashable, JSONTransformer {
    /// Decode the `Date` as a UNIX timestamp from a JSON number.
    case secondsSince1970
    /// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
    case millisecondsSince1970
    /// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
    case iso8601
    /// Decode the `Date` with a custom date format string
    case format(String)
    /// Return a `Date` from the JSON value
    /// If the return value is nil and it is being mapped to
    /// a non-optional `Date` property an Exception will be thrown
    case custom((Any?) -> Date?)
    
    public static func == (lhs: DateFormat, rhs: DateFormat) -> Bool {
        switch (lhs, rhs) {
        case (.secondsSince1970, .secondsSince1970),
             (.millisecondsSince1970, .millisecondsSince1970),
             (.iso8601, .iso8601):
            return true
        case (.format(let lhsFormat), .format(let rhsFormat)):
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
        case .format(let format):
            return format.hashValue
        case .custom(_):
            return ".custom(_:)".hashValue
        }
    }
    
    public var keyPath: JSONKeyPath? {
        return nil
    }
    
    public func transform(_ json: inout [String : Any], mappingTo propertyKey: PropertyKey) {
        let keyPath = resolvedKeyPath(propertyKey)
        
        switch self {
        case .custom(let adapter):
            guard let date = adapter(json[jsonKeyPath: keyPath]) else {
                // If `date` is nil and the property being transformed is explicitly non-optional
                // JSONDecoder will throw an error and initialization will fail
                return
            }
            let dateFormatter = DateFormat.millisecondsSince1970.dateFormatter
            json[propertyKey] = Int(dateFormatter.string(from: date))
            return
        default:
            break
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
        guard self != .millisecondsSince1970 else {
            json[propertyKey] = Int(dateString)
            return
        }
        if let millisecondsSince1970String = DateFormatAdapter.shared.convert(dateString, fromFormat: self, toFormat: .millisecondsSince1970) {
            json[propertyKey] = Int(millisecondsSince1970String)
        }
    }
}

/// Decode the `Date` as a UNIX timestamp from a JSON number.
public let secondsSince1970 = DateFormat.secondsSince1970
/// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
public let millisecondsSince1970 = DateFormat.millisecondsSince1970
/// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
public let iso8601 = DateFormat.iso8601
/// Decode the `Date` with a custom date format string
public func format(_ format: String) -> DateFormat { return DateFormat.format(format) }
/// Return a `Date` from the JSON value
/// If the return value is nil and it is being mapped to
/// a non-optional `Date` property an Exception will be thrown
public func custom(_ adapter: @escaping (Any?) -> Date?) -> DateFormat { return DateFormat.custom(adapter) }
// Assign the current date to the `Date` property
public let currentDate = DateFormat.custom { _ in return Date() }

