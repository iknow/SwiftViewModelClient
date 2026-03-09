//
//  MigrationWarningMacro.swift
//
//
//  Created by Andrew Childs on 2023/10/18.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

public struct MigrationWarningMacro: MemberMacro {
  enum MigrationWarningError: Error {
    case notAClass
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingMembersOf declaration: some DeclGroupSyntax,
    conformingTo protocols: [TypeSyntax],
    in context: some MacroExpansionContext
  ) throws -> [DeclSyntax] {
    guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
      throw MigrationWarningError.notAClass
    }
    let classType = IdentifierTypeSyntax(name: classDecl.name)

    return [
      """
      #if DEBUG
      private static let migrationWarning = MigrationWarning()
      public override class func warnOnMigration() {
        migrationWarning.warn(forViewModel: \(classType).self)
      }
      #endif
      """,
    ]
  }
}
