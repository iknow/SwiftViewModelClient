//
//  GenerateConfig.swift
//  ViewModels
//
//  Created by Eric Velazquez on 2026/11/11.
//

import PackagePlugin
import Foundation

@main
struct GenerateConfigPlugin: CommandPlugin {

  func performCommand(context: PluginContext, arguments: [String]) async throws {
    let tool = try context.tool(named: "ConfigGenerator")
    let toolUrl = URL(fileURLWithPath: tool.path.string)
    
    var extractor = ArgumentExtractor(arguments)
    _ = extractor.extractOption(named: "target")
        
    // Get the remaining arguments (with "--target" removed).
    let remainingArgs = extractor.remainingArguments
    
    let process = try Process.run(toolUrl, arguments: remainingArgs)
    process.waitUntilExit()
    
    if process.terminationStatus != 0 {
      Diagnostics.error("CLI tool failed with exit code \(process.terminationStatus)")
    }
  }

}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension GenerateConfigPlugin: XcodeCommandPlugin {
  func performCommand(context: XcodePluginContext, arguments: [String]) throws {
    let tool = try context.tool(named: "ConfigGenerator")
    let toolUrl = URL(fileURLWithPath: tool.path.string)
    
    var extractor = ArgumentExtractor(arguments)
    _ = extractor.extractOption(named: "target")
        
    // Get the remaining arguments (with "--target" removed).
    let remainingArgs = extractor.remainingArguments
    
    let process = try Process.run(toolUrl, arguments: remainingArgs)
    process.waitUntilExit()
  }
}
#endif
