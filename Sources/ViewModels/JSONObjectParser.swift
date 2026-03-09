import Foundation

// A wrapper around json to make parsing easier
public struct JSONObjectParser: ViewModelParser {
  private enum PathElement: CustomStringConvertible {
    case key(_: String)
    case index(_: Int)

    var description: String {
      switch self {
      case let .key(string): string
      case let .index(int): String(int)
      }
    }
  }

  private let data: Any
  private let path: [PathElement]

  public init(data: Any) {
    self.data = data
    path = []
  }

  private init(data: Any, path: [PathElement]) {
    self.data = data
    self.path = path
  }

  public static func with<T>(
    data: Data,
    body: (any ViewModelParser) throws -> T
  ) throws -> T {
    let json = try JSONSerialization.jsonObject(with: data)
    let parser = Self(data: json, path: [])
    return try body(parser)
  }

  public func unbox(type: String.Type) throws -> String {
    try asType(String.self)
  }

  public func unbox(type: Int.Type) throws -> Int {
    try asType(Int.self)
  }

  public func unbox(type: Double.Type) throws -> Double {
    try asType(Double.self)
  }

  public func unbox(type: Bool.Type) throws -> Bool {
    try asType(Bool.self)
  }

  public var isNull: Bool {
    data is NSNull
  }

  public func parseArray<T>(of: T.Type, parse: (JSONObjectParser) throws -> T) throws -> [T] {
    let value = try asArray()
    return try value.enumerated().map { index, subvalue in
      let subparser = Self(data: subvalue, path: subpath(.index(index)))
      return try parse(subparser)
    }
  }

  public func enumerateObject(parse: (String, JSONObjectParser) throws -> Void) throws {
    for (key, value) in try asObject() {
      try parse(key, .init(data: value))
    }
  }

  public func descend(into key: String) throws -> JSONObjectParser {
    guard let parser = try maybeDescend(into: key) else {
      throw ParserError.noValue(key: key, location: location())
    }
    return parser
  }

  public func maybeDescend(into key: String) throws -> JSONObjectParser? {
    guard let value = try (asObject())[key] else {
      return nil
    }
    return Self(data: value, path: subpath(.key(key)))
  }

  private func asObject() throws -> [String: Any] {
    try asType([String: Any].self)
  }

  private func asArray() throws -> [Any] {
    try asType([Any].self)
  }

  private func location() -> String {
    path.map(\.description).joined(separator: "/")
  }

  private func subpath(_ newElement: PathElement) -> [PathElement] {
    var path = path
    path.append(newElement)
    return path
  }

  private func asType<T>(_ requiredType: T.Type) throws -> T {
    guard let x = data as? T else {
      let expected = String(describing: T.self)
      let actual = String(describing: type(of: data))
      throw ParserError.error(
        description: "Expected \(expected), but got \(actual)",
        location: location()
      )
    }
    return x
  }
}
