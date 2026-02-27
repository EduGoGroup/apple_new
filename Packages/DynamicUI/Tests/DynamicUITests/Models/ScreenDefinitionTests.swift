import Testing
import Foundation
import EduModels
@testable import EduDynamicUI

@Suite("ScreenDefinition Decoding Tests")
struct ScreenDefinitionTests {

    // MARK: - Test JSON Fixture

    static let screenJSON = """
    {
        "screenId": "scr-001",
        "screenKey": "home_dashboard",
        "screenName": "Dashboard Principal",
        "pattern": "dashboard",
        "version": 2,
        "template": {
            "navigation": {
                "topBar": {
                    "title": "Bienvenido, {user.firstName}",
                    "showBack": false
                }
            },
            "zones": [
                {
                    "id": "zone-metrics",
                    "type": "metric-grid",
                    "distribution": "grid",
                    "slots": [
                        {
                            "id": "slot-students",
                            "controlType": "metric-card",
                            "field": "totalStudents",
                            "label": "Estudiantes",
                            "icon": "person.2.fill"
                        }
                    ]
                },
                {
                    "id": "zone-actions",
                    "type": "action-group",
                    "distribution": "flow-row",
                    "slots": [
                        {
                            "id": "slot-btn-create",
                            "controlType": "filled-button",
                            "label": "Crear Clase",
                            "icon": "plus.circle.fill",
                            "value": "create"
                        }
                    ]
                }
            ]
        },
        "slotData": {
            "welcomeMessage": "Hola Mundo"
        },
        "dataEndpoint": "mobile:/api/v1/dashboard/metrics",
        "dataConfig": {
            "defaultParams": {
                "role": "teacher"
            },
            "refreshInterval": 300
        },
        "actions": [
            {
                "id": "action-create-class",
                "trigger": "button_click",
                "triggerSlotId": "slot-btn-create",
                "type": "NAVIGATE",
                "config": {
                    "target": "create_class"
                }
            }
        ],
        "handlerKey": "dashboard_handler",
        "updatedAt": "2025-01-15T10:30:00Z"
    }
    """.data(using: .utf8)!

    @Test("Decodes full ScreenDefinition from JSON")
    func decodeScreenDefinition() throws {
        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: Self.screenJSON)

        #expect(screen.screenId == "scr-001")
        #expect(screen.screenKey == "home_dashboard")
        #expect(screen.screenName == "Dashboard Principal")
        #expect(screen.pattern == .dashboard)
        #expect(screen.version == 2)
        #expect(screen.handlerKey == "dashboard_handler")
        #expect(screen.updatedAt == "2025-01-15T10:30:00Z")
        #expect(screen.dataEndpoint == "mobile:/api/v1/dashboard/metrics")
    }

    @Test("Decodes template with navigation and zones")
    func decodeTemplate() throws {
        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: Self.screenJSON)

        #expect(screen.template.navigation?.topBar?.title == "Bienvenido, {user.firstName}")
        #expect(screen.template.navigation?.topBar?.showBack == false)
        #expect(screen.template.zones.count == 2)
    }

    @Test("Decodes zones with correct types")
    func decodeZones() throws {
        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: Self.screenJSON)

        let metricsZone = screen.template.zones[0]
        #expect(metricsZone.id == "zone-metrics")
        #expect(metricsZone.type == .metricGrid)
        #expect(metricsZone.distribution == .grid)
        #expect(metricsZone.slots?.count == 1)

        let actionsZone = screen.template.zones[1]
        #expect(actionsZone.id == "zone-actions")
        #expect(actionsZone.type == .actionGroup)
        #expect(actionsZone.distribution == .flowRow)
    }

    @Test("Decodes slots with control types and properties")
    func decodeSlots() throws {
        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: Self.screenJSON)
        let slot = screen.template.zones[0].slots![0]

        #expect(slot.id == "slot-students")
        #expect(slot.controlType == .metricCard)
        #expect(slot.field == "totalStudents")
        #expect(slot.label == "Estudiantes")
        #expect(slot.icon == "person.2.fill")
    }

    @Test("Decodes slotData as JSONValue dictionary")
    func decodeSlotData() throws {
        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: Self.screenJSON)

        #expect(screen.slotData?["welcomeMessage"] == .string("Hola Mundo"))
    }

    @Test("Decodes actions with trigger and type")
    func decodeActions() throws {
        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: Self.screenJSON)

        #expect(screen.actions.count == 1)
        let action = screen.actions[0]
        #expect(action.id == "action-create-class")
        #expect(action.trigger == .buttonClick)
        #expect(action.triggerSlotId == "slot-btn-create")
        #expect(action.type == .navigate)
        #expect(action.config?["target"] == .string("create_class"))
    }

    @Test("Decodes dataConfig with defaultParams")
    func decodeDataConfig() throws {
        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: Self.screenJSON)

        #expect(screen.dataConfig?.defaultParams?["role"] == "teacher")
        #expect(screen.dataConfig?.refreshInterval == 300)
        #expect(screen.dataConfig?.pagination == nil)
    }

    @Test("ScreenDefinition id matches screenId")
    func identifiable() throws {
        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: Self.screenJSON)
        #expect(screen.id == screen.screenId)
    }

    @Test("Decodes minimal ScreenDefinition without optionals")
    func decodeMinimal() throws {
        let json = """
        {
            "screenId": "scr-minimal",
            "screenKey": "minimal",
            "screenName": "Minimal",
            "pattern": "list",
            "version": 1,
            "template": {
                "zones": []
            },
            "actions": [],
            "updatedAt": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let screen = try JSONDecoder().decode(ScreenDefinition.self, from: json)
        #expect(screen.screenKey == "minimal")
        #expect(screen.pattern == .list)
        #expect(screen.slotData == nil)
        #expect(screen.dataEndpoint == nil)
        #expect(screen.dataConfig == nil)
        #expect(screen.handlerKey == nil)
        #expect(screen.template.zones.isEmpty)
        #expect(screen.actions.isEmpty)
    }
}
