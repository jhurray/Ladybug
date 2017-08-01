//
//  KeyPathRepresentable.swift
//  Ladybug
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

internal enum JSONSubscriptType {
    case index(Int)
    case key(String)
}

public protocol JSONSubscript {}

internal protocol _JSONSubscript: JSONSubscript {
    
    var subscriptType: JSONSubscriptType { get }
}

extension Int: _JSONSubscript {
    var subscriptType: JSONSubscriptType {
        return .index(self)
    }
}
extension String: _JSONSubscript {
    var subscriptType: JSONSubscriptType {
        return .key(self)
    }
}

public struct JSONKeyPath {
    
    fileprivate var segments: [JSONSubscript]
    
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

internal extension Dictionary where Key: StringProtocol {
    
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
