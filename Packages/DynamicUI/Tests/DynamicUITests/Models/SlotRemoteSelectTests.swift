import Testing
import Foundation
import EduModels
@testable import EduDynamicUI

@Suite("Slot Remote Select Tests")
struct SlotRemoteSelectTests {

    // MARK: - Slot decoding with remote select properties

    @Test("Slot decodes options_endpoint, option_label, option_value")
    func decodeSlotWithRemoteSelectProperties() throws {
        let json = """
        {
            "id": "slot-school",
            "controlType": "remote_select",
            "field": "school_id",
            "label": "Escuela",
            "options_endpoint": "admin:/api/v1/schools",
            "option_label": "name",
            "option_value": "id"
        }
        """.data(using: .utf8)!

        let slot = try JSONDecoder().decode(Slot.self, from: json)

        #expect(slot.id == "slot-school")
        #expect(slot.controlType == .remoteSelect)
        #expect(slot.field == "school_id")
        #expect(slot.label == "Escuela")
        #expect(slot.optionsEndpoint == "admin:/api/v1/schools")
        #expect(slot.optionLabel == "name")
        #expect(slot.optionValue == "id")
    }

    @Test("Slot decodes without remote select properties (backward compatible)")
    func decodeSlotWithoutRemoteProperties() throws {
        let json = """
        {
            "id": "slot-name",
            "controlType": "text-input",
            "field": "name",
            "label": "Nombre"
        }
        """.data(using: .utf8)!

        let slot = try JSONDecoder().decode(Slot.self, from: json)

        #expect(slot.controlType == .textInput)
        #expect(slot.optionsEndpoint == nil)
        #expect(slot.optionLabel == nil)
        #expect(slot.optionValue == nil)
    }

    @Test("Slot remote_select without options_endpoint is valid but has nil endpoint")
    func decodeRemoteSelectWithoutEndpoint() throws {
        let json = """
        {
            "id": "slot-fallback",
            "controlType": "remote_select",
            "label": "Tipo",
            "value": ["A", "B", "C"]
        }
        """.data(using: .utf8)!

        let slot = try JSONDecoder().decode(Slot.self, from: json)

        #expect(slot.controlType == .remoteSelect)
        #expect(slot.optionsEndpoint == nil)
        #expect(slot.value != nil)
    }

    // MARK: - SlotOption

    @Test("SlotOption encodes and decodes correctly")
    func slotOptionCodable() throws {
        let option = SlotOption(label: "Escuela ABC", value: "school-123")
        let data = try JSONEncoder().encode(option)
        let decoded = try JSONDecoder().decode(SlotOption.self, from: data)

        #expect(decoded.label == "Escuela ABC")
        #expect(decoded.value == "school-123")
    }

    @Test("SlotOption is Hashable")
    func slotOptionHashable() {
        let a = SlotOption(label: "A", value: "1")
        let b = SlotOption(label: "A", value: "1")
        let c = SlotOption(label: "B", value: "2")

        #expect(a == b)
        #expect(a != c)

        let set: Set<SlotOption> = [a, b, c]
        #expect(set.count == 2)
    }

    // MARK: - SelectOptionsState

    @Test("SelectOptionsState loading state")
    func selectOptionsLoading() {
        let state = SelectOptionsState.loading
        if case .loading = state {
            // Expected
        } else {
            Issue.record("Expected .loading")
        }
    }

    @Test("SelectOptionsState success with options")
    func selectOptionsSuccess() {
        let options = [
            SlotOption(label: "A", value: "1"),
            SlotOption(label: "B", value: "2"),
        ]
        let state = SelectOptionsState.success(options: options)
        if case .success(let loaded) = state {
            #expect(loaded.count == 2)
            #expect(loaded[0].label == "A")
        } else {
            Issue.record("Expected .success")
        }
    }

    @Test("SelectOptionsState error with message")
    func selectOptionsError() {
        let state = SelectOptionsState.error(message: "Network failed")
        if case .error(let msg) = state {
            #expect(msg == "Network failed")
        } else {
            Issue.record("Expected .error")
        }
    }

    // MARK: - Full screen with remote_select slot

    @Test("ScreenDefinition with remote_select slot decodes correctly")
    func screenWithRemoteSelect() throws {
        let json = """
        {
            "screenId": "scr-form",
            "screenKey": "create_user",
            "screenName": "Crear Usuario",
            "pattern": "form",
            "version": 1,
            "template": {
                "zones": [
                    {
                        "id": "zone-fields",
                        "type": "form-section",
                        "slots": [
                            {
                                "id": "slot-name",
                                "controlType": "text-input",
                                "field": "name",
                                "label": "Nombre"
                            },
                            {
                                "id": "slot-school",
                                "controlType": "remote_select",
                                "field": "school_id",
                                "label": "Escuela",
                                "options_endpoint": "admin:/api/v1/schools",
                                "option_label": "name",
                                "option_value": "id",
                                "required": true
                            }
                        ]
                    }
                ]
            },
            "actions": [],
            "updatedAt": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: json)
        let zone = screen.template.zones[0]
        #expect(zone.slots?.count == 2)

        let remoteSlot = zone.slots![1]
        #expect(remoteSlot.controlType == .remoteSelect)
        #expect(remoteSlot.optionsEndpoint == "admin:/api/v1/schools")
        #expect(remoteSlot.optionLabel == "name")
        #expect(remoteSlot.optionValue == "id")
        #expect(remoteSlot.required == true)
    }
}
