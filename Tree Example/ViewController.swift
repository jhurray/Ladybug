//
//  ViewController.swift
//  Tree Example
//
//  Created by  Jeffrey Hurray on 9/13/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var jsonData: Data!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        jsonData = treeJSON.data(using: .utf8)!
        createCodableTree()
        createJSONCodableTree()
    }
    
    func createCodableTree() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        let tree = try! decoder.decode(Tree_Codable.self, from: jsonData)
        
        print(tree)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(dateFormatter)
        let data = try! encoder.encode(tree)
        
        print(data)
        
        let treeAgain = try! decoder.decode(Tree_Codable.self, from: data)
        
        print(treeAgain)
    }
    
    func encodeCodableTree() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        
    }
    
    func createJSONCodableTree() {
        let tree = try! Tree_JSONCodable(data: jsonData)
        
        print(tree)
        
        let data = try! tree.toData()
        
        print(data)
                
        let treeAgain = try! Tree_JSONCodable(data: data)
        
        print(treeAgain)
    }
}

