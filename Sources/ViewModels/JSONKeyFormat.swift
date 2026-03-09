//
//  JSONKeyFormat.swift
//  ViewModels
//
//  Created by Andrew Childs on 2025/12/08.
//

import Foundation

// Analogue of ViewModelFormat, but from String, not Parser

public protocol JSONKeyFormat<Value> {
  associatedtype Value
  func deserialize(from string: String) throws -> Value
  func serialize(value: Value) throws -> String
}

public struct UUIDKeyFormat: JSONKeyFormat {
  public typealias Value = UUID

  public func deserialize(from string: String) throws -> Value {
    guard let value = UUID(uuidString: string) else {
      throw DeserializeError.loadError
    }

    return value
  }

  public func serialize(value: UUID) throws -> String {
    value.uuidString
  }
}
