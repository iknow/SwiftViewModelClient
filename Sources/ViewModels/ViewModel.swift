import Foundation
import SwiftUI

public protocol AnyViewModel: AnyObject, ViewModelSerializable, ViewModelDeserializable, ViewModelVersions {
  static var typeName: String { get }
  static var version: Int { get }

  static func deserialize(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> Self

  func serialize(
    to emitter: ViewModelEmitter,
    in context: SerializeContext
  ) throws
}

public extension AnyViewModel {
  // Convenience wrapper, call via User.deserialize(json: responseBody)
  static func deserialize(from json: Data) throws -> Self {
    try ViewModel.deserialize(json: json, type: self)
  }

  // Convenience wrapper, call via User.deserialize(jsonObject: responseObject)
  static func deserialize(from parser: ViewModelParser) throws -> Self {
    try ViewModel.deserialize(parser: parser, type: self)
  }
}

open class ViewModel: AnyViewModel, AssociationValue {
  open class var typeName: String { fatalError("ViewModel subtype did not override typeName") }
  open class var version: Int { 1 }

  // Sometimes we only have the instance, it's useful to be able to
  // look at type properties. Doing the same for `version` is
  // reasonable, but is too generic and conflicts with attributes.
  public var typeName: String { Self.typeName }

  // Convenience wrapper, call via ViewModel.deserialize(json: responseData, type: [User].self), handles arrays
  public static func deserialize<T: ViewModelDeserializable>(json: Data, type: T.Type) throws -> T {
    try SIMDJSONParser.with(data: json) { parser in
      try ViewModel.deserialize(parser: parser, type: type)
    }
  }

  // Convenience wrapper, call via ViewModel.deserialize(parser: responseParser, type: [User].self), handles arrays
  public static func deserialize<T: ViewModelDeserializable>(parser: ViewModelParser, type: T.Type) throws -> T {
    let data = try parser.descend(into: "data")
    let references = try parser.maybeDescend(into: "references")

    let deserializeContext = DeserializeContext(references: references)

    return try T.deserialize(from: data, in: deserializeContext)
  }

  struct EncodeBody: Encodable {
    let data: AnyEncodable?
    let references: AnyEncodable?
  }

  #if DEBUG
  open class func warnOnMigration() {
    fatalError("abstract method called")
  }
  #endif

  open class func deserialize(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> Self {
    try Self(from: parser, in: context)
  }

  public static func serialize(_ value: some ViewModelSerializable) throws -> Data {
    let serializeContext = SerializeContext()
    let dataEmitter = ViewModelEmitter()

    try value.serialize(to: dataEmitter, in: serializeContext)
    let references = serializeContext.references

    let encoder = JSONEncoder()
    return try encoder.encode(
      EncodeBody(
        data: dataEmitter.toValue(),
        references: AnyEncodable(value: references)
      )
    )
  }

  // Convenience wrapper, call via user.serialize()
  public func serialize() throws -> Data {
    try ViewModel.serialize(self)
  }

  public required convenience init(from parser: ViewModelParser, in context: DeserializeContext) throws {
    self.init(defaultValues: false)
    try deserialize(from: parser, in: context)
  }

  public init(defaultValues: Bool) {
    if defaultValues {
      initDefaults()
    }
  }

  public convenience init() {
    self.init(defaultValues: true)
  }

  open func initDefaults() {}

  open func deserialize(from parser: ViewModelParser, in context: DeserializeContext) throws {
    let typeName = try parser.fetch(key: "_type", type: String.self)
    if typeName != Self.typeName {
      throw DeserializeError.invalidType(expected: Self.typeName, actual: typeName)
    }

    let version = try parser.fetch(key: "_version", type: Int.self)
    if version != Self.version {
      throw DeserializeError.invalidVersion(typeName: Self.typeName, expected: Self.version, actual: version)
    }

    #if DEBUG
    if let migrated = try parser.maybeFetch(key: "_migrated", type: Bool.self), migrated {
      Self.warnOnMigration()
    }
    #endif
  }

  open func serialize(to emitter: ViewModelEmitter, in context: SerializeContext) throws {
    emitter.set(Self.typeName, forKey: "_type")
    emitter.set(Self.version, forKey: "_version")
  }

  open func saved() {}

  open func saved(_ other: ViewModel) {}

  open func discardChanges() {}

  open func _walkChildren(_ visitor: (ViewModel) -> Bool) {}

  public func walk(_ visitor: (ViewModel) -> Bool) {
    if visitor(self) {
      _walkChildren(visitor)
    }
  }

  open class func nestedVersions(into versionMap: inout [String: Int]) {
    versionMap[typeName] = version
  }

  open class func deserializeAssociated(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> Self {
    try deserialize(from: parser, in: context)
  }

  open func serializeAssociated(
    to emitter: ViewModelEmitter,
    in context: SerializeContext
  ) throws {
    try serialize(to: emitter, in: context)
  }
}

public protocol JSONID {
  associatedtype JsonType
  func jsonId() -> JsonType
}

extension UUID: JSONID {
  public typealias JsonType = String
  public func jsonId() -> String {
    uuidString.lowercased()
  }
}
