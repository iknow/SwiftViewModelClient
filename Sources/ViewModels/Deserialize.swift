import Foundation

public enum DeserializeError: Error {
  case invalidVersion(typeName: String, expected: Int, actual: Int)
  case invalidType(expected: String, actual: String)
  case incoherentRefType
  case missingValue
  case loadError
}

public class DeserializeContext {
  private var rawReferences: ViewModelParser?
  private var parsedReferences: [String: Any] = [:]

  public init(references: ViewModelParser?) {
    rawReferences = references
  }

  public func fetchReference<T: ViewModelDeserializable>(key: String, type: T.Type) throws -> T {
    if let existing = parsedReferences[key] {
      guard let vm = existing as? T else {
        throw DeserializeError.incoherentRefType
      }
      return vm
    } else {
      guard let rawReferences, let subparser = try rawReferences
        .maybeDescend(into: key)
      else {
        throw DeserializeError.missingValue
      }
      let new = try T.deserialize(from: subparser, in: self)
      parsedReferences[key] = new
      return new
    }
  }

  /// Determine the type of an associated value, flattening ref indirection
  /// - Parameter parser: parser focused on an association
  /// - Returns: the value of the "_type" field
  public func associationType(from parser: ViewModelParser) throws -> String {
    if let immediateType = try parser.maybeFetch(key: "_type", type: String.self) {
      return immediateType
    } else if let refHandle = try parser.maybeFetch(key: "_ref", type: String.self) {
      guard let refParser = try rawReferences?.maybeDescend(into: refHandle) else { throw DeserializeError.missingValue }
      return try refParser.fetch(key: "_type", type: String.self)
    } else {
      throw DeserializeError.loadError
    }
  }
}

// Mostly to abstract over viewmodel and collection of viewmodel
public protocol ViewModelDeserializable: ViewModelVersions {
  static func deserialize(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> Self
}

extension ViewModel: ViewModelDeserializable {}

extension Array: ViewModelDeserializable where Element: ViewModelDeserializable {
  public static func deserialize(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> Self {
    try parser.parseArray(of: Element.self) { parser in
      try Element.deserialize(from: parser, in: context)
    }
  }
}
