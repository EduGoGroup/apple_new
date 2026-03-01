import Testing
import Foundation
@testable import EduDynamicUI

@Suite("ControlType Tests")
struct ControlTypeTests {

    @Test("remoteSelect raw value is remote_select")
    func remoteSelectRawValue() {
        #expect(ControlType.remoteSelect.rawValue == "remote_select")
    }

    @Test("remoteSelect decodes from JSON string")
    func remoteSelectDecode() throws {
        let json = "\"remote_select\"".data(using: .utf8)!
        let controlType = try JSONDecoder().decode(ControlType.self, from: json)
        #expect(controlType == .remoteSelect)
    }

    @Test("remoteSelect encodes to JSON string")
    func remoteSelectEncode() throws {
        let data = try JSONEncoder().encode(ControlType.remoteSelect)
        let str = String(data: data, encoding: .utf8)
        #expect(str == "\"remote_select\"")
    }

    @Test("all existing control types still decode correctly")
    func existingControlTypes() throws {
        let cases: [(String, ControlType)] = [
            ("text-input", .textInput),
            ("email-input", .emailInput),
            ("select", .select),
            ("filled-button", .filledButton),
            ("metric-card", .metricCard),
            ("list-item-navigation", .listItemNavigation),
            ("remote_select", .remoteSelect),
        ]

        for (rawValue, expected) in cases {
            let json = "\"\(rawValue)\"".data(using: .utf8)!
            let decoded = try JSONDecoder().decode(ControlType.self, from: json)
            #expect(decoded == expected, "Expected \(expected) for raw value \(rawValue)")
        }
    }

    // MARK: - Unknown Case Tests

    @Test("unknown control type decodes to .unknown with raw value preserved")
    func unknownControlTypeDecodes() throws {
        let json = "\"fancy-slider\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ControlType.self, from: json)
        #expect(decoded == .unknown("fancy-slider"))
        #expect(decoded.rawValue == "fancy-slider")
    }

    @Test("unknown control type roundtrips through encode/decode")
    func unknownRoundtrip() throws {
        let original = ControlType.unknown("custom-widget")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ControlType.self, from: data)
        #expect(decoded == original)
    }

    @Test("unknown control type is Hashable")
    func unknownHashable() {
        let set: Set<ControlType> = [.textInput, .unknown("x"), .unknown("y"), .unknown("x")]
        #expect(set.count == 3)
    }
}
