import ArgumentParser
import Foundation
import ViewModels
import Shared

public struct AttributeMember {
  let name: String
  let type: String
  let array: Bool
  let writeOnce: Bool
  let nullable: Bool?
  let attributeKind: String
  let attributeType: String?

  var localType: String? {
    guard let attributeType else { return nil }

    switch attributeType {
    case "string": return "String"
    case "boolean": return "Bool"
    case "integer": return "Int"
    case "uuid": return "UUID"
    case "Time": return "Date"
    case "point": return "CGSize" // Not always correct, but more common than CGPoint
    case "float": return "Double"
    default:
      break
    }

    if let match = try! #/ParamSerializers::(.+)/#.prefixMatch(in: attributeType) {
      let paramType = match.1.replacingOccurrences(of: "::", with: "")

      return switch paramType {
      case "Time": "Date"
      case "FixedDuration": "FixedDuration"
      default: paramType
      }
    }

    return attributeType
  }

  var formatType: String? {
    guard
      let attributeType,
      let match = try! #/ParamSerializers::(.+)/#.prefixMatch(in: attributeType)
    else { return nil }

    let paramType = match.1.replacingOccurrences(of: "::", with: "")

    return switch paramType {
    case "AccurateTime": "AccurateTimeFormat()"
    default: nil
    }
  }
}

extension AttributeMember: ViewModelParserDecodable {
  init(deserializingFrom parser: any ViewModelParser) throws {
    name = try parser.fetch(key: "name", type: String.self)
    type = try parser.fetch(key: "type", type: String.self)
    array = try parser.fetch(key: "array", type: Bool.self)
    writeOnce = try parser.fetch(key: "write_once", type: Bool.self)
    nullable = try parser.maybeFetch(key: "nullable", type: Bool.self)
    attributeKind = try parser.fetch(key: "attribute_kind", type: String.self)
    attributeType = try parser.maybeFetch(key: "attribute_type", type: String.self)
  }

  public static func deserialize(from parser: any ViewModels.ViewModelParser) throws -> Self {
    try Self(deserializingFrom: parser)
  }
}

public func localViewmodelType(_ type: String) -> String {
  switch type {
  case "Text": return "LocalizableText"
  case "Image": return "RemoteImage"
  default:
    return type.replacingOccurrences(of: ".", with: "")
  }
}

public struct AssociationMember {
  let name: String
  let type: String
  let viewmodels: [String]
  let owned: Bool
  let readOnly: Bool
  let collection: Bool
  let nullable: Bool
  let external: Bool

  var localType: String { localViewmodelType(name) }
}

extension AssociationMember: ViewModelParserDecodable {
  init(deserializingFrom parser: any ViewModelParser) throws {
    name = try parser.fetch(key: "name", type: String.self)
    type = try parser.fetch(key: "name", type: String.self)
    viewmodels = try parser.descend(into: "viewmodels").parseArray(of: String.self) { subparser in
      try subparser.unbox(type: String.self)
    }
    owned = try parser.fetch(key: "owned", type: Bool.self)
    readOnly = try parser.fetch(key: "read_only", type: Bool.self)
    collection = try parser.fetch(key: "collection", type: Bool.self)
    nullable = try parser.fetch(key: "nullable", type: Bool.self)
    external = try parser.fetch(key: "external", type: Bool.self)
  }

  public static func deserialize(from parser: any ViewModelParser) throws -> Self {
    try Self(deserializingFrom: parser)
  }
}

public enum Member {
  case association(_: AssociationMember)
  case attribute(_: AttributeMember)

  enum CodingKeys: String, CodingKey {
    case type
  }
}

extension Member: ViewModelParserCodable {
  init(deserializingFrom parser: any ViewModelParser) throws {
    let type = try parser.fetch(key: "type", type: String.self)
    switch type {
    case "association":
      self = try .association(AssociationMember.deserialize(from: parser))
    case "attribute":
      self = try .attribute(AttributeMember.deserialize(from: parser))
    default:
      fatalError("Unexpected member type \(type)")
    }
  }

  public static func deserialize(from parser: any ViewModelParser) throws -> Self {
    try Self(deserializingFrom: parser)
  }

  public func serialize(to emitter: ViewModelEmitter) throws {
    fatalError("unimplemented")
  }
}

struct Enum: Decodable {
  struct Member: Decodable {
    let enumConstant: String

    var swiftName: String {
      var name = enumConstant

      let start = name.startIndex
      if !name[start].isLowercase {
        let breakpoint = name.firstIndex { $0.isLowercase } ?? name.endIndex
        name = name[start..<breakpoint].lowercased().appending(name[breakpoint...])
      }

      name = name.replacingOccurrences(of: "-", with: "")

      return name
    }
  }

  enum CodingKeys: String, CodingKey {
    case type = "_type"
    case members
  }

  let type: String
  let members: [Member]

