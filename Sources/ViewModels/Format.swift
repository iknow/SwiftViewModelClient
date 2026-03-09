//
//  Format.swift
//
//
//  Created by Andrew Childs on 2023/09/01.
//

import Foundation

/// Define a bidirectional serialization for a given type.
///
/// Like ViewModelParserCodable, but external to the type.
///
/// For example, you might want to serialize Dates with or without millisecond precision
/// depending their usage. You may only have one instance of ViewModelParserCodable for Date,
/// so in other cases you'll need to explicitly provide an alternate implementation.
public protocol ViewModelFormat<Value> {
  associatedtype Value
  func deserialize(from parser: ViewModelParser) throws -> Value
  func serialize(value: Value, to emitter: ViewModelEmitter) throws
}

/// Format container that uses the ViewModelParserCodable instance
public struct TrivialFormat<Value>: ViewModelFormat where Value: ViewModelParserCodable {
  public init() {}

  public func deserialize(from parser: ViewModelParser) throws -> Value {
    try Value.deserialize(from: parser)
  }

  public func serialize(value: Value, to emitter: ViewModelEmitter) throws {
    try value.serialize(to: emitter)
  }
}

public struct OptionalFormat<Format: ViewModelFormat>: ViewModelFormat {
  public typealias Value = Format.Value?

  let format: Format

  fileprivate init(of format: Format) {
    self.format = format
  }

  public func deserialize(from parser: ViewModelParser) throws -> Value {
    if !parser.isNull {
      try format.deserialize(from: parser)
    } else {
      nil
    }
  }

  public func serialize(value: Value, to emitter: ViewModelEmitter) throws {
    if let value {
      try format.serialize(value: value, to: emitter)
    } else {
      emitter.setNil()
    }
  }
}

public extension ViewModelFormat {
  func optional() -> OptionalFormat<Self> {
    OptionalFormat(of: self)
  }
}

public struct AccurateTimeFormat: ViewModelFormat {
  public typealias Value = Date

  public init() {}

  public func deserialize(from parser: ViewModelParser) throws -> Value {
    let stringValue = try parser.unbox(type: String.self)
    guard let date = Self.formatter.date(from: stringValue) else {
      throw DeserializeError.loadError
    }
    return date
  }

  public func serialize(value: Value, to emitter: ViewModelEmitter) throws {
    emitter.set(Self.formatter.string(from: value))
  }

  static let formatter: ISO8601DateFormatter = {
    let dateFormatter = ISO8601DateFormatter()
    dateFormatter.formatOptions.insert(.withFractionalSeconds)
    return dateFormatter
  }()
}

public struct DictionaryFormat<
  Key: Hashable,
  Element,
  KeyFormat: JSONKeyFormat<Key>,
  ElementFormat: ViewModelFormat<Element>
>: ViewModelFormat {
  public typealias Value = [Key: Element]

  let keyFormat: KeyFormat
  let elementFormat: ElementFormat

  public init(
    keyFormat: KeyFormat,
    element: Element.Type = Element.self
  ) where ElementFormat == TrivialFormat<Element> {
    self.keyFormat = keyFormat
    elementFormat = ElementFormat()
  }

  public init(
    keyFormat: KeyFormat,
    elementFormat: ElementFormat,
  ) {
    self.keyFormat = keyFormat
    self.elementFormat = elementFormat
  }

  public func deserialize(from parser: any ViewModelParser) throws -> Value {
    var result: Value = [:]
    try parser.enumerateObject { key, subparser in
      try result[keyFormat.deserialize(from: key)] = elementFormat.deserialize(from: subparser)
    }
    return result
  }

  public func serialize(value: Value, to emitter: ViewModels.ViewModelEmitter) throws {
    for (k, v) in value {
      try emitter.emit(forKey: keyFormat.serialize(value: k)) { subemitter in
        try elementFormat.serialize(value: v, to: subemitter)
      }
    }
  }
}
