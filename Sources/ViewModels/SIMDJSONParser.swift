//
//  SIMDJSONParser.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/18.
//

import ZippyJSONCFamily

// A wrapper around json to make parsing easier
public struct SIMDJSONParser: ViewModelParser {
  @usableFromInline
  typealias Value = JNTDecoder

  @usableFromInline
  let value: Value

  init(value: Value) {
    self.value = value
  }

  private func checkError() throws {
    if JNTDocumentErrorDidOccur(value) {
      var errorInfo = JNTErrorInfo()
      JNTGetErrorInfo(JNTGetContext(value), &errorInfo)
      let description = String(utf8String: errorInfo.description)!

      JNTClearError(JNTGetContext(value))
      throw ParserError.error(description: description, location: location(of: value))
    }
  }

  private func location(of: Value) -> String {
    let array = JNTDocumentCodingPath(value)
    let pathString = array?.compactMap { value in
      switch value {
      case let number as NSNumber:
        return "\(number)"
      case let string as NSString:
        return string as String
      default:
        assertionFailure("Unexpected key path element")
        return nil as String?
      }
    }.joined(separator: "/")
    return pathString ?? "unknown"
  }

  // Primitive unboxing of focused value
  public func unbox(type: String.Type) throws -> String {
    let result = JNTDocumentDecode__String(value)
    try checkError()
    guard let result, let str = String(utf8String: result) else {
      throw ParserError.error(description: "String decode failed", location: location(of: value))
    }
    return str
  }

  public func unbox(type: Int.Type) throws -> Int {
    guard JNTDocumentValueIsInteger(value) else {
      throw ParserError.error(description: "Expected Int.", location: location(of: value))
    }
    let result = JNTDocumentDecode__Int(value)
    try checkError()
    return result
  }

  public func unbox(type: Double.Type) throws -> Double {
    guard JNTDocumentValueIsDouble(value) else {
      throw ParserError.error(description: "Expected Double.", location: location(of: value))
    }
    let result = JNTDocumentDecode__Double(value)
    try checkError()
    return result
  }

  public func unbox(type: Bool.Type) throws -> Bool {
    let result = JNTDocumentDecode__Bool(value)
    try checkError()
    return result
  }

  public var isNull: Bool {
    JNTDocumentDecodeNil(value)
  }

  // Refocus on key, if present and not null
  public func maybeDescend(into key: String) throws -> Self? {
    guard JNTDocumentValueIsDictionary(value) else {
      throw ParserError.error(description: "Expected Dictionary.", location: location(of: value))
    }
    var iterator = JNTDocumentGetDictionaryIterator(value)
    let result: Value? = try key.withCString { (pkey: UnsafePointer<CChar>) throws -> Value? in
      guard JNTDocumentContains(value, pkey, &iterator) else {
        return nil
      }

      let result = JNTDocumentFetchValue(value, pkey, &iterator)
      try checkError()

      return result
    }

    return result.map { Self(value: $0) }
  }

  // Refocus on key if present
  public func descend(into key: String) throws -> Self {
    guard let child = try maybeDescend(into: key) else {
      throw ParserError.noValue(key: key, location: location(of: value))
    }
    return child
  }

  // Exhaustively decode an array
  public func parseArray<T>(
    of: T.Type,
    parse: (Self) throws -> T
  ) throws -> [T] {
    guard JNTDocumentValueIsArray(value) else {
      throw ParserError.error(description: "Expected Array.", location: location(of: value))
    }
    var iterator = JNTDocumentGetIterator(value)
    let count = JNTDocumentGetArrayCount(value)
    var result: [T] = []
    for _ in 0..<count {
      let elementValue = JNTDecoderFromIterator(&iterator, value)
      let child = Self(value: elementValue)
      try result.append(parse(child))
      JNTAdvanceIterator(&iterator, value)
    }
    return result
  }

  public func enumerateObject(parse: (String, SIMDJSONParser) throws -> Void) throws {
    guard JNTDocumentValueIsDictionary(value) else {
      throw ParserError.error(description: "Expected Dictionary.", location: location(of: value))
    }

    // We can't throw from the C++ function, so we sidechannel out any error(s).
    var innerError: Error?

    withoutActuallyEscaping(parse) { escapingParse in
      JNTDocumentForAllKeyValuePairs(value) { key, value in
        let keyString = String(cString: key!)
        do {
          try escapingParse(keyString, .init(value: value))
        } catch {
          innerError = error
        }
      }
    }

    if let innerError { throw innerError }

    try checkError()
  }

  public static func with<T>(data: Data, body: (ViewModelParser) throws -> T) throws -> T {
    try data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> T in
      guard let baseAddress = bytes.baseAddress else { throw ParserError.error(description: "Missing baseAddress of Data", location: nil) }
      let string = baseAddress.assumingMemoryBound(to: Int8.self)
      let context = JNTCreateContext(string, UInt32(data.count), "", "", "", false)
      defer {
        JNTReleaseContext(context)
      }
      var success = false
      var retryReason: UnsafePointer<CChar>? = nil
      let value = JNTDocumentFromJSON(context, baseAddress, data.count, false, &retryReason, &success)
      if success {
        let parser = SIMDJSONParser(value: value)
        return try body(parser)
      } else {
        // If we couldn't get a document instance, we fall back to the
        // old slow parser.  This could be caused by malformed JSON,
        // non-ASCII keys, or other cases that simdjson doesn't
        // support.
        return try JSONObjectParser.with(data: data, body: body)
      }
    }
  }
}
