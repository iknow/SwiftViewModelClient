//
//  EphemeralMacro.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/19.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Similar to SwiftData's @Attribute(.ephemeral)
struct EphemeralMacro: PeerMacro, AccessorMacro {
  struct TransientProperty {
    enum ParseError: Error {
      case multipleBindings
      case multipleAttributes
      case missingTypeAnnotation
      case unexpectedIdentifierToken(_: TokenKind)
      case unexpectedType(_: TypeSyntax)
    }

    let name: TokenSyntax
    let type: TypeSyntax
    let modifiers: DeclModifierListSyntax
    let storageName: TokenSyntax

    init(declaration: VariableDeclSyntax) throws {
      guard declaration.bindings.count == 1 else { throw ParseError.multipleBindings }
      let patternBinding = declaration.bindings.first!

      let id = patternBinding.pattern.cast(IdentifierPatternSyntax.self).identifier

      guard let type = patternBinding.typeAnnotation?.type else {
        throw ParseError.missingTypeAnnotation
      }

      name = id
      self.type = type
      modifiers = declaration.modifiers

      let rawName: String = try Property.unquotedName(identifier: id)
      storageName = "_\(raw: rawName)"
    }
  }

  enum EphemeralMacroError: Error {
    case invalidDeclaration
  }

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingAccessorsOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.AccessorDeclSyntax] {
    guard let declaration = declaration.as(VariableDeclSyntax.self) else {
      throw EphemeralMacroError.invalidDeclaration
    }
    let property = try TransientProperty(declaration: declaration)

    var result: [AccessorDeclSyntax] = []

    // Redirect reads and writes to the property wrapped value
    result.append(
      """
      get {
        access(keyPath: \\.\(property.name))
        return \(property.storageName)
      }
      """
    )

    result.append(
      """
      set {
        withMutation(keyPath: \\.\(property.name)) {
          \(property.storageName) = newValue
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
      throw EphemeralMacroError.invalidDeclaration
    }
    let property = try TransientProperty(declaration: declaration)

    let bindings = PatternBindingListSyntax {
      for binding in declaration.bindings {
        PatternBindingSyntax(
          pattern: PatternSyntax(IdentifierPatternSyntax(identifier: property.storageName)),
          typeAnnotation: binding.typeAnnotation,
          initializer: binding.initializer
        )
      }
    }

    let storageDeclaration = VariableDeclSyntax(
      bindingSpecifier: declaration.bindingSpecifier,
      bindings: bindings
    )

    result.append(DeclSyntax(storageDeclaration))

    return result
  }
}
