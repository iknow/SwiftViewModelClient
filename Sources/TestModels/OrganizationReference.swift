//
//  OrganizationReference.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation
import ViewModels

@ViewModel
public class OrganizationReference: ViewModelRecord<UUID> {
  override public class var typeName: String { "OrganizationReference" }
  override public class var version: Int { 3 }
  override public class var root: Bool { true }
}