  static func fetchAll(urlSession: URLSession, domain: String) async throws -> [String: Enum] {
    let (raw, _) = try await urlSession.data(from: URL(string: "\(domain)/api/types")!)

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    let data = try decoder.decode(DataResponse<[Enum]>.self, from: raw)

    return Dictionary(uniqueKeysWithValues: data.data.map { ($0.swiftName, $0) })
  }

  func generate() -> String {
    var result = ""

    result.append("""
    import Foundation
    import ViewModels

    enum \(swiftName): String, CaseIterable, Codable, ViewModelParserRawCodable {

    """)

    for member in members {
      var stmt = "  case \(member.swiftName)"

      if member.swiftName != member.enumConstant {
        stmt.append(" = \"\(member.enumConstant)\"")
      }

      result.append(stmt)
      result.append("\n")
    }

    result.append("""
    }

    """)

    return result
  }

  var swiftName: String {
    try! String(#/Type\.(.+)$/#.prefixMatch(in: type)!.output.1)
      .replacingOccurrences(of: "::", with: "")
  }
}

struct DataResponse<T: Decodable>: Decodable {
  let data: T
}

@ViewModel
class Schema: ViewModel {
  override class var typeName: String { "ViewModelSchema" }
  override class var version: Int { 3 }

  @Attribute(name: "view_name")
  var viewName: String

  @Attribute(name: "view_schema_version")
  var viewSchemaVersion: Int

  @Attribute(name: "root")
  var root: Bool

  @Attribute(name: "members")
  var members: [Member]

  public func attributes() -> [AttributeMember] {
    members.compactMap { member -> AttributeMember? in
      guard case let .attribute(attr) = member else { return nil }
      return attr
    }
  }

  public func associations() -> [AssociationMember] {
    members.compactMap { member -> AssociationMember? in
      guard case let .association(assoc) = member, !assoc.external else { return nil }
      return assoc
    }
  }

  public func toCamelCase(_ snakeCase: String) -> String {
    let components = snakeCase.components(separatedBy: "_")

    guard let first = components.first else {
      fatalError("Failed to parse components of name: \(snakeCase)")
    }

    return first.appending(components.suffix(from: 1).map(\.capitalized).joined())
  }

  public func containedViewmodels() -> Set<String> {
    Set(associations().flatMap(\.viewmodels))
  }

  public var name: String {
    localViewmodelType(viewName)
  }

  public func generate() -> String {
    var result = ""

    result.append("""
    import Foundation
    import ViewModels

    @ViewModel
    class \(name): ViewModelRecord<UUID> {
      override class var typeName: String { "\(viewName)" }
      override class var version: Int { \(viewSchemaVersion) }
    """)

    if root {
      result.append("""

        override class var root: Bool { \(root) }
      """)
    }

    result.append("""



    """)

    for member in members {
      switch member {
      case let .attribute(attr):
        generateAttribute(attr, into: &result)
      case let .association(assoc) where !assoc.external:
        generateAssociation(assoc, into: &result)
      default:
        break
      }
    }

    result = result.trimmingCharacters(in: .whitespacesAndNewlines)

    result.append("\n}\n")

    return result
  }

  private func generateAssociation(_ member: AssociationMember, into result: inout String) {
    var comments: [String] = []
    var type: String
    if member.viewmodels.count == 1 {
      type = localViewmodelType(member.viewmodels[0])
    } else {
      comments.append("// TODO: resolve polymorphic types")
      type = member.viewmodels.map { localViewmodelType($0) }.joined(separator: ", ")
    }
    if member.collection {
      type = "[\(type)]"
    }

    if member.nullable {
      type += "?"
    }

    result.append(comments.map { "  " + $0 + "\n" }.joined())

    result.append("""
      @Association(name: "\(member.name)")
      var \(toCamelCase(member.name)): \(type)


    """)
  }

  private func generateAttribute(_ member: AttributeMember, into result: inout String) {
    var attributes: [String] = []
    var comments: [String] = []

    attributes.append("name: \"\(member.name)\"")

    let localType = member.localType

    var type: String
    if let localType {
      type = localType
    } else {
      comments.append("// TODO: check type")
      type = "HOLE"
    }

    if member.array {
      type = "[\(type)]"
    }

    let assumedNullability: Bool
    if let nullable = member.nullable {
      assumedNullability = nullable
    } else {
      comments.append("// TODO: check nullability")
      assumedNullability = true
    }

    if assumedNullability {
      type += "?"
    }

    var `default`: String? = nil
    if assumedNullability {
      `default` = "nil"
    } else if member.array {
      `default` = "[]"
    } else if type == "Bool" {
      `default` = "false"
    } else if type == "String" {
      `default` = "\"\""
    } else if type == "Language" {
      `default` = "Language.en"
    }

    if let `default` {
      attributes.append("default: \(`default`)")
    }

    var format = member.formatType
    if assumedNullability {
      format = format.map { "\($0).optional()" }
    }
    if let format {
      attributes.append("format: \(format)")
    }

    result.append(comments.map { "  " + $0 + "\n" }.joined())

    result.append("""
      @Attribute(\(attributes.joined(separator: ", ")))
      var \(toCamelCase(member.name)): \(type)


    """)
  }
}

@main
struct Generate: AsyncParsableCommand {
  @Flag(help: "Write to file")
  var write: Bool = defaultConfig.write!

