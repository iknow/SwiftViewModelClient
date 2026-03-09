//
//  ViewModelsMacrosPlugin.swift
//
//
//  Created by Andrew Childs on 2023/10/18.
//

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct ViewModelsPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    AttributeMacro.self,
    PropertiesMacro.self,
    MigrationWarningMacro.self,
    ViewModelMacro.self,
    ObservationRegistrarMacro.self,
    VMRIdAttributeMacro.self,
    EphemeralMacro.self,
    ViewModelVariantMacro.self,
  ]
}
