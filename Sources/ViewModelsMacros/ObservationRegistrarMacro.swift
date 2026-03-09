//
//  ObservationRegistrarMacro.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/14.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Supply an observation registrar, but without observing any fields.
public struct ObservationRegistrarMacro: MemberMacro, ExtensionMacro {
  enum ObservationRegistrarMacroError: Error {
    case notAClass
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
      throw ObservationRegistrarMacroError.notAClass
    }

    let classType = IdentifierTypeSyntax(name: classDecl.name)

    return [
      """
      @ObservationIgnored private let _$observationRegistrar = Observation.ObservationRegistrar()
      """,

      """
      internal nonisolated func access<Member>(
          keyPath: KeyPath<\(classType), Member>
      ) {
          _$observationRegistrar.access(self, keyPath: keyPath)
      }
      """,

      """
      internal nonisolated func withMutation<Member, MutationResult>(
          keyPath: KeyPath<\(classType), Member>,
          _ mutation: () throws -> MutationResult
      ) rethrows -> MutationResult {
          try _$observationRegistrar.withMutation(of: self, keyPath: keyPath, mutation)
      }
      """,
    ]
  }

  public static func expansion(
    of node: AttributeSyntax,
    attachedTo declaration: some DeclGroupSyntax,
    providingExtensionsOf type: some TypeSyntaxProtocol,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [ExtensionDeclSyntax] {
    guard !protocols.isEmpty else { return [] }

    let classDecl = declaration.as(ClassDeclSyntax.self)!
    let classType = IdentifierTypeSyntax(name: classDecl.name)
    return [
      ExtensionDeclSyntax(
        extendedType: classType,
        inheritanceClause: InheritanceClauseSyntax(inheritedTypes:
          InheritedTypeListSyntax {
            InheritedTypeSyntax(type:
              IdentifierTypeSyntax(name: "Observation.Observable"))
          }
        ),
        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax([]))
      ),
    ]
  }
}
