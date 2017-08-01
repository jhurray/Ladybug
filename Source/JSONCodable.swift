//
//  JSONCodable.swift
//  Ladybug
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

public protocol JSONCodable: Codable {
    
    init?(json: [String: Any])
    
    static var keyPathsByJSONKeyPaths: [String: JSONKeyPathProtocol] { get }
    static var nestedTypes: [JSONNestedType] { get }
}

public extension Array where Element: JSONCodable {
    
    init?(jsonList: [[String: Any]]) {
        var list: [Element] = []
        for json in jsonList {
            guard let object = Element(json: json) else {
                return nil
            }
            list.append(object)
        }
        self = list
    }
}

public extension JSONCodable {
    
    public init?(json: [String: Any]) {
        var json = json
        for nestedType in Self.nestedTypes {
            guard let nestedJSON = json[jsonKeyPath: nestedType.keyPath] as? [String: Any] else {
                return nil
            }
            let alteredJSON = nestedType.type.alter(nestedJSON)
            json[jsonKeyPath: nestedType.keyPath] = alteredJSON
        }
        json = Self.alter(json)
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        guard let instance = try? decoder.decode(Self.self, from: jsonData) else {
            return nil
        }
        self = instance
    }
    
    private static func alter(_ json: [String: Any]) -> [String: Any] {
        var json = json
        for mapping in Self.keyPathsByJSONKeyPaths {
            switch mapping.value {
            case let dateKeyPath as JSONDateKeyPath:
                
                if let customAdapter = dateKeyPath.customAdapter {
                    let date = customAdapter(json[jsonKeyPath: dateKeyPath])
                    let dateFormatter = JSONDateKeyPath.DateFormat.millisecondsSince1970.dateFormatter
                    json[mapping.key] = Int(dateFormatter.string(from: date))
                    continue
                }
                
                let possibleDateString: String?
                switch json[jsonKeyPath: dateKeyPath] {
                case let unformattedDateString as String:
                    possibleDateString = unformattedDateString
                case let timestamp as TimeInterval:
                    possibleDateString = String(timestamp)
                case let timestamp as Int:
                    possibleDateString = String(timestamp)
                default:
                    continue
                }
                guard let dateString = possibleDateString else {
                    continue
                }
                guard dateKeyPath.dateFormat != .millisecondsSince1970 else {
                    json[mapping.key] = Int(dateString)
                    continue
                }
                if let millisecondsSince1970String = DateFormatAdapter.shared.convert(dateString, fromFormat: dateKeyPath.dateFormat, toFormat: .millisecondsSince1970) {
                    json[mapping.key] = Int(millisecondsSince1970String)
                }
                
            case let keyPath as JSONKeyPath:
                json[mapping.key] = json[jsonKeyPath: keyPath]
            default:
                break
            }
        }
        return json
    }
    
    public static var nestedTypes: [JSONNestedType] {
        return []
    }
    
    public static var keyPathsByJSONKeyPaths: [String: JSONKeyPathProtocol] {
        return [:]
    }
}
