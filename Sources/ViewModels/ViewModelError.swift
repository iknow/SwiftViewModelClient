import Foundation
import os

// MARK: - Core error types

public protocol ViewModelError: Error {
  var status: Int { get }
  var title: String? { get }
  var detail: String { get }
  var code: String { get }
}

/// Application defined errors should inherit from this
open class ViewModelErrorBase: ViewModelError, CustomDebugStringConvertible {
  public let status: Int
  public let title: String?
  public let detail: String
  public let code: String

  public init(status: Int, title: String?, detail: String, code: String) {
    self.status = status
    self.title = title
    self.detail = detail
    self.code = code
  }

  public var debugDescription: String {
    "\(Self.self)(code=\(code) status=\(status)): [\(title ?? "No title")] \(detail)"
  }
}

// MARK: - Error code dispatch

// TODO: this might need locking around the registry
/// A place to put application defined error handlers
public enum ViewModelErrorRegistry {
  public static let typeName = "Error"

  private struct DefaultParser: ViewModelErrorParser {
    func newError(status: Int, title: String?, detail: String, code: String, parser: ViewModelParser) throws -> any ViewModelError {
      ViewModelErrorBase(status: status, title: title, detail: detail, code: code)
    }
  }

  private static var parsers = OSAllocatedUnfairLock<[String: any ViewModelErrorParser]>(initialState: [:])

  private static func parserForCode(code: String) -> any ViewModelErrorParser {
    if let parser = parsers.withLock({ $0[code] }) {
      return parser
    }

    return DefaultParser()
  }

  public static func register(_ parser: any ViewModelErrorParser, for codes: [String]) {
    parsers.withLock {
      for code in codes {
        $0[code] = parser
      }
    }
  }

  public static func register<Code>(_ parser: any ViewModelErrorParser, for codes: [Code])
    where Code: RawRepresentable, Code.RawValue == String
  {
    parsers.withLock {
      for code in codes {
        $0[code.rawValue] = parser
      }
    }
  }

  public static func deserialize(json: Data) -> Error? {
    // TODO: make a Decoder instead?
    try? SIMDJSONParser.with(data: json) { parser in
      let vmparser = try parser.descend(into: "error")

      let status = try vmparser.fetch(key: "status", type: Int.self)
      let title = try vmparser.maybeFetch(key: "title", type: String.self)
      let detail = try vmparser.fetch(key: "detail", type: String.self)
      let code = try vmparser.fetch(key: "code", type: String.self)

      let errorParser = parserForCode(code: code)
      return try errorParser.newError(status: status, title: title, detail: detail, code: code, parser: vmparser)
    }
  }
}

public protocol ViewModelErrorParser: Sendable {
  func newError(status: Int, title: String?, detail: String, code: String, parser: ViewModelParser) throws -> any ViewModelError
}
