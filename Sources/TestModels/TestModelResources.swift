//
//  TestModelResources.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/13.
//

import Foundation

public enum TestModelResources {
  public static func loadJson(name: String) throws -> Data {
    let url = Bundle.module.path(forResource: name, ofType: "json")!
    let bytes = try Data(contentsOf: URL(filePath: url))
    return bytes
  }
}
