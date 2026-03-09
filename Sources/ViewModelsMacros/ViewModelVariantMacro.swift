//
//  ViewModelVariantMacro.swift
//  ViewModels
//
//  Created by Andrew Childs on 2025/05/29.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct ViewModelVariantMacro: ExtensionMacro, MemberMacro {
  enum Errors: Error {
    case notAnEnum
    case noParameters
    case multipleParameters
  }

  struct VariantCase {
    var name: TokenSyntax
    var type: TypeSyntax
  }

  static func variantCases(of enumDecl: EnumDeclSyntax) throws -> [VariantCase] {
    try enumDecl.memberBlock.members.flatMap { member -> [VariantCase] in
      guard let caseDecl = member.decl.as(EnumCaseDeclSyntax.self) else {
        return []
      }

      return try caseDecl.elements.map { caseElement in
        guard let parameters = caseElement.parameterClause?.parameters else { throw Errors.noParameters }
        guard parameters.count == 1 else { throw Errors.multipleParameters }

        return VariantCase(name: caseElement.name, type: parameters.first!.type)
      }
    }
  }

  static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw Errors.notAnEnum
    }
    let enumType = IdentifierTypeSyntax(name: enumDecl.name)

    return protocols.map { p in
      ExtensionDeclSyntax(
        extendedType: enumType,
        inheritanceClause: InheritanceClauseSyntax(inheritedTypesBuilder: {
          InheritedTypeSyntax(type: p)
        })
      ) {}
    }
  }

  static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let enumDecl = declaration.as(EnumDeclSyntax.self) else {
      throw Errors.notAnEnum
    }
    let variantCases = try variantCases(of: enumDecl)

    return try [
      DeclSyntax(FunctionDeclSyntax("static func nestedVersions(into versionMap: inout [String: Int])") {
        for variantCase in variantCases {
          "\(variantCase.type).nestedVersions(into: &versionMap)"
        }
      }),

      DeclSyntax(FunctionDeclSyntax("static func deserializeAssociated(from parser: ViewModelParser, in context: DeserializeContext) throws -> Self") {
        "let type = try context.associationType(from: parser)"

        try SwitchExprSyntax("switch type") {
          for variantCase in variantCases {
            "case \(variantCase.type).typeName: return try \(variantCase.name)(\(variantCase.type).deserializeAssociated(from: parser, in: context))"
          }

          "default: throw DeserializeError.loadError"
        }
      }),

      DeclSyntax(FunctionDeclSyntax("func serializeAssociated(to emitter: ViewModelEmitter, in context: SerializeContext) throws") {
        try SwitchExprSyntax("switch self") {
          for variantCase in variantCases {
            "case let .\(variantCase.name)(value): try value.serializeAssociated(to: emitter, in: context)"
          }
        }
      }),

      DeclSyntax(FunctionDeclSyntax("func walk(_ visitor: (ViewModel) -> Bool)") {
        try SwitchExprSyntax("switch self") {
          for variantCase in variantCases {
            "case let .\(variantCase.name)(value): value.walk(visitor)"
          }
        }
      }),
    ]
  }
}
