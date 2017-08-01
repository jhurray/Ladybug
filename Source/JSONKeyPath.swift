//
//  KeyPathRepresentable.swift
//  Ladybug
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

public struct JSONKeyPath {
    
    private var segments: [String]
    
    public init(keys: String...) {
        self.init(segments: keys)
    }
    
    public init(_ keyPath: String) {
        segments = keyPath.components(separatedBy: ".")
    }
    
    private init(segments: [String]) {
        self.segments = segments
    }
    
    internal var isEmpty: Bool {
        return segments.isEmpty
    }
    
    internal func headAndTail() -> (head: String, tail: JSONKeyPath)? {
        guard !isEmpty else {
            return nil
        }
        var tail = segments
        let head = tail.removeFirst()
        return (head, JSONKeyPath(segments: tail))
    }
}

internal extension Dictionary where Key: StringProtocol {
    
    subscript(jsonKeyPath keyPath: JSONKeyPath) -> Any? {
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
