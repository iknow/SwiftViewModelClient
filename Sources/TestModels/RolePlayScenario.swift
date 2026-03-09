//
//  RolePlayScenario.swift
//  Eikaiwa
//
//  Created by Kevin Griffin on 2023/07/12.
//

import Foundation
import ViewModels

@ViewModel
public class RolePlayScenario: ViewModelRecord<UUID> {
  override public class var typeName: String { "RolePlay.Scenario" }
  override public class var version: Int { 3 }
  override public class var root: Bool { true }

  @Association(name: "owner")
  public var owner: OrganizationReference

  @Association(name: "name")
  public var name: LocalizableText

  @Association(name: "description")
  public var description: LocalizableText

  @Association(name: "introduction")
  public var introduction: LocalizableText?

  @Association(name: "image")
  public var image: RemoteImage?

  @Attribute(name: "language")
  public var language: Language

  @Attribute(name: "requires_lesson")
  public var requiresLesson: Bool

  @Attribute(name: "enabled")
  public var enabled: Bool

  // If the scenario was fetched in an authenticated context and progress
  // was requested, we know if the user has finished the scenario
  @Ephemeral public var complete: Bool = false
}
