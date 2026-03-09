//
//  main.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/12.
//

import Foundation
import TestModels
import ViewModels

enum Benchmarks {
  static func main() throws {
    let bytes = try TestModelResources.loadJson(name: "scenarios")
    for _ in 0...100 {
      _ = try ViewModel.deserialize(json: bytes, type: [RolePlayScenario].self)
    }
  }
}

try! Benchmarks.main()
