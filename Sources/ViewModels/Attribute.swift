import Foundation

public protocol AttributeProtocol {
  associatedtype Value

  var name: String { get }

  func initDefault(_ storage: inout AttributeStorage<Self.Value>)
  func deserialize(_ storage: inout AttributeStorage<Self.Value>, instance: ViewModel, from parser: ViewModelParser, in context: DeserializeContext) throws
  func serialize(_ storage: inout AttributeStorage<Self.Value>, instance: ViewModel, to emitter: ViewModelEmitter, in context: SerializeContext) throws
  func discardChanges(_ storage: inout AttributeStorage<Self.Value>)
  func saved(_ storage: inout AssociationStorage<Self.Value>, other: AssociationStorage<Self.Value>)
}

open class Attribute<
  Value,
  Format: ViewModelFormat<Value>
>: AttributeProtocol {
  public var name: String

  public init(
    of: Value.Type,
    name: String
  ) where Format == TrivialFormat<Value> {
    newDefaultValue = nil
    format = Format()
    self.name = name
  }

  public init(
    of: Value.Type,
    name: String,
    format: Format
  ) {
    newDefaultValue = nil
    self.format = format
    self.name = name
  }

  public init(
    of: Value.Type,
    name: String,
    default newDefaultValue: @autoclosure @escaping () -> Value
  ) where Format == TrivialFormat<Value> {
    self.newDefaultValue = newDefaultValue
    format = Format()
    self.name = name
  }

  public init(
    of: Value.Type,
    name: String,
    default newDefaultValue: @autoclosure @escaping () -> Value,
    format: Format
  ) {
    self.newDefaultValue = newDefaultValue
    self.format = format
    self.name = name
  }

  public let newDefaultValue: (() -> Value)?
  public let format: Format

  open func deserialize(
    _ storage: inout AttributeStorage<Value>,
    instance: ViewModel,
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws {
    // TODO: actually think about this
    // Can you deserialize onto an existing object graph?
    let valueParser = try parser.descend(into: name)
    let value: Value = try format.deserialize(from: valueParser)
    storage.value = value
    storage.savedValue = storage.value
    storage.dirty = false
  }

  open func serialize(
    _ storage: inout AttributeStorage<Value>,
    instance: ViewModel,
    to emitter: ViewModelEmitter,
    in context: SerializeContext
  ) throws {
    guard storage.dirty else { return }
    guard let value = storage.value else {
      throw SerializeError.valueMissing(typeName: instance.typeName, name: name)
    }

    try emitter.emit(forKey: name) {
      try format.serialize(value: value, to: $0)
    }
  }

  open func initDefault(_ storage: inout AttributeStorage<Value>) {
    if let newDefaultValue {
      storage.wrappedValue = newDefaultValue()
    }
  }

  open func discardChanges(_ storage: inout AttributeStorage<Value>) {
    storage.discardChanges()
  }

  public func saved(_ storage: inout AttributeStorage<Value>, other: AttributeStorage<Value>) {
    storage = other
  }
}
