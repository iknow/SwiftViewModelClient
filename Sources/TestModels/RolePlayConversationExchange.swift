//
//  RolePlayConversationExchange.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation
import ViewModels

@ViewModel
public class RolePlayConversationExchange: ViewModelRecord<UUID> {
  override public class var typeName: String { "RolePlay.ConversationExchange" }
  override public class var version: Int { 5 }
}
