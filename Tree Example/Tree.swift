//
//  Tree.swift
//  Tree Example
//
//  Created by  Jeffrey Hurray on 9/13/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation
import Ladybug

let treeJSON: String = """
{
    "tree_names": {
        "colloquial": ["pine", "big green"],
        "scientific": "piniferous scientificus"
    },
    "age": 121,
    "family": 1,
    "planted_at": "7-4-1896",
    "leaves": [
        {
            "size": "large",
            "is_attached": true
        },
        {
            "size": "small",
            "is_attached": false
        }
    ]
}
"""

struct Tree_JSONCodable: JSONCodable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let age: Int
    let plantedAt: Date
    let leaves: [Leaf]
    
    struct Leaf: JSONCodable {
        
        enum Size: String, Codable {
            case small, medium, large
        }
        
        let size: Size
        let isAttached: Bool
        
        static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
            "isAttached": "is_attached"
        ]
    }
    
    static let transformersByPropertyKey: [PropertyKey: JSONTransformer] = [
        "name": JSONKeyPath("tree_names", "colloquial", 0),
        "plantedAt": "planted_at" <- format("MM-dd-yyyy"),
        "leaves": [Leaf].transformer,
    ]
}


struct Tree_Codable: Codable {
    
    enum Family: Int, Codable {
        case deciduous, coniferous
    }
    
    let name: String
    let family: Family
    let age: Int
    let plantedAt: Date
    let leaves: [Leaf]
    
    enum CodingKeys: String, CodingKey {
        case names = "tree_names"
        case family
        case age
        case plantedAt = "planted_at"
        case leaves
    }
    
    enum NameKeys: String, CodingKey {
        case name = "colloquial"
    }
    
    enum LeavesKeys: Int, CodingKey {
        case first = 0
    }
    
    enum DecodingError: Error {
        case emptyColloquialNames
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let namesContainer = try values.nestedContainer(keyedBy: NameKeys.self, forKey: .names)
        let names = try namesContainer.decode([String].self, forKey: .name)
        guard let firstColloquialName = names.first else {
            throw DecodingError.emptyColloquialNames
        }
        name = firstColloquialName
        family = try values.decode(Family.self, forKey: .family)
        age = try values.decode(Int.self, forKey: .age)
        plantedAt = try values.decode(Date.self, forKey: .plantedAt)
        leaves = try values.decode([Leaf].self, forKey: .leaves)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var nameContainer = container.nestedContainer(keyedBy: NameKeys.self, forKey: .names)
        let colloquialNames = [name]
        try nameContainer.encode(colloquialNames, forKey: .name)
        try container.encode(family, forKey: .family)
        try container.encode(age, forKey: .age)
        try container.encode(plantedAt, forKey: .plantedAt)
        try container.encode(leaves, forKey: .leaves)
    }
    
    struct Leaf: Codable {
        
        enum Size: String, Codable {
            case small, medium, large
        }
        
        let size: Size
        let isAttached: Bool
        
        enum CodingKeys: String, CodingKey {
            case isAttached = "is_attached"
            case size
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            size = try values.decode(Size.self, forKey: .size)
            isAttached = try values.decode(Bool.self, forKey: .isAttached)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(size, forKey: .size)
            try container.encode(isAttached, forKey: .isAttached)
        }
    }
}
