//
//  Serialize.swift
//
//
//  Created by Andrew Childs on 2023/07/22.
//

import Foundation

public enum SerializeError: Error, Equatable {
  case valueMissing(typeName: String, name: String)
}

public class SerializeContext {
  // Convenience struct to emit json
  public struct Reference: Codable {
    public let ref: String

    enum CodingKeys: String, CodingKey {
      case ref = "_ref"
    }
  }

  public private(set) var references: [String: AnyEncodable] = [:]
  private var usedReferences: [AnyHashable: Reference] = [:]
  private var nextRefIndex: Int = 0

  public func reference(for view: ViewModelRecord<some Hashable>) throws -> Reference {
    if let ref = usedReferences[view] {
      return ref
    }

    let ref = nextRef()
    references[ref.ref] = try AnyEncodable(value: view.toReference())
    usedReferences[view] = ref

    return ref
  }

  private func nextRef() -> Reference {
    let ref = Reference(ref: String(format: "r:%d", nextRefIndex))
    nextRefIndex += 1
    return ref
  }
}

// TODO: why do I need to define this?
public struct AnyEncodable: Encodable {
  public let value: Encodable

  public func encode(to encoder: Encoder) throws {
    try value.encode(to: encoder)
  }
}

public protocol ViewModelSerializable: ViewModelVersions {
  func serialize(to emitter: ViewModelEmitter, in context: SerializeContext) throws
}

extension ViewModel: ViewModelSerializable {}

extension Array: ViewModelSerializable where Element: ViewModelSerializable {
  public func serialize(to emitter: ViewModelEmitter, in context: SerializeContext) throws {
    emitter.setArray()
    for element in self {
      let subemitter = ViewModelEmitter()
      try element.serialize(to: emitter, in: context)
      emitter.append(subemitter)
    }
  }
}
