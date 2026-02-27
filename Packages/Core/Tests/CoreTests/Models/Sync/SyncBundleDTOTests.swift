import Testing
import Foundation
@testable import EduModels

@Suite("Sync Bundle DTO Tests")
struct SyncBundleDTOTests {

    // MARK: - SyncBundleResponseDTO

    @Test("SyncBundleResponseDTO decodes full response")
    func testDecodeSyncBundle() throws {
        let json = """
        {
          "menu": [
            {
              "key": "dashboard",
              "display_name": "Dashboard",
              "icon": "house.fill",
              "scope": "student",
              "sort_order": 1,
              "permissions": ["view_dashboard"],
              "screens": {"main": "dashboard_main"},
              "children": []
            }
          ],
          "permissions": ["view_dashboard", "edit_profile"],
          "screens": {
            "dashboard_main": {
              "screen_key": "dashboard_main",
              "screen_name": "Dashboard",
              "pattern": "dashboard",
              "version": "1.0.0",
              "template": {"type": "container"},
              "slot_data": null,
              "handler_key": null
            }
          },
          "available_contexts": [
            {
              "role_id": "role-1",
              "role_name": "student",
              "school_id": "school-1",
              "school_name": "Test School",
              "academic_unit_id": null,
              "permissions": ["view_dashboard"]
            }
          ],
          "hashes": {
            "menu": "hash-menu-abc",
            "screens": "hash-screens-def"
          }
        }
        """.data(using: .utf8)!

        let bundle = try JSONDecoder().decode(SyncBundleResponseDTO.self, from: json)

        #expect(bundle.menu.count == 1)
        #expect(bundle.menu[0].key == "dashboard")
        #expect(bundle.permissions == ["view_dashboard", "edit_profile"])
        #expect(bundle.screens.count == 1)
        #expect(bundle.screens["dashboard_main"]?.pattern == "dashboard")
        #expect(bundle.availableContexts.count == 1)
        #expect(bundle.availableContexts[0].roleName == "student")
        #expect(bundle.hashes["menu"] == "hash-menu-abc")
        #expect(bundle.hashes["screens"] == "hash-screens-def")
    }

    // MARK: - MenuItemDTO

    @Test("MenuItemDTO decodes with recursive children")
    func testMenuItemWithChildren() throws {
        let json = """
        {
          "key": "academic",
          "display_name": "Academic",
          "icon": "book.fill",
          "scope": "teacher",
          "sort_order": 2,
          "permissions": ["view_academic"],
          "screens": {"main": "academic_main"},
          "children": [
            {
              "key": "grades",
              "display_name": "Grades",
              "icon": "chart.bar",
              "scope": "teacher",
              "sort_order": 1,
              "permissions": ["view_grades"],
              "screens": {"main": "grades_main"},
              "children": null
            },
            {
              "key": "attendance",
              "display_name": "Attendance",
              "icon": "person.badge.clock",
              "scope": "teacher",
              "sort_order": 2,
              "permissions": ["view_attendance"],
              "screens": {"main": "attendance_main"},
              "children": []
            }
          ]
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(MenuItemDTO.self, from: json)

        #expect(item.key == "academic")
        #expect(item.displayName == "Academic")
        #expect(item.children?.count == 2)
        #expect(item.children?[0].key == "grades")
        #expect(item.children?[0].children == nil)
        #expect(item.children?[1].key == "attendance")
        #expect(item.children?[1].children?.isEmpty == true)
    }

    @Test("MenuItemDTO Identifiable uses key")
    func testMenuItemIdentifiable() {
        let item = MenuItemDTO(
            key: "test-key",
            displayName: "Test",
            scope: "student",
            sortOrder: 1,
            permissions: [],
            screens: [:]
        )

        #expect(item.id == "test-key")
    }

    // MARK: - ScreenBundleDTO

    @Test("ScreenBundleDTO decodes with JSONValue template")
    func testScreenBundleDecoding() throws {
        let json = """
        {
          "screen_key": "dashboard_main",
          "screen_name": "Dashboard",
          "pattern": "dashboard",
          "version": "2.0.0",
          "template": {
            "type": "stack",
            "children": [
              {"type": "text", "value": "Hello"}
            ]
          },
          "slot_data": {"title": "Welcome"},
          "handler_key": "dashboard_handler"
        }
        """.data(using: .utf8)!

        let screen = try JSONDecoder().decode(ScreenBundleDTO.self, from: json)

        #expect(screen.screenKey == "dashboard_main")
        #expect(screen.screenName == "Dashboard")
        #expect(screen.pattern == "dashboard")
        #expect(screen.version == "2.0.0")
        #expect(screen.handlerKey == "dashboard_handler")

        // Template is a JSONValue.object
        if case .object(let templateObj) = screen.template {
            #expect(templateObj["type"] == .string("stack"))
        } else {
            Issue.record("Expected template to be .object")
        }

        // Slot data is a JSONValue.object
        if case .object(let slotObj) = screen.slotData {
            #expect(slotObj["title"] == .string("Welcome"))
        } else {
            Issue.record("Expected slotData to be .object")
        }
    }

    @Test("ScreenBundleDTO decodes with null optional fields")
    func testScreenBundleNullOptionals() throws {
        let json = """
        {
          "screen_key": "simple",
          "screen_name": "Simple",
          "pattern": "list",
          "version": "1.0.0",
          "template": {"type": "list"},
          "slot_data": null,
          "handler_key": null
        }
        """.data(using: .utf8)!

        let screen = try JSONDecoder().decode(ScreenBundleDTO.self, from: json)

        #expect(screen.slotData == nil)
        #expect(screen.handlerKey == nil)
    }

    // MARK: - DeltaSyncResponseDTO

    @Test("DeltaSyncResponseDTO decodes changed and unchanged")
    func testDeltaSyncResponse() throws {
        let json = """
        {
          "changed": {
            "menu": {
              "data": {"items": [1, 2, 3]},
              "hash": "new-menu-hash"
            }
          },
          "unchanged": ["screens", "permissions"]
        }
        """.data(using: .utf8)!

        let delta = try JSONDecoder().decode(DeltaSyncResponseDTO.self, from: json)

        #expect(delta.changed.count == 1)
        #expect(delta.changed["menu"]?.hash == "new-menu-hash")
        #expect(delta.unchanged == ["screens", "permissions"])
    }

    // MARK: - BucketDataDTO

    @Test("BucketDataDTO decodes data and hash")
    func testBucketDataDecoding() throws {
        let json = """
        {
          "data": {"key": "value", "count": 42},
          "hash": "abc123def456"
        }
        """.data(using: .utf8)!

        let bucket = try JSONDecoder().decode(BucketDataDTO.self, from: json)

        #expect(bucket.hash == "abc123def456")
        if case .object(let obj) = bucket.data {
            #expect(obj["key"] == .string("value"))
            #expect(obj["count"] == .integer(42))
        } else {
            Issue.record("Expected data to be .object")
        }
    }

    // MARK: - DeltaSyncRequestDTO

    @Test("DeltaSyncRequestDTO encodes with snake_case")
    func testDeltaSyncRequestEncoding() throws {
        let request = DeltaSyncRequestDTO(hashes: ["menu": "hash1", "screens": "hash2"])
        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        let hashes = dict["hashes"] as? [String: String]
        #expect(hashes?["menu"] == "hash1")
        #expect(hashes?["screens"] == "hash2")
    }
}
