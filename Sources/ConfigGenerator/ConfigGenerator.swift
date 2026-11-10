//
//  ConfigGenerator.swift
//  ViewModels
//
//  Created by Eric Velazquez on 2026/11/11.
//

import ArgumentParser
import Foundation
import Shared

@main
struct GenerateConfig: AsyncParsableCommand {
  private static let defaultConfigPath = ".config/generation.json"
  
  @Argument(help: "Config path. Defaults to \(defaultConfigPath)")
  var configPath: String = defaultConfigPath
  
  mutating func run() async throws {
    let fileManager = FileManager.default
    
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    do {
      let content = try encoder.encode(defaultConfig)
      let configUrl = URL(fileURLWithPath: configPath)
      try fileManager.createDirectory(
        at: configUrl.deletingLastPathComponent(),
        withIntermediateDirectories: true,
        attributes: nil
      )
      try content.write(to: configUrl)
      
      print("Config file created at \(configPath)")
    } catch {
      print("Couldn't create config file.")
    }
  }
}