  @Flag(help: "Overwrite existing files")
  var force: Bool = defaultConfig.force!

  @Option(help: "output dir")
  var outputDir: String?

  @Option(help: "The names of the types that will be generated.")
  var typeNames: String?

  @Flag(inversion: .prefixedNo, help: "Generate models and their children.")
  var recurse: Bool = defaultConfig.recurse!
  
  @Option(help: "Path to the JSON configuration file, if any.")
  var configPath: String = ".config/generation.json"
  
  @Option(help: "The api url used to fetch types. Defaults to localhost.")
  var apiDomain: String = defaultConfig.apiDomain!

  mutating func run() async throws {
    let fm = FileManager.default
    
    // Use custom session to avoid cache errors.
    let config = URLSessionConfiguration.ephemeral
    config.urlCache = nil
    config.requestCachePolicy = .reloadIgnoringLocalCacheData

    let urlSession = URLSession(configuration: config)
    
    var typeNames: [String] = []
    var force = self.force
    var outputDir = self.outputDir
    var write = self.write
    var recurse = self.recurse
    var apiDomain = self.apiDomain
    
    // Try to read and decode the JSON file.
    if fm.fileExists(atPath: configPath) {
      printInfo("Reading configuration from \(configPath)...")
      let data = try Data(contentsOf: URL(fileURLWithPath: configPath))
      let config = try JSONDecoder().decode(PluginConfigFile.self, from: data)
      
      if let jsonObject = try? JSONSerialization.jsonObject(with: data),
         let prettyData = try? JSONSerialization.data(
          withJSONObject: jsonObject,
          options: [.prettyPrinted, .sortedKeys]
         ),
         let prettyString = String(data: prettyData, encoding: .utf8)
      {
        printInfo(prettyString)
      }
                
      typeNames = config.typeNames
      force = config.force ?? force
      outputDir = config.outputDir ?? outputDir
      write = config.write ?? write
      recurse = config.recurse ?? recurse
      apiDomain = config.apiDomain ?? apiDomain
    } else {
      printInfo("No config file found at \(configPath)")
    }
    
    // Fallback/Override logic: If user typed specific CLI options, use those instead.
    if let cliNames = self.typeNames {
      typeNames = cliNames.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
    
    if typeNames.isEmpty {
      printInfo("No type names specified via a cli argument or the config file. Exiting...")
      return
    }

    if let outputDir, !outputDir.isEmpty && !fm.fileExists(atPath: outputDir) {
      printInfo("Output directory \(outputDir) does not exist. Files will not be created.")
    }
    
    // Avoid path issues.
    if (apiDomain.last == "/") {
      apiDomain.removeLast()
    }

    var done = Set<String>()
    var queueHead = 0
    var queue = typeNames

    let allEnums = try await Enum.fetchAll(
      urlSession: urlSession,
      domain: apiDomain
    )

    var usedEnumNames = Set<String>()

    while queueHead < queue.count  {
      let work = queue[queueHead]
      queueHead += 1

      let (data, _) = try await urlSession.data(from: URL(string: "\(apiDomain)/api/schemas/\(work)")!)

      printInfo("Parsing: \(work)")
      let schema = try! ViewModel.deserialize(json: data, type: Schema.self)

      let generated = schema.generate()

      try emit(
        filename: "\(schema.name).swift",
        contents: generated,
        write: write,
        outputDir: outputDir,
        force: force
      )

      if recurse {
        for attribute in schema.attributes() {
          if let localType = attribute.localType, allEnums[localType] != nil {
            usedEnumNames.insert(localType)
          }
        }

        for nested in schema.containedViewmodels() {
          if done.insert(nested).inserted {
            queue.append(nested)
          }
        }
      }
    }

    for name in usedEnumNames {
      let e = allEnums[name]!
      let generated = e.generate()

      try emit(
        filename: "\(name).swift",
        contents: generated,
        write: write,
        outputDir: outputDir,
        force: force
      )
    }
  }

  func emit(
    filename: String,
    contents: String,
    write: Bool,
    outputDir: String?,
    force: Bool
  ) throws {
    let fm = FileManager.default

    if write {
      let outPath = outputDir.map { "\($0)/\(filename)" } ?? filename
      if force || !fm.fileExists(atPath: outPath) {
        printInfo("Writing to \(outPath)")
        try contents.write(toFile: outPath, atomically: true, encoding: .utf8)
      } else {
        printInfo("Skipping \(outPath)")
      }
    } else {
      printCode(contents)
    }
  }
}

/// Adds markers so that write commands can strip out debug messages and just write code.
func printInfo(_ message: String) {
  print("[INFO] \(message) [/INFO]")
}
/// Just a wrapper to make things clear and facilitate future refactoring.
func printCode(_ code: String) {
  print(code)
}
