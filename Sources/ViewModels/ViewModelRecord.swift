//
//  ViewModelRecord.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation

public protocol ViewModelRecordCachedKeypaths: ViewModelParserCodable & Hashable & Default & JSONID {
  static var idKeypath: KeyPath<ViewModelRecord<Self>, Self> { get }
  static var isNewKeypath: KeyPath<ViewModelRecord<Self>, Bool> { get }
}

extension UUID: ViewModelRecordCachedKeypaths {
  public static var idKeypath: KeyPath<ViewModelRecord<Self>, Self> { \.id }
  public static var isNewKeypath: KeyPath<ViewModelRecord<Self>, Bool> { \.isNew }
}

@ObservationRegistrar
open class ViewModelRecord<ID>: ViewModel, Equatable, Hashable, Identifiable, Observable, Default
  where ID: ViewModelParserCodable & Hashable & Default & JSONID & ViewModelRecordCachedKeypaths
{
  open class var root: Bool { false }

  public static func defaultValue() -> Self {
    self.init(isNew: true, defaultValues: true)
  }

  public typealias ID = ID
  public typealias JsonID = ID.JsonType

  public var jsonID: ID.JsonType { id.jsonId() }

  public private(set) var isNew: Bool {
    get {
      access(keyPath: ID.isNewKeypath)
      return _isNew
    }
    set {
      withMutation(keyPath: ID.isNewKeypath) {
        _isNew = newValue
      }
    }
  }

  private var _isNew: Bool

  @VMRIdAttribute
  public var id: ID

  public required convenience init(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws {
    self.init(isNew: false, defaultValues: false)
    try deserialize(from: parser, in: context)
  }

  public required init(isNew: Bool, defaultValues: Bool) {
    _isNew = isNew
    super.init(defaultValues: defaultValues)
  }

  public convenience init() {
    self.init(isNew: true, defaultValues: true)
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(Self.typeName)
    hasher.combine(id)
  }

  public func toReference() throws -> some Encodable {
    guard Self.root else {
      fatalError("Attempt to generate reference to non-root")
    }

    let emitter = ViewModelEmitter()
    emitter.set(Self.typeName, forKey: "_type")

    try emitter.emit(forKey: "id") { try id.serialize(to: $0) }

    return emitter.toValue()
  }

  public static func == (lhs: ViewModelRecord, rhs: ViewModelRecord) -> Bool {
    if lhs.$id.isUnset() || rhs.$id.isUnset() {
      return lhs === rhs
    }
    return lhs.id == rhs.id && lhs.typeName == rhs.typeName
  }

  override open func initDefaults() {
    id = .defaultValue()
  }

  override open func deserialize(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws {
    try super.deserialize(from: parser, in: context)

    let id = try ID.deserialize(from: parser.descend(into: "id"))
    self.$id.value = id
    self.$id.savedValue = id
    self.$id.dirty = false

    isNew = false
  }

  override open class func deserializeAssociated(
    from parser: ViewModelParser,
    in context: DeserializeContext
  ) throws -> Self {
    if root {
      let refKey = try parser.fetch(key: "_ref", type: String.self)
      return try context.fetchReference(key: refKey, type: self)
    } else {
      return try deserialize(from: parser, in: context)
    }
  }

  override open func serialize(
    to emitter: ViewModelEmitter,
    in context: SerializeContext
  ) throws {
    if isNew {
      emitter.set(true, forKey: "_new")
    }

    // New records may be created without explicit ids,
    // all other cases need ids.
    if !(isNew && $id.isUnset()) {
      guard let id = $id.value else {
        throw SerializeError.valueMissing(typeName: typeName, name: "id")
      }

      try emitter.emit(forKey: "id") { try id.serialize(to: $0) }
    }

    try super.serialize(to: emitter, in: context)
  }

  override open func serializeAssociated(
    to emitter: ViewModelEmitter,
    in context: SerializeContext
  ) throws {
    if Self.root {
      let ref = try context.reference(for: self)
      emitter.set(ref)
    } else {
      try serialize(to: emitter, in: context)
    }
  }

  override open func discardChanges() {
    $id.discardChanges()
  }

  override open func saved() {
    super.saved()
    isNew = false
  }

  override open func saved(_ other: ViewModel) {
    super.saved(other)
    guard let other = other as? Self else { fatalError("Mismatched saved call") }
    $id = other._id
    isNew = false
  }
}
