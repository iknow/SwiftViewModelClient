//
//  Default.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation

public protocol Default {
  static func defaultValue() -> Self
}

extension UUID: Default {
  public static func defaultValue() -> UUID {
    UUID()
  }
}

extension Optional: Default {
  public static func defaultValue() -> Self {
    nil
  }
}

extension Array: Default {
  public static func defaultValue() -> Self {
    []
  }
}
