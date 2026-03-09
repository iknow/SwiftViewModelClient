//
//  CGSize+AttributeProps.swift
//  Eikaiwa
//
//  Created by Andrew Childs on 2023/08/08.
//

import Foundation
import ViewModels

extension CGSize: ViewModelParserCodable {
  public static func deserialize(from parser: ViewModelParser) throws -> CGSize {
    let x = try parser.fetch(key: "x", type: Double.self)
    let y = try parser.fetch(key: "y", type: Double.self)
    return CGSize(width: x, height: y)
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.set(width, forKey: "x")
    emitter.set(height, forKey: "y")
  }
}
