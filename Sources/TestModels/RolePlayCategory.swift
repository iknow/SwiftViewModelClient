//
//  RolePlayCategory.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation
import ViewModels

@ViewModel
public class RolePlayCategory: ViewModelRecord<UUID> {
  override public class var typeName: String { "RolePlay.Category" }

  @Association(name: "name")
  public var name: LocalizableText
}
