//
//  KeyPathRepresentable.swift
//  Ladybug
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

public protocol JSONKeyPathProtocol {}

internal protocol _JSONKeyPathProtocol: JSONKeyPathProtocol {
    
    var isEmpty: Bool { get }
    
    /// Strips off the first segment and returns a pair
    /// consisting of the first segment and the remaining key path.
    /// Returns nil if the key path has no segments.
    func headAndTail() -> (head: String, tail: _JSONKeyPathProtocol)?
}

public struct JSONKeyPath: JSONKeyPathProtocol {
    
    private var segments: [String]
    
    public init(keys: String...) {
        self.init(segments: keys)
    }
    
    public init(keyPath: String) {
        segments = keyPath.components(separatedBy: ".")
    }
}

extension JSONKeyPath: _JSONKeyPathProtocol {
    
    internal var isEmpty: Bool {
        return segments.isEmpty
    }
    
    internal func headAndTail() -> (head: String, tail: _JSONKeyPathProtocol)? {
        guard !isEmpty else {
            return nil
        }
        var tail = segments
        let head = tail.removeFirst()
        return (head, JSONKeyPath(segments: tail))
    }
    
    private init(segments: [String]) {
        self.segments = segments
    }
}

public struct JSONDateKeyPath: JSONKeyPathProtocol {
    
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
    
    private let keyPath: JSONKeyPath
    internal let dateFormat: DateFormat
    internal let customAdapter: ((Any?) -> Date)?
    
    init(keyPath: JSONKeyPath, dateFormat: DateFormat) {
        self.keyPath = keyPath
        self.dateFormat = dateFormat
        self.customAdapter = nil
    }
    
    init(keyPath: JSONKeyPath, customAdapter: @escaping (Any?) -> Date) {
        self.keyPath = keyPath
        self.dateFormat = .secondsSince1970
        self.customAdapter = customAdapter
    }
}

extension JSONDateKeyPath: _JSONKeyPathProtocol {
    
    internal var isEmpty: Bool {
        return keyPath.isEmpty
    }
    
    internal func headAndTail() -> (head: String, tail: _JSONKeyPathProtocol)? {
        return keyPath.headAndTail()
    }
}

internal extension Dictionary where Key: StringProtocol {
    
    subscript(jsonKeyPath keyPath: _JSONKeyPathProtocol) -> Any? {
        get {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return nil
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                guard let key = Key(head) else {
                    return nil
                }
                return self[key]
            case let (head, remainingKeyPath)?:
                // Key path has a tail we need to traverse.
                guard let key = Key(head) else {
                    return nil
                }
                switch self[key] {
                case let nestedDict as [Key: Any]:
                    // Next nest level is a dictionary.
                    // Start over with remaining key path.
                    return nestedDict[jsonKeyPath: remainingKeyPath]
                default:
                    // Next nest level isn't a dictionary.
                    // Invalid key path, abort.
                    return nil
                }
            }
        }
        set {
            switch keyPath.headAndTail() {
            case nil:
                // key path is empty.
                return
            case let (head, remainingKeyPath)? where remainingKeyPath.isEmpty:
                // Reached the end of the key path.
                guard let key = Key(head) else {
                    return
                }
                self[key] = newValue as? Value
            case let (head, remainingKeyPath)?:
                guard let key = Key(head) else {
                    return
                }
                let value = self[key]
                switch value {
                case var nestedDict as [Key: Any]:
                    // Key path has a tail we need to traverse
                    nestedDict[jsonKeyPath: remainingKeyPath] = newValue
                    self[key] = nestedDict as? Value
                default:
                    // Invalid keyPath
                    return
                }
            }
        }
    }
}
