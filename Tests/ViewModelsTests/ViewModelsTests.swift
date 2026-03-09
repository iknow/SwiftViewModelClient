import Foundation
import os
import Testing
import TestModels
@testable import ViewModels

@Suite
final class ViewModelsTests {
  func loadJson(name: String) throws -> Data {
    try TestModelResources.loadJson(name: name)
  }

  @Test
  func testParseCategories() throws {
    let bytes = try loadJson(name: "categories")
    let result = try ViewModel.deserialize(json: bytes, type: [RolePlayCategory].self)
    let first = result.first!
    #expect(first.id == UUID(uuidString: "06AF37EC-2F54-0684-8A75-E47D88A002CA")!)
  }

  @Test
  func testParseScenarios() throws {
    let bytes = try loadJson(name: "scenarios")
    let result = try ViewModel.deserialize(json: bytes, type: [RolePlayScenario].self)
    let first = result.first!
    #expect(first.id == UUID(uuidString: "7562A491-F702-0ADF-65FA-4EF0F40CA112")!)
  }

  @Test
  func testParseConversation() throws {
    let bytes = try loadJson(name: "conversation")
    let result = try ViewModel.deserialize(json: bytes, type: RolePlayConversation.self)
    #expect(result.id == UUID(uuidString: "1CEA976E-238F-11EE-AC1A-5B1D41839835")!)
  }

