//
//  AttributeStorage.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/15.
//

// Note this is a property wrapper for flexibility,
// but viewmodels will often manually instantiate this

@propertyWrapper
public struct AttributeStorage<Value> {
  public var dirty: Bool
  public var savedValue: Value?
  public var value: Value?

  public init() {
    dirty = false
    savedValue = nil
    value = nil
  }

  public init(wrappedValue value: Value) {
    dirty = true
    savedValue = nil
    self.value = value
  }

  public var wrappedValue: Value {
    get {
      guard let value else { fatalError("Read of uninitialized attribute") }
      return value
    }
    set {
      dirty = true
      value = newValue
    }
  }

  public var projectedValue: AttributeStorage<Value> {
    get { self }
    set { self = newValue }
  }

  public mutating func discardChanges() {
    value = savedValue
    dirty = false
  }

  // Notify that we have been saved, so are no longer dirty
  public mutating func saved() {
    savedValue = value
    dirty = false
  }

  // Notify that we've updated the server to a given value,
  // and are no longer dirty
  public mutating func saved(value newValue: Value) {
    savedValue = newValue
    value = newValue
    dirty = false
  }

  public func isUnset() -> Bool {
    value == nil
  }

  public func isSet() -> Bool {
    value != nil
  }

  public func isDirty() -> Bool { dirty }

  public mutating func unset() {
    dirty = true
    value = nil
  }
}
