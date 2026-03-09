import Foundation

public protocol AssociationValue: ViewModelVersions {
  static func deserializeAssociated(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> Self

  func serializeAssociated(
    to: ViewModelEmitter,
    in: SerializeContext
  ) throws

  func walk(_ visitor: (ViewModel) -> Bool)
}

// TODO: this really feels like cheating, but also unnecessary.
public protocol AnyViewModelRecord: AnyViewModel, Hashable, Equatable {
  associatedtype ID: Hashable
  associatedtype JsonID

  static var root: Bool { get }

  var id: ID { get set }
  var jsonID: JsonID { get }
  var isNew: Bool { get }

  init(isNew: Bool, defaultValues: Bool)
}

extension ViewModelRecord: AnyViewModelRecord {}

extension Optional: AssociationValue where Wrapped: AssociationValue {
  public static func deserializeAssociated(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> Self {
    if !parser.isNull {
      try Wrapped.deserializeAssociated(from: parser, in: context)
    } else {
      nil
    }
  }

  public func serializeAssociated(
    to emitter: ViewModelEmitter,
    in context: SerializeContext
  ) throws {
    if let self {
      try self.serializeAssociated(to: emitter, in: context)
    } else {
      emitter.setNil()
    }
  }

  public func walk(_ visitor: (ViewModel) -> Bool) {
    guard let self else { return }
    self.walk(visitor)
  }
}

extension Array: AssociationValue where Element: AssociationValue {
  public static func deserializeAssociated(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> [Element] {
    try parser.parseArray(of: Element.self) { elementParser in
      try Element.deserializeAssociated(from: elementParser, in: context)
    }
  }

  public func serializeAssociated(
    to emitter: ViewModelEmitter,
    in context: SerializeContext
  ) throws {
    // TODO: this should diff and fupdate, but not in MVP
    emitter.setArray()
    for element in self {
      let elementEmitter = ViewModelEmitter()
      try element.serializeAssociated(to: elementEmitter, in: context)
      emitter.append(elementEmitter)
    }
  }

  public func walk(_ visitor: (ViewModel) -> Bool) {
    for element in self {
      element.walk(visitor)
    }
  }
}
