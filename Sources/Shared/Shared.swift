//
//  Constants.swift
//  ViewModels
//
//  Created by Eric Velazquez on 2026/11/11.
//


/// The configuration used for the Generate command.
public struct PluginConfigFile: Codable {
  public let write: Bool?
  public let force: Bool?
  public let outputDir: String?
  public let typeNames: [String]
  public let recurse: Bool?
  public let apiDomain: String?
}

public let defaultConfig = PluginConfigFile(
  write: false,
  force: false,
  outputDir: "",
  typeNames: [],
  recurse: true,
  apiDomain: "https://localhost.devdomain.name:3000"
)
