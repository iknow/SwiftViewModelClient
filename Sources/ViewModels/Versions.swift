//
//  Versions.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/10/15.
//

import Foundation

/// Designates a type that may contain versioned viewmodels
///
/// When viewmodels are exchanged with the backend, the versions
/// should be explicitly indicated for migrations.
public protocol ViewModelVersions {
  static func nestedVersions(into versionMap: inout [String: Int])
}

public extension ViewModel {
  static var versionsHeaderName: String { "X-ViewModel-Versions" }
}

public extension ViewModelVersions {
  static func nestedVersions() -> [String: Int] {
    var versionMap: [String: Int] = [:]
    nestedVersions(into: &versionMap)
    return versionMap
  }

  static func versionHeader(forNestedVersions versions: [String: Int]) -> String {
    // This is morally equivalent to a Vary header, and potentially
    // affects caching. Try to have some consistency here.
    let encoder = JSONEncoder()
    encoder.outputFormatting = .sortedKeys
    let versionsHeader = try! encoder.encode(versions)

    return String(decoding: versionsHeader, as: UTF8.self)
  }

  static func versionHeader() -> String {
    versionHeader(forNestedVersions: nestedVersions())
  }
}

extension Array: ViewModelVersions where Element: ViewModelVersions {
  public static func nestedVersions(into versionMap: inout [String: Int]) {
    Element.nestedVersions(into: &versionMap)
  }
}

extension Optional: ViewModelVersions where Wrapped: ViewModelVersions {
  public static func nestedVersions(into versionMap: inout [String: Int]) {
    Wrapped.nestedVersions(into: &versionMap)
  }
}
