//
//  RolePlayConversation.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation
import ViewModels

@ViewModel
public class RolePlayConversation: ViewModelRecord<UUID> {
  override public class var typeName: String { "RolePlay.Conversation" }
  override public class var version: Int { 2 }

  @Association(name: "scenario")
  public var scenario: RolePlayScenario

  @Association(name: "exchanges")
  public var exchanges: [RolePlayConversationExchange]

  @Attribute(name: "assistant_greeting", default: "")
  public var assistantGreeting: String

  @Attribute(name: "greeting_translation", default: "")
  public var greetingTranslation: String?

  @Attribute(name: "greeting_translation_language", default: "")
  public var greetingTranslationLangauge: String?

  @Attribute(name: "lock_version", default: 0)
  public var lockVersion: Int
}
