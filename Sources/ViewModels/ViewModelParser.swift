import Foundation

public enum ParserError: Error, Equatable {
  case noValue(key: String, location: String?)
  case error(description: String, location: String?)
}

public protocol ViewModelParser {
  static func with<T>(data: Data, body: (ViewModelParser) throws -> T) throws -> T

  // Primitives
  func unbox(type: String.Type) throws -> String
  func unbox(type: Int.Type) throws -> Int
  func unbox(type: Double.Type) throws -> Double
  func unbox(type: Bool.Type) throws -> Bool
  var isNull: Bool { get }

  // Arrays
  func parseArray<T>(of: T.Type, parse: (Self) throws -> T) throws -> [T]

  // Objects
  func descend(into key: String) throws -> Self
  func maybeDescend(into key: String) throws -> Self?
  func enumerateObject(parse: (String, Self) throws -> Void) throws
}

public extension ViewModelParser {
  func fetch(key: String, type: String.Type) throws -> String {
    try descend(into: key).unbox(type: String.self)
  }

  func fetch(key: String, type: Int.Type) throws -> Int {
    try descend(into: key).unbox(type: Int.self)
  }

  func fetch(key: String, type: Double.Type) throws -> Double {
    try descend(into: key).unbox(type: Double.self)
  }

  func fetch(key: String, type: Bool.Type) throws -> Bool {
    try descend(into: key).unbox(type: Bool.self)
  }

  func maybeFetch(key: String, type: String.Type) throws -> String? {
    guard let child = try maybeDescend(into: key), !child.isNull else { return nil }
    return try child.unbox(type: String.self)
  }

  func maybeFetch(key: String, type: Int.Type) throws -> Int? {
    guard let child = try maybeDescend(into: key), !child.isNull else { return nil }
    return try child.unbox(type: Int.self)
  }

  func maybeFetch(key: String, type: Double.Type) throws -> Double? {
    guard let child = try maybeDescend(into: key), !child.isNull else { return nil }
    return try child.unbox(type: Double.self)
  }

  func maybeFetch(key: String, type: Bool.Type) throws -> Bool? {
    guard let child = try maybeDescend(into: key), !child.isNull else { return nil }
    return try child.unbox(type: Bool.self)
  }

  func parseDictionary<T>(of: T.Type = T.self, parse: (Self) throws -> T) throws -> [String: T] {
    var result: [String: T] = [:]
    try enumerateObject { key, subparser in
      try result[key] = parse(subparser)
    }
    return result
  }
}

/// A type that can be trivially read from a ViewModelParser, like Decodeable
public protocol ViewModelParserDecodable {
  static func deserialize(from parser: ViewModelParser) throws -> Self
}

/// A type that can be trivially emitteed from a ViewModelEmitter, like Codable
public protocol ViewModelParserEncodable {
  func serialize(to emitter: ViewModelEmitter) throws
}

/// A type that can be decoded and encoded by ViewModel
public typealias ViewModelParserCodable = ViewModelParserDecodable & ViewModelParserEncodable

extension Optional: ViewModelParserCodable where Wrapped: ViewModelParserCodable {
  public static func deserialize(from parser: any ViewModelParser) throws -> Self {
    if !parser.isNull {
      try Wrapped.deserialize(from: parser)
    } else {
      nil
    }
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    if let self {
      try self.serialize(to: emitter)
    } else {
      emitter.setNil()
    }
  }
}

extension Array: ViewModelParserCodable where Element: ViewModelParserCodable {
  public static func deserialize(from parser: any ViewModelParser) throws -> Self {
    try parser.parseArray(of: Element.self) {
      try Element.deserialize(from: $0)
    }
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    emitter.setArray()
    for element in self {
      let subemitter = ViewModelEmitter()
      try element.serialize(to: subemitter)
      emitter.append(subemitter)
    }
  }
}
