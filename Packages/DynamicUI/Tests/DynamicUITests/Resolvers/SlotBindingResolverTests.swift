import Testing
import Foundation
import EduModels
@testable import EduDynamicUI

@Suite("SlotBindingResolver Tests")
struct SlotBindingResolverTests {

    let resolver = SlotBindingResolver()

    // MARK: - Helpers

    private func makeSlot(
        field: String? = nil,
        bind: String? = nil,
        value: JSONValue? = nil
    ) throws -> Slot {
        var json: [String: Any] = [
            "id": "test-slot",
            "controlType": "label"
        ]
        if let field { json["field"] = field }
        if let bind { json["bind"] = bind }
        // value needs special handling via full JSON
        let jsonData = try JSONSerialization.data(withJSONObject: json)

        if let value {
            // Re-encode with value
            var dict = try JSONDecoder().decode([String: JSONValue].self, from: jsonData)
            dict["value"] = value
            let fullData = try JSONEncoder().encode(dict)
            return try JSONDecoder().decode(Slot.self, from: fullData)
        }

        return try JSONDecoder().decode(Slot.self, from: jsonData)
    }

    // MARK: - Priority Tests

    @Test("Priority 1: field resolves from data dictionary")
    func fieldResolvesFromData() throws {
        let slot = try makeSlot(field: "userName")
        let data: [String: JSONValue] = ["userName": .string("Juan")]

        let result = resolver.resolve(slot: slot, data: data, slotData: nil)
        #expect(result == .string("Juan"))
    }

    @Test("Priority 2: bind slot:key resolves from slotData")
    func bindResolvesFromSlotData() throws {
        let slot = try makeSlot(bind: "slot:welcomeMessage")
        let slotData: [String: JSONValue] = ["welcomeMessage": .string("Bienvenido")]

        let result = resolver.resolve(slot: slot, data: nil, slotData: slotData)
        #expect(result == .string("Bienvenido"))
    }

    @Test("Priority 3: literal value from slot definition")
    func literalValueResolves() throws {
        let slot = try makeSlot(value: .string("Default Label"))

        let result = resolver.resolve(slot: slot, data: nil, slotData: nil)
        #expect(result == .string("Default Label"))
    }

    @Test("Field has higher priority than bind")
    func fieldOverridesBind() throws {
        let slot = try makeSlot(field: "name", bind: "slot:name")
        let data: [String: JSONValue] = ["name": .string("From Data")]
        let slotData: [String: JSONValue] = ["name": .string("From SlotData")]

        let result = resolver.resolve(slot: slot, data: data, slotData: slotData)
        #expect(result == .string("From Data"))
    }

    @Test("Bind has higher priority than literal value")
    func bindOverridesValue() throws {
        let slot = try makeSlot(bind: "slot:title", value: .string("Literal"))
        let slotData: [String: JSONValue] = ["title": .string("From SlotData")]

        let result = resolver.resolve(slot: slot, data: nil, slotData: slotData)
        #expect(result == .string("From SlotData"))
    }

    @Test("Falls back to bind when field not found in data")
    func fallbackFromFieldToBind() throws {
        let slot = try makeSlot(field: "missing", bind: "slot:title")
        let data: [String: JSONValue] = ["other": .string("X")]
        let slotData: [String: JSONValue] = ["title": .string("Fallback")]

        let result = resolver.resolve(slot: slot, data: data, slotData: slotData)
        #expect(result == .string("Fallback"))
    }

    @Test("Returns nil when no source resolves")
    func returnsNilWhenNothingResolves() throws {
        let slot = try makeSlot(field: "missing")
        let result = resolver.resolve(slot: slot, data: [:], slotData: nil)
        #expect(result == nil)
    }

    @Test("Non slot: bind prefix is ignored")
    func nonSlotBindIgnored() throws {
        let slot = try makeSlot(bind: "other:key", value: .string("Literal"))
        let slotData: [String: JSONValue] = ["key": .string("Should Not Use")]

        let result = resolver.resolve(slot: slot, data: nil, slotData: slotData)
        #expect(result == .string("Literal"))
    }

    @Test("Resolves integer values from data")
    func resolvesIntegerValues() throws {
        let slot = try makeSlot(field: "count")
        let data: [String: JSONValue] = ["count": .integer(42)]

        let result = resolver.resolve(slot: slot, data: data, slotData: nil)
        #expect(result == .integer(42))
    }
}
