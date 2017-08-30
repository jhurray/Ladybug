//
//  Operators.swift
//  Ladybug iOS
//
//  Created by Jeff Hurray on 8/29/17.
//  Copyright © 2017 jhurray. All rights reserved.
//

import Foundation

infix operator <- : AdditionPrecedence 

public func <- (lhs: JSONTransformer, rhs: JSONTransformer) -> JSONTransformer {
    return CompositeTransformer(transformers: lhs, rhs)
}
