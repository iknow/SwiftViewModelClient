//
//  AttributeMacro.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/14.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct AttributeMacro: AccessorMacro, PeerMacro {
  enum AttributeMacroErrors: Error {
    case notAVariable
  }

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
    let declaration = declaration.as(VariableDeclSyntax.self)!
    guard let property = try Property(declaration: declaration, attribute: node) else { return [] }

    var result: [AccessorDeclSyntax] = []

    // Redirect reads and writes to the property wrapped value
    result.append(
      """
      get {
        access(keyPath: \\.\(property.name))
        return \(property.storageName).wrappedValue
      }
      """
    )

    result.append(
      """
      set {
        withMutation(keyPath: \\.\(property.name)) {
          \(property.storageName).wrappedValue = newValue
        }
      }
      """
    )

    return result
  }

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    var result: [DeclSyntax] = []

    guard let declaration = declaration.as(VariableDeclSyntax.self) else {
      throw AttributeMacroErrors.notAVariable
    }
    guard let property = try Property(declaration: declaration, attribute: node) else { return [] }

    // It's possible we could use @ObservationTracked here, at the expense of having the
    // wrong name for the keypath used in the property accessor.
    result.append(
      """
      @ObservationIgnored private var \(property.storageName) = \(property.storageType)()
      """
    )

    // The projected value of the storage
    result.append(
      """
      \(property.modifiers) var \(property.projectedName): \(property.storageType) {
        get {
          access(keyPath: \\.\(property.name))
          return \(property.storageName)
        }
        set {
          withMutation(keyPath: \\.\(property.name)) {
            \(property.storageName) = newValue
          }
        }
      }
      """
    )

    return result
  }
}
