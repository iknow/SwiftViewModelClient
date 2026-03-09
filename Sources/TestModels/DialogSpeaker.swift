//
//  DialogSpeaker.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation
import ViewModels

@ViewModel
public class DialogSpeaker: ViewModelRecord<UUID> {
  override public class var typeName: String { "DialogSpeaker" }
  override public class var version: Int { 6 }
  override public class var root: Bool { true }

  @Attribute(name: "name", default: "")
  public var name: String
}
