//
//  ViewModelEmitter.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

public class ViewModelEmitter {
  // TODO: consider SwiftyJSON, or other json builders
  public enum Value {
    case none
    case object(_: [String: AnyEncodable?])
    case array(_: [AnyEncodable?])
    case single(_: AnyEncodable?)
  }

  public init() {}

  private(set) var value: Value = .none

  // Single methods

  public func setNil() {
    switch value {
    case .none:
      value = .single(nil)
    default:
      fatalError("Attempt to set nil in non-empty emitter")
    }
  }

  public func set(_ value: Encodable?) {
    switch self.value {
    case .none:
      self.value = .single(value.map { AnyEncodable(value: $0) })
    default:
      fatalError("Attempt to set value in non-empty emitter")
    }
  }

  // Object methods
  public func setObject() {
    switch value {
    case .none:
      value = .object([:])
    case .object:
      break
    default:
      fatalError("Attempt to set object in non-object emitter")
    }
  }

  public func set(_ value: Encodable, forKey key: String) {
    set(erasedValue: AnyEncodable(value: value), forKey: key)
  }

  public func set(_ emitter: ViewModelEmitter, forKey key: String) {
    set(erasedValue: emitter.toValue(), forKey: key)
  }

  public func setNil(forKey key: String) {
    set(erasedValue: nil, forKey: key)
  }

  public func emit(
    forKey key: String,
    body: (ViewModelEmitter) throws -> Void
  ) rethrows {
    let subemitter = ViewModelEmitter()
    try body(subemitter)
    set(subemitter, forKey: key)
  }

  private func set(erasedValue value: AnyEncodable?, forKey key: String) {
    switch self.value {
    case .none:
      self.value = .object([key: value])

    case var .object(o):
      o[key] = value
      self.value = .object(o)

    default:
      fatalError("Attempt to set object in non-object emitter")
    }
  }

  // Collection methods

  public func setArray() {
    switch value {
    case .none:
      value = .array([])
    case .array:
      break
    default:
      fatalError("Attempt to set object in non-object emitter")
    }
  }

  public func append(_ value: Encodable) {
    append(erasedValue: AnyEncodable(value: value))
  }

  public func append(_ emitter: ViewModelEmitter) {
    append(erasedValue: emitter.toValue())
  }

  private func append(erasedValue value: AnyEncodable?) {
    switch self.value {
    case .none:
      self.value = .array([value])

    case var .array(a):
      a.append(value)
      self.value = .array(a)

    default:
      fatalError("Attempt to set object in non-object emitter")
    }
  }

  // Elimination methods

  public func toValue() -> AnyEncodable {
    switch value {
    case .none:
      fatalError("To value of empty emitter")
    case let .object(o):
      return AnyEncodable(value: o)
    case let .array(a):
      return AnyEncodable(value: a)
    case let .single(a):
      return AnyEncodable(value: a)
    }
  }
}
