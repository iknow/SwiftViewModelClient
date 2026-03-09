//
//  Association.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

public protocol AssociationProtocol {
  associatedtype Value

  var name: String { get }

  func initDefault(_ storage: inout AssociationStorage<Self.Value>)
  func deserialize(_ storage: inout AssociationStorage<Self.Value>, instance: ViewModel, from parser: ViewModelParser, in context: DeserializeContext) throws
  func serialize(_ storage: inout AssociationStorage<Self.Value>, instance: ViewModel, to emitter: ViewModelEmitter, in: SerializeContext) throws
  func discardChanges(_ storage: inout AssociationStorage<Self.Value>)
  func nestedVersions(into versionMap: inout [String: Int])
  func saved(_ storage: inout AssociationStorage<Self.Value>, other: AssociationStorage<Self.Value>)
  func walk(_ storage: AssociationStorage<Self.Value>, visitor: (ViewModel) -> Bool)
}

// TODO: this is unexpected.
// The main reason we need savedValue+dirty is for .discardChanges()
// otherwise we could store only "Value" and recurse.
//
// If we get contexts, then this is probably something we can revisit.
public typealias AssociationStorage = AttributeStorage

open class Association<Value: AssociationValue>: AssociationProtocol {
  public var name: String

  public init(
    of: Value.Type,
    name: String
  ) {
    self.name = name
  }

  open func deserialize(_ storage: inout AssociationStorage<Value>, instance: ViewModel, from parser: ViewModelParser, in context: DeserializeContext) throws {
    let valueParser = try parser.descend(into: name)
    storage.value = try Value.deserializeAssociated(from: valueParser, in: context)
    storage.savedValue = storage.value
    storage.dirty = false
  }

  open func serialize(_ storage: inout AssociationStorage<Value>, instance: ViewModel, to emitter: ViewModelEmitter, in context: SerializeContext) throws {
    guard storage.dirty else { return }
    guard let value = storage.value else {
      throw SerializeError.valueMissing(typeName: instance.typeName, name: name)
    }

    let valueEmitter = ViewModelEmitter()
    try value.serializeAssociated(to: valueEmitter, in: context)
    emitter.set(valueEmitter, forKey: name)
  }

  open func initDefault(_ storage: inout AssociationStorage<Value>) {
    if let defaultValue = Value.self as? Default.Type {
      storage.wrappedValue = defaultValue.defaultValue() as! Value
    }
  }

  open func nestedVersions(into versionMap: inout [String: Int]) {
    Value.nestedVersions(into: &versionMap)
  }

  open func discardChanges(_ storage: inout AttributeStorage<Value>) {
    storage.discardChanges()
  }

  open func saved(_ storage: inout AttributeStorage<Value>, other: AttributeStorage<Value>) {
    storage = other
  }

  open func walk(_ storage: AssociationStorage<Value>, visitor: (ViewModel) -> Bool) {
    guard let value = storage.value else { return }
    value.walk(visitor)
  }
}
