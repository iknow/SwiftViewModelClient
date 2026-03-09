//
//  ViewModelMacro.swift
//
//
//  Created by Andrew Childs on 2023/10/18.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Umbrella macro that calls all other macros to make a full ViewModel
public struct ViewModelMacro: MemberMacro, ExtensionMacro {
  public static func expansion(
    of node: SwiftSyntax.AttributeSyntax,
    attachedTo declaration: some SwiftSyntax.DeclGroupSyntax,
    providingExtensionsOf type: some SwiftSyntax.TypeSyntaxProtocol,
    conformingTo protocols: [SwiftSyntax.TypeSyntax],
    in context: some SwiftSyntaxMacros.MacroExpansionContext
  ) throws -> [SwiftSyntax.ExtensionDeclSyntax] {
    var decls: [ExtensionDeclSyntax] = []

    try decls.append(contentsOf: ObservationRegistrarMacro.expansion(
      of: node,
      attachedTo: declaration,
      providingExtensionsOf: type,
      conformingTo: protocols,
      in: context
    ))

    return decls
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    var decls: [DeclSyntax] = []

    try decls.append(contentsOf: PropertiesMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      conformingTo: protocols,
      in: context
    ))

    try decls.append(contentsOf: MigrationWarningMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      conformingTo: protocols,
      in: context
    ))

    try decls.append(contentsOf: ObservationRegistrarMacro.expansion(
      of: node,
      providingMembersOf: declaration,
      conformingTo: protocols,
      in: context
    ))

    return decls
  }
}
