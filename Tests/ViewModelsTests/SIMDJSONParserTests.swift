//
//  SIMDJSONParserTests.swift
//  ViewModels
//
//  Created by Andrew Childs on 2024/11/20.
//

import Testing
import ViewModels

struct SIMDJSONParserTests {
  @Test func testNoValueError() throws {
    #expect(throws: ParserError.noValue(key: "bar", location: "test/0")) {
      try parse(
        """
        {"test":[{"foo": 42}]}
        """
      ) { parser in
        try parser.descend(into: "test").parseArray(of: Int.self) { parser in
          try parser.fetch(key: "bar", type: Int.self)
        }
      }
    }
  }

  @Test func testTypeMismatchNumberInsteadOfString() throws {
    #expect(throws: ParserError.error(description: "Expected to decode PKc but found Number instead.", location: "test")) {
      try parse(
        """
        {"test":42}
        """
      ) { parser in
        try parser.fetch(key: "test", type: String.self)
      }
    }
  }

  @Test func testTypeMismatchStringInsteadOfNumber() throws {
    #expect(throws: ParserError.error(description: "Expected Int.", location: "test")) {
      try parse(
        """
        {"test":"forty two"}
        """
      ) { parser in
        try parser.fetch(key: "test", type: Int.self)
      }
    }
  }

  private func parse<T>(_ json: String, body: (any ViewModelParser) throws -> T) throws -> T {
    let data = try #require(json.data(using: .utf8))
    return try SIMDJSONParser.with(data: data, body: body)
  }
}
