//
//  ViewModelParser-Instances.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation

extension String: ViewModelParserCodable {
  public static func deserialize(from parser: ViewModelParser) throws -> String {
    try parser.unbox(type: self)
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.set(self)
  }
}

extension Int: ViewModelParserCodable {
  public static func deserialize(from parser: ViewModelParser) throws -> Self {
    try parser.unbox(type: self)
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.set(self)
  }
}

extension Bool: ViewModelParserCodable {
  public static func deserialize(from parser: ViewModelParser) throws -> Self {
    try parser.unbox(type: self)
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.set(self)
  }
}

extension Double: ViewModelParserCodable {
  public static func deserialize(from parser: ViewModelParser) throws -> Self {
    try parser.unbox(type: self)
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.set(self)
  }
}

extension Date: ViewModelParserCodable {
  public static func deserialize(from parser: ViewModelParser) throws -> Date {
    let stringValue = try parser.unbox(type: String.self)
    let dateFormatter = ISO8601DateFormatter()
    guard let date = dateFormatter.date(from: stringValue) else {
      throw DeserializeError.loadError
    }
    return date
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.set(ISO8601DateFormatter().string(from: self))
  }
}

extension URL: ViewModelParserCodable {
  public static func deserialize(from parser: ViewModelParser) throws -> Self {
    let stringValue = try parser.unbox(type: String.self)
    guard let url = URL(string: stringValue) else {
      throw DeserializeError.loadError
    }
    return url
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.set(absoluteString)
  }
}

extension UUID: ViewModelParserCodable {
  public static func deserialize(from parser: ViewModelParser) throws -> Self {
    let stringValue = try parser.unbox(type: String.self)
    guard let uuid = UUID(uuidString: stringValue) else {
      throw DeserializeError.loadError
    }
    return uuid
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.set(uuidString.lowercased())
  }
}

// A protocol to add trivial conformances for RawRepresentable types
public protocol ViewModelParserRawCodable: RawRepresentable, ViewModelParserCodable
  where RawValue: ViewModelParserCodable
{}

// Implement ViewModelParserCodable for ViewModelParserRawCodable
public extension ViewModelParserRawCodable {
  static func deserialize(from parser: ViewModelParser) throws -> Self {
    let value = try RawValue.deserialize(from: parser)
    guard let val = Self(rawValue: value) else {
      throw DeserializeError.loadError
    }
    return val
  }

  func serialize(to emitter: ViewModelEmitter) throws {
    try rawValue.serialize(to: emitter)
  }
}
