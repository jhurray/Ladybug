//
//  KeyPathRepresentable.swift
//  Ladybug
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

/// Represents a valid type for subscripting JSON objects
public protocol JSONSubscript {}

extension Int: JSONSubscript {}
extension String: JSONSubscript {}

/// Used to subscript JSON objects
public struct JSONKeyPath {
    
    fileprivate var segments: [JSONSubscript]
    
    /**
     Used to subscript JSON objects
     
     - Parameter keys: variadic list of String or Int that represent a JSON key path
     */
    public init(_ keys: JSONSubscript...) {
        var segments: [JSONSubscript] = []
        keys.forEach {
            switch $0 {
            case let index as Int:
                segments.append(index)
            case let string as String:
                string.components(separatedBy: ".").filter { !$0.isEmpty }.forEach {
                    segments.append($0)
                }
            default:
                fatalError("keyPath needs to be of type Int or String")
            }
        }
        self.segments = segments
    }
}

extension JSONKeyPath: ExpressibleByStringLiteral {
    
    public init(stringLiteral value: StaticString) {
        self = JSONKeyPath("\(value)")
    }
}

public extension Dictionary where Key: StringProtocol {
    
    subscript(jsonKeyPath keyPath: JSONKeyPath) -> Any? {
        var value: Any? = self
        for segment in keyPath.segments {
            switch segment {
            case let index as Int:
                guard let list = value as? [Any], index >= 0, index < list.count else {
                    return nil
                }
                value = list[index]
            case let key as String:
                guard let dictionary = value as? [String: Any] else {
                    return nil
                }
                value = dictionary[key]
            default:
                return nil
            }
        }
        return value
    }
}
