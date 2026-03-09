//
//  PropertiesMacro.swift
//
//
//  Created by Andrew Childs on 2023/09/11.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct PropertiesMacro: MemberMacro {
  enum PropertiesError: Error {
    case notAClass
    case unexpectedIdentifierToken(_: TokenKind)
  }

  static func members(_ classDecl: ClassDeclSyntax) -> [DeclSyntax] {
    classDecl.memberBlock.members.map(\.decl)
  }

  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    providingMembersOf declaration: some SwiftSyntax.DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.DeclSyntax] {
    // Must be a class
    guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
      throw PropertiesError.notAClass
    }

    let final = classDecl.modifiers.contains(where: { modifier in
      if case .keyword(.final) = modifier.name.tokenKind {
        return true
      } else {
        return false
      }
    })

    let modifier = final ? "public" : "open"

    let properties = try members(classDecl).compactMap { decl in
      try decl.as(VariableDeclSyntax.self).flatMap { try Property(declaration: $0) }
    }

    let witnessNamespace = EnumDeclSyntax(name: "Properties") {
      for property in properties {
        "static let \(property.name) = \(property.witnessObject)"
      }
    }

    let deserialize = try FunctionDeclSyntax("override \(raw: modifier) func deserialize(from parser: ViewModelParser, in context: DeserializeContext) throws") {
      "try super.deserialize(from: parser, in: context)"
      for property in properties {
        "try Properties.\(property.name).deserialize(&\(property.projectedName), instance: self, from: parser, in: context)"
      }
    }

    let serialize = try FunctionDeclSyntax("override \(raw: modifier) func serialize(to emitter: ViewModelEmitter, in context: SerializeContext) throws") {
      "try super.serialize(to: emitter, in: context)"
      for property in properties {
        "try Properties.\(property.name).serialize(&\(property.projectedName), instance: self, to: emitter, in: context)"
      }
    }

    let initDefaults = try FunctionDeclSyntax("override \(raw: modifier) func initDefaults()") {
      "super.initDefaults()"
      for property in properties {
        "Properties.\(property.name).initDefault(&\(property.storageName))"
      }
    }

    let nestedVersions = try FunctionDeclSyntax("override \(raw: modifier) class func nestedVersions(into versionMap: inout [String: Int])") {
      "super.nestedVersions(into: &versionMap)"
      for property in properties where property.kind == .association {
        "Properties.\(property.name).nestedVersions(into: &versionMap)"
      }
    }

    let discardChanges = try FunctionDeclSyntax("override \(raw: modifier) func discardChanges()") {
      "super.discardChanges()"
      for property in properties {
        "Properties.\(property.name).discardChanges(&\(property.projectedName))"
      }
    }

    let saved = try FunctionDeclSyntax("override \(raw: modifier) func saved(_ other: ViewModel)") {
      "super.saved(other)"
      "guard let other = other as? Self else { fatalError(\"Mismatched saved call\") }"
      for property in properties {
        "Properties.\(property.name).saved(&\(property.projectedName), other: other.\(property.storageName))"
      }
    }

    let walkProperties = try FunctionDeclSyntax("override \(raw: modifier) func _walkChildren(_ visitor: (ViewModel) -> Bool)") {
      "super._walkChildren(visitor)"
      for property in properties where property.kind == .association {
        "Properties.\(property.name).walk(\(property.projectedName), visitor: visitor)"
      }
    }

    return [
      .init(witnessNamespace),
      .init(deserialize),
      .init(serialize),
      .init(initDefaults),
      .init(nestedVersions),
      .init(discardChanges),
      .init(saved),
      .init(walkProperties),
    ]
  }
}
