//
//  GenerateReportPlugin.swift
//  ViewModels
//
//  Created by Eric Velazquez on 2026/11/09.
//

import PackagePlugin
import Foundation

@main
struct GenerateViewModelsPlugin: CommandPlugin {
    
  func performCommand(context: PluginContext, arguments: [String]) async throws {
    let tool = try context.tool(named: "Generator")
    let process = run(tool: tool, arguments: arguments)
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus != 0 {
      Diagnostics.error("CLI tool failed with exit code \(process.terminationStatus)")
    }
    
    try cleanPrint(
      outputPipe: outputPipe,
      arguments: arguments
    )
  }
  
  fileprivate func run(tool: PluginContext.Tool, arguments: [String]) -> Process {
    // Find the compiled executable path from the context.
    let toolUrl = URL(fileURLWithPath: tool.path.string)
    
    var extractor = ArgumentExtractor(arguments)
    _ = extractor.extractOption(named: "target")
        
    // Get the remaining arguments (with "--target" removed).
    let remainingArgs = extractor.remainingArguments
              
    // Forward the raw arguments array.
    let process = Process()
    process.executableURL = toolUrl
    process.arguments = remainingArgs
    
    // Disable system printing.
    var env = ProcessInfo.processInfo.environment
    env["OS_ACTIVITY_MODE"] = "disable"
    env["CFNETWORK_DIAGNOSTICS"] = "0"
    process.environment = env
    
    return process
  }
  
  fileprivate func cleanPrint(
    outputPipe: Pipe,
    arguments: [String]
  ) throws {
    let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()

    if !outputData.isEmpty {
      if let rawOutput = String(data: outputData, encoding: .utf8) {
        // Grab out all [INFO]...[/INFO] blocks and their trailing newlines.
        let infoPattern = #/\[INFO\]([\s\S]*?)\[\/INFO\]\n?/#
        
        let extractedInfo = rawOutput
            .matches(of: infoPattern)
            .map { String($0.output.1) }
            .joined(separator: "\n")
        
        if !extractedInfo.isEmpty {
          print(extractedInfo)
        }
        
        let cleanSwiftCode = rawOutput
          .replacing(infoPattern, with: "")
          .trimmingCharacters(in: .whitespacesAndNewlines)

        if !cleanSwiftCode.isEmpty {
          print("\n\n---------------- GENERATED CODE ----------------\n\n")
          print(cleanSwiftCode)
        }
      }
    }
  }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension GenerateViewModelsPlugin: XcodeCommandPlugin {
  func performCommand(context: XcodePluginContext, arguments: [String]) throws {
    let tool = try context.tool(named: "Generator")
    let process = run(tool: tool, arguments: arguments)
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    
    try process.run()
    process.waitUntilExit()
    
    try cleanPrint(
      outputPipe: outputPipe,
      arguments: arguments
    )
  }
}
#endif
