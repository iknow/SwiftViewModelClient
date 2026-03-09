//
//  Property.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/14.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct Property {
  enum Kind {
    case attribute
    case association
  }

  enum ParseError: Error {
    case multipleBindings
    case multipleAttributes
    case missingTypeAnnotation
    case unexpectedIdentifierToken(_: TokenKind)
    case unexpectedType(_: TypeSyntax)
  }

  let kind: Kind
  let name: TokenSyntax
  let type: TypeSyntax
  let modifiers: DeclModifierListSyntax
  let attribute: AttributeSyntax

  /// The name of the underlying storage in the viewmodel class
  let storageName: TokenSyntax

  /// Analogous to the projectedValue of a property wrapper
  let projectedName: TokenSyntax

  // Normally we expand directly, but sometimes we also expand in a global context and are looking down.
  // (gathering attributes is looking down, for the all main methods).
  init?(
    declaration: VariableDeclSyntax,
    attribute: AttributeSyntax? = nil
  ) throws {
    guard let attribute = try attribute ?? Self.viewmodelAttribute(declaration) else { return nil }

    guard declaration.bindings.count == 1 else { throw ParseError.multipleBindings }
    let patternBinding = declaration.bindings.first!

    let id = patternBinding.pattern.cast(IdentifierPatternSyntax.self).identifier

    guard let type = patternBinding.typeAnnotation?.type else {
      throw ParseError.missingTypeAnnotation
    }

    name = id
    self.type = type
    self.attribute = attribute
    modifiers = declaration.modifiers
    kind = try Self.kindOf(attribute)

    let rawName: String = try Self.unquotedName(identifier: id)
    storageName = "_\(raw: rawName)"
    projectedName = "$\(raw: rawName)"
  }

  static func viewmodelAttribute(_ varDecl: VariableDeclSyntax) throws -> AttributeSyntax? {
    let candidates = try varDecl.attributes.compactMap { attribute in
      if
        case let .attribute(attr) = attribute,
        try attributeIsViewModelAttribute(attr)
      {
        return attr
      } else {
        return nil
      }
    }

    guard candidates.count <= 1 else { throw ParseError.multipleAttributes }

    return candidates.first
  }

  static func unquotedName(identifier: TokenSyntax) throws -> String {
    switch identifier.tokenKind {
    case let .identifier(name):
      // name may or may not be quoted, and this appears to be only
      // represented on the string level.
      if name.hasPrefix("`") && name.hasSuffix("`") {
        return name.trimmingCharacters(in: ["`"])
      } else {
        return name
      }
    default:
      throw ParseError.unexpectedIdentifierToken(identifier.tokenKind)
    }
  }

  /// Attribute name without any namespacing
  static func attributeName(_ attr: AttributeSyntax) throws -> String {
    let name: TokenSyntax

    if let memberType = attr.attributeName.as(MemberTypeSyntax.self) {
      name = memberType.name
    } else if let identifier = attr.attributeName.as(IdentifierTypeSyntax.self) {
      name = identifier.name
    } else {
      throw ParseError.unexpectedType(attr.attributeName)
    }

    guard case let .identifier(nameString) = name.tokenKind else {
      throw ParseError.unexpectedIdentifierToken(name.tokenKind)
    }

    return nameString
  }

  static func attributeIsViewModelAttribute(_ attr: AttributeSyntax) throws -> Bool {
    let nameString = try attributeName(attr)
    return nameString.hasSuffix("Attribute") || nameString.hasSuffix("Association")
  }

  static func kindOf(_ attribute: AttributeSyntax) throws -> Kind {
    let nameString = try attributeName(attribute)
    if nameString.hasSuffix("Attribute") {
      return .attribute
    } else {
      return .association
    }
  }

  var storageType: TypeSyntax {
    switch kind {
    case .attribute:
      """
      AttributeStorage<\(type)>
      """
    case .association:
      """
      AssociationStorage<\(type)>
      """
    }
  }

  var witnessObject: ExprSyntax {
    let arguments = LabeledExprListSyntax {
      LabeledExprSyntax(label: "of", expression: "\(type).self" as ExprSyntax)
      if let arguments = attribute.arguments {
        for argument in arguments.children(viewMode: .all) {
          argument.cast(LabeledExprSyntax.self)
        }
      }
    }

    let identifier = attribute.attributeName.cast(IdentifierTypeSyntax.self)

    return
      "\(identifier)(\(arguments))"
  }
}
