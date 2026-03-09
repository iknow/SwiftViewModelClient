//
//  ViewModelParserTests.swift
//  ViewModels
//
//  Created by Andrew Childs on 2025/02/04.
//

import Testing
import ViewModels

@Suite
struct ViewModelParserTests {
  @Test func testSimpleObjectParse() throws {
    try parse(
      """
      {"a":1, "b":2}
      """
    ) { parser in
      let decoded = try #require(
        try parser.parseDictionary(of: Int.self, parse: { subparser in
          try subparser.unbox(type: Int.self)
        })
      )
      #expect(decoded == ["a": 1, "b": 2])
    }
  }

  /// Run a test on both parser types
  private func parse(_ json: String, body: (any ViewModelParser) throws -> Void) throws {
    let data = try #require(json.data(using: .utf8))
    try SIMDJSONParser.with(data: data, body: body)
    try JSONObjectParser.with(data: data, body: body)
  }
}
