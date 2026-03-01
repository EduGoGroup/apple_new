import Testing
import Foundation
import EduModels
@testable import EduDynamicUI

@Suite("Unknown Enum Forward Compatibility Tests")
struct UnknownEnumTests {

    // MARK: - ScreenPattern Unknown

    @Test("Unknown screen pattern decodes and preserves raw value")
    func unknownScreenPatternDecodes() throws {
        let json = "\"kanban-board\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ScreenPattern.self, from: json)
        #expect(decoded == .unknown("kanban-board"))
        #expect(decoded.rawValue == "kanban-board")
    }

    @Test("ScreenPattern unknown roundtrips through encode/decode")
    func screenPatternUnknownRoundtrip() throws {
        let original = ScreenPattern.unknown("timeline-view")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ScreenPattern.self, from: data)
        #expect(decoded == original)
    }

    @Test("ScreenPattern allCases does not include unknown")
    func screenPatternAllCases() {
        #expect(ScreenPattern.allCases.count == 12)
        for c in ScreenPattern.allCases {
            if case .unknown = c {
                Issue.record("allCases should not contain .unknown")
            }
        }
    }

    // MARK: - ActionType Unknown

    @Test("Unknown action type decodes and preserves raw value")
    func unknownActionTypeDecodes() throws {
        let json = "\"DEEP_LINK\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ActionType.self, from: json)
        #expect(decoded == .unknown("DEEP_LINK"))
    }

    @Test("ActionType unknown roundtrips through encode/decode")
    func actionTypeUnknownRoundtrip() throws {
        let original = ActionType.unknown("SHARE")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ActionType.self, from: data)
        #expect(decoded == original)
    }

    @Test("Known action types still decode correctly")
    func knownActionTypes() throws {
        let cases: [(String, ActionType)] = [
            ("NAVIGATE", .navigate),
            ("NAVIGATE_BACK", .navigateBack),
            ("API_CALL", .apiCall),
            ("SUBMIT_FORM", .submitForm),
            ("LOGOUT", .logout),
        ]
        for (raw, expected) in cases {
            let json = "\"\(raw)\"".data(using: .utf8)!
            let decoded = try JSONDecoder().decode(ActionType.self, from: json)
            #expect(decoded == expected)
        }
    }

    // MARK: - ActionTrigger Unknown

    @Test("Unknown action trigger decodes and preserves raw value")
    func unknownActionTriggerDecodes() throws {
        let json = "\"double_tap\"".data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ActionTrigger.self, from: json)
        #expect(decoded == .unknown("double_tap"))
    }

    @Test("ActionTrigger unknown roundtrips through encode/decode")
    func actionTriggerUnknownRoundtrip() throws {
        let original = ActionTrigger.unknown("force_touch")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ActionTrigger.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - Full ScreenDefinition with Unknown Types

    @Test("ScreenDefinition decodes with unknown pattern and control type")
    func screenDefinitionWithUnknowns() throws {
        let json = """
        {
            "screenId": "scr-future",
            "screenKey": "future_screen",
            "screenName": "Future Screen",
            "pattern": "kanban-board",
            "version": 1,
            "template": {
                "zones": [
                    {
                        "id": "zone-1",
                        "type": "container",
                        "slots": [
                            {
                                "id": "slot-1",
                                "controlType": "color-picker",
                                "label": "Pick a color"
                            }
                        ]
                    }
                ]
            },
            "actions": [
                {
                    "id": "act-1",
                    "trigger": "voice_command",
                    "type": "DEEP_LINK",
                    "config": {}
                }
            ],
            "updatedAt": "2026-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: json)
        #expect(screen.pattern == .unknown("kanban-board"))
        #expect(screen.template.zones[0].slots?[0].controlType == .unknown("color-picker"))
        #expect(screen.actions[0].trigger == .unknown("voice_command"))
        #expect(screen.actions[0].type == .unknown("DEEP_LINK"))
    }
}
