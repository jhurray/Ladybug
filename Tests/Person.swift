//
//  Person.swift
//  Ladybug Tests
//
//  Created by Jeff Hurray on 7/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation
@testable import Ladybug

struct Pet: JSONCodable {
    
    static let jsonString: String = """
    {
    "pet_kind": "dog",
    "name": "agnes"
    }
    """
    
    static var keyPathsByJSONKeyPaths: [String : JSONKeyPathProtocol] = [
        "kind": JSONKeyPath(keyPath: "pet_kind"),
        "createdAt": JSONDateKeyPath(keyPath: JSONKeyPath(keyPath: "createdAt"), customAdapter: { (_) -> Date in
            return Date()
        }),
    ]
    
    enum Kind: String, Codable {
        case dog
        case cat
        case other
    }
    
    let kind: Kind
    let name: String
    let createdAt: Date
}

struct Person: JSONCodable {
    
    static let jsonString: String = """
    {
    "full_name": "Jeff Hurray",
    "age": 24,
    "gender": "male",
    "date_of_birth": "10/25/1992",
    "personalWebsite": "https://google.com",
    "pet_thing": \(Pet.jsonString)
    }
    """
    
    static let petKeyPath = JSONKeyPath(keyPath: "pet_thing")
    
    static let keyPathsByJSONKeyPaths: [String: JSONKeyPathProtocol] = [
        "name": JSONKeyPath(keyPath: "full_name"),
        "pet": petKeyPath,
        "petName": JSONKeyPath(keys: "pet_thing", "name"),
        "birthday": JSONDateKeyPath(keyPath: JSONKeyPath(keyPath: "date_of_birth"), dateFormat: .custom(format: "mm/dd/YYYY")),
    ]
    
    static let nestedTypes: [JSONNestedType] = [
        JSONNestedType(keyPath: petKeyPath , type: Pet.self)
    ]
    
    enum Gender: String, Codable {
        case male
        case female
    }
    
    let name: String
    let age: Int
    let gender: Gender
    let pet: Pet
    let petName: String
    let personalWebsite: URL
    let birthday: Date
}