  @Test
  func testNestedVersions() throws {
    let versions = RolePlayConversation.nestedVersions()
    #expect(versions == [
      "RolePlay.ConversationExchange": RolePlayConversationExchange.version,
      "OrganizationReference": OrganizationReference.version,
      "Image": RemoteImage.version,
      "TextTranslation": TextTranslation.version,
      "RolePlay.Conversation": RolePlayConversation.version,
      "RolePlay.Scenario": RolePlayScenario.version,
      "Text": LocalizableText.version,
    ])
  }

  @Test
  func testIdsAreDifferent() throws {
    let user1 = RolePlayCategory()
    let user2 = RolePlayCategory()
    #expect(user1.id != user2.id)
  }

  @Test
  func testArrayDirty() throws {
    let bytes = try loadJson(name: "conversation")
    let conversation = try ViewModel.deserialize(json: bytes, type: RolePlayConversation.self)
    conversation.exchanges.append(RolePlayConversationExchange())
    #expect(conversation.$exchanges.isDirty())
  }

  @Test
  func testReferencesIdentical() throws {
    let bytes = try loadJson(name: "scenarios")
    let result = try ViewModel.deserialize(json: bytes, type: [RolePlayScenario].self)
    let first = result[0]
    let second = result[1]

    #expect(first.owner === second.owner)
  }

  @Test
  func testNewDirty() throws {
    let scenario = RolePlayScenario()
    #expect(scenario.$id.isDirty())
  }

  @Test
  func testSerializeNew() throws {
    let json = try RolePlayConversation().serialize()
    print(String(data: json, encoding: .utf8)!)
    // TODO: actually check conditions
  }

  @Test
  func testSerializeAttributes() throws {
    let conversation = RolePlayConversation()

    conversation.assistantGreeting = "hello, world"
    conversation.saved()
    conversation.assistantGreeting = "woot"
    conversation.exchanges.append(RolePlayConversationExchange())

    let json = try conversation.serialize()

    print(String(data: json, encoding: .utf8)!)
    // TODO: actually check conditions
  }

  @Test
  func testNewWithoutId() throws {
    let conversation = RolePlayConversation(isNew: true, defaultValues: false)
    let json = try conversation.serialize()
    print(String(data: json, encoding: .utf8)!)
    // TODO: actually check conditions
  }

  @Test
  func testUpdateWithoutId() throws {
    let conversation = RolePlayConversation(isNew: false, defaultValues: false)

    #expect(throws: SerializeError.valueMissing(typeName: "RolePlay.Conversation", name: "id"), performing: {
      try conversation.serialize()
    })
  }

  enum Dates {
    enum JSON {
      static let withValues = """
        { "data":
          {
             "_type": "Model",
             "_version": 1,
             "seconds_precision_date": "2023-08-24T17:01:02Z",
             "milliseconds_precision_date": "2023-08-24T17:01:02.456Z"
          }
        }
      """.data(using: .utf8)!

      static let withoutValues = """
        { "data":
          {
             "_type": "Model",
             "_version": 1,
             "seconds_precision_date": null,
             "milliseconds_precision_date": null
          }
        }
      """.data(using: .utf8)!
    }
  }

  @Test
  func testDateParsing() throws {
    let m = try DateModel.deserialize(from: Dates.JSON.withValues)
    #expect(m.secondsPrecisionDate == Date(timeIntervalSince1970: 1_692_896_462))
    #expect(m.millisecondsPrecisionDate == Date(timeIntervalSince1970: 1_692_896_462.456))
  }

  @Test
  func testOptionalDateParsingPresent() throws {
    let m = try OptionalDateModel.deserialize(from: Dates.JSON.withValues)
    #expect(m.secondsPrecisionDate == Date(timeIntervalSince1970: 1_692_896_462))
    #expect(m.millisecondsPrecisionDate == Date(timeIntervalSince1970: 1_692_896_462.456))
  }

  @Test
  func testOptionalDateParsingAbsent() throws {
    let m = try OptionalDateModel.deserialize(from: Dates.JSON.withoutValues)
    #expect(m.secondsPrecisionDate == nil)
    #expect(m.millisecondsPrecisionDate == nil)
  }

  @Test
  func testPropertyChanged() throws {
    let scenario = RolePlayScenario()
    scenario.$enabled.saved(value: false)

    let updated = OSAllocatedUnfairLock(initialState: false)

    // Direct writes must be visible
    withObservationTracking {
      _ = scenario.enabled
    } onChange: {
      updated.withLock { $0 = true }
    }
    scenario.enabled.toggle()
    #expect(updated.withLock { $0 })

    // Writes via the projected value must be visible to value readers
    updated.withLock { $0 = false }
    withObservationTracking {
      _ = scenario.enabled
    } onChange: {
      updated.withLock { $0 = true }
    }
    scenario.$enabled.discardChanges()
    #expect(updated.withLock { $0 })

    // Writes via the value must be visible to projected value readers
    updated.withLock { $0 = false }
    withObservationTracking {
      _ = scenario.$enabled.isDirty()
    } onChange: {
      updated.withLock { $0 = true }
    }
    scenario.enabled.toggle()
    #expect(updated.withLock { $0 })

    // Transient properties must be visible
    updated.withLock { $0 = false }
    withObservationTracking {
      _ = scenario.complete
    } onChange: {
      updated.withLock { $0 = true }
    }
    scenario.complete.toggle()
    #expect(updated.withLock { $0 })
  }

  @Test
  func testVariant() throws {
    var versions: [String: Int] = [:]
    RolePlayScenario.nestedVersions(into: &versions)
    RolePlayConversation.nestedVersions(into: &versions)
    #expect(SomeVariant.nestedVersions() == versions)
  }
}

@ViewModel
class DateModel: ViewModel {
  override class var typeName: String { "Model" }
  @Attribute(name: "seconds_precision_date") var secondsPrecisionDate: Date
  @Attribute(name: "milliseconds_precision_date", format: AccurateTimeFormat()) var millisecondsPrecisionDate: Date
}

@ViewModel
class OptionalDateModel: ViewModel {
  override class var typeName: String { "Model" }
  @Attribute(name: "seconds_precision_date") var secondsPrecisionDate: Date?
  @Attribute(name: "milliseconds_precision_date", format: AccurateTimeFormat().optional()) var millisecondsPrecisionDate: Date?
}

@ViewModelVariant
enum SomeVariant {
  case scenario(RolePlayScenario)
  case conversation(RolePlayConversation)
}
