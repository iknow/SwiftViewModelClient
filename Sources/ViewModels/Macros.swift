//
//  Macros.swift
//
//
//  Created by Andrew Childs on 2023/09/11.
//

import Observation

@attached(member, names: named(warnOnMigration), named(warnedOnMigration))
macro MigrationWarning() =
  #externalMacro(module: "ViewModelsMacros", type: "MigrationWarningMacro")

@attached(
  member,
  names:
  named(_$observationRegistrar),
  named(access),
  named(withMutation)
)
macro ObservationRegistrar() =
  #externalMacro(module: "ViewModelsMacros", type: "ObservationRegistrarMacro")

@attached(
  member,
  names:
  named(Properties),
  named(warnOnMigration),
  named(migrationWarning),
  named(_$observationRegistrar),
  named(access),
  named(withMutation),
  named(initDefaults),
  named(nestedVersions),
  named(deserialize),
  named(serialize),
  named(discardChanges),
  named(saved),
  named(_walkChildren)
)
@attached(extension, conformances: Observable)
public macro ViewModel() =
  #externalMacro(module: "ViewModelsMacros", type: "ViewModelMacro")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(`_`), prefixed(`$`))
public macro Attribute(name: String) =
  #externalMacro(module: "ViewModelsMacros", type: "AttributeMacro")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(`_`), prefixed(`$`))
public macro Attribute(
  name: String,
  default: Any?
) =
  #externalMacro(module: "ViewModelsMacros", type: "AttributeMacro")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(`_`), prefixed(`$`))
public macro Attribute<Value>(
  name: String,
  format: any ViewModelFormat<Value>
) =
  #externalMacro(module: "ViewModelsMacros", type: "AttributeMacro")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(`_`), prefixed(`$`))
public macro Attribute<Value>(
  name: String,
  default: @escaping @autoclosure () -> Value,
  format: any ViewModelFormat<Value>
) =
  #externalMacro(module: "ViewModelsMacros", type: "AttributeMacro")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(`_`), prefixed(`$`))
public macro Association(
  name: String
) =
  #externalMacro(module: "ViewModelsMacros", type: "AttributeMacro")

@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(`_`), prefixed(`$`))
public macro VMRIdAttribute() =
  #externalMacro(module: "ViewModelsMacros", type: "VMRIdAttributeMacro")

/// Defines an observable attribute that is local to the class.
///
/// This is comparable to @Attribute(.ephemeral) in Swift Data.
@attached(accessor, names: named(get), named(set))
@attached(peer, names: prefixed(`_`))
public macro Ephemeral() =
  #externalMacro(module: "ViewModelsMacros", type: "EphemeralMacro")

@attached(extension, conformances: ViewModelVersions, AssociationValue)
@attached(member, names: named(nestedVersions), named(deserializeAssociated), named(serializeAssociated), named(walk))
public macro ViewModelVariant() =
  #externalMacro(module: "ViewModelsMacros", type: "ViewModelVariantMacro")
