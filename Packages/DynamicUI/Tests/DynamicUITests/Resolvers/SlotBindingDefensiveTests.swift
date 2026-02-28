import Testing
import Foundation
import EduModels
@testable import EduDynamicUI

@Suite("SlotBindingResolver Defensive Tests")
struct SlotBindingDefensiveTests {

    let resolver = SlotBindingResolver()

    // MARK: - Helpers

    private func makeSlot(
        id: String = "test-slot",
        field: String? = nil,
        bind: String? = nil,
        value: JSONValue? = nil
    ) throws -> Slot {
        var json: [String: Any] = [
            "id": id,
            "controlType": "label"
        ]
        if let field { json["field"] = field }
        if let bind { json["bind"] = bind }
        let jsonData = try JSONSerialization.data(withJSONObject: json)

        if let value {
            var dict = try JSONDecoder().decode([String: JSONValue].self, from: jsonData)
            dict["value"] = value
            let fullData = try JSONEncoder().encode(dict)
            return try JSONDecoder().decode(Slot.self, from: fullData)
        }

        return try JSONDecoder().decode(Slot.self, from: jsonData)
    }

    // MARK: - Defensive Behavior Tests

    @Test("resolve returns nil gracefully with all nil inputs")
    func resolveAllNilInputs() throws {
        let slot = try makeSlot()
        let result = resolver.resolve(slot: slot, data: nil, slotData: nil)
        #expect(result == nil)
    }

    @Test("resolve returns nil with empty data dictionaries")
    func resolveEmptyDictionaries() throws {
        let slot = try makeSlot(field: "missing")
        let result = resolver.resolve(slot: slot, data: [:], slotData: [:])
        #expect(result == nil)
    }

    @Test("resolve handles null JSONValue in data")
    func resolveNullValue() throws {
        let slot = try makeSlot(field: "nullField")
        let data: [String: JSONValue] = ["nullField": .null]
        let result = resolver.resolve(slot: slot, data: data, slotData: nil)
        #expect(result == .null)
    }

    @Test("resolve returns fallback value when field not in data")
    func resolveFallbackToValue() throws {
        let slot = try makeSlot(field: "missing", value: .string("fallback"))
        let result = resolver.resolve(slot: slot, data: [:], slotData: nil)
        #expect(result == .string("fallback"))
    }

    @Test("resolve handles deeply nested object values")
    func resolveNestedObject() throws {
        let slot = try makeSlot(field: "nested")
        let nestedValue: JSONValue = .object([
            "inner": .object(["deep": .string("value")])
        ])
        let data: [String: JSONValue] = ["nested": nestedValue]
        let result = resolver.resolve(slot: slot, data: data, slotData: nil)
        #expect(result == nestedValue)
    }

    @Test("resolve handles empty string bind prefix gracefully")
    func resolveEmptyBind() throws {
        let slot = try makeSlot(bind: "", value: .string("literal"))
        let result = resolver.resolve(slot: slot, data: nil, slotData: ["": .string("should not match")])
        #expect(result == .string("literal"))
    }

    @Test("resolve handles bind with slot: prefix but missing key in slotData")
    func resolveBindMissingKey() throws {
        let slot = try makeSlot(bind: "slot:missing", value: .string("literal"))
        let slotData: [String: JSONValue] = ["other": .string("x")]
        let result = resolver.resolve(slot: slot, data: nil, slotData: slotData)
        #expect(result == .string("literal"))
    }
}
