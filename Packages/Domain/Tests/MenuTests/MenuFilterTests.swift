// MenuFilterTests.swift
// EduDomainTests

import Testing
import EduCore
@testable import EduDomain

@Suite("MenuFilter Tests")
struct MenuFilterTests {

    // MARK: - Helpers

    private func makeDTO(
        key: String,
        displayName: String = "Item",
        icon: String? = nil,
        sortOrder: Int = 0,
        permissions: [String] = [],
        screens: [String: String] = [:],
        children: [MenuItemDTO]? = nil
    ) -> MenuItemDTO {
        MenuItemDTO(
            key: key,
            displayName: displayName,
            icon: icon,
            scope: "global",
            sortOrder: sortOrder,
            permissions: permissions,
            screens: screens,
            children: children
        )
    }

    // MARK: - Permission Filtering

    @Test("Items without permissions are visible to all")
    func itemsWithoutPermissionsAreVisible() {
        let items = [
            makeDTO(key: "dashboard", permissions: [])
        ]

        let result = MenuFilter.filter(items: items, permissions: [])
        #expect(result.count == 1)
        #expect(result.first?.key == "dashboard")
    }

    @Test("Items with permissions are hidden when user lacks permission")
    func itemsHiddenWithoutPermission() {
        let items = [
            makeDTO(key: "admin", permissions: ["admin_access"])
        ]

        let result = MenuFilter.filter(items: items, permissions: ["view_dashboard"])
        #expect(result.isEmpty)
    }

    @Test("Items with permissions are visible when user has at least one")
    func itemsVisibleWithMatchingPermission() {
        let items = [
            makeDTO(key: "grades", permissions: ["edit_grades", "view_grades"])
        ]

        let result = MenuFilter.filter(items: items, permissions: ["view_grades"])
        #expect(result.count == 1)
        #expect(result.first?.key == "grades")
    }

    @Test("Mixed items filter correctly")
    func mixedItemsFilterCorrectly() {
        let items = [
            makeDTO(key: "dashboard", permissions: []),
            makeDTO(key: "admin", permissions: ["admin_access"]),
            makeDTO(key: "grades", permissions: ["view_grades"])
        ]

        let result = MenuFilter.filter(items: items, permissions: ["view_grades"])
        #expect(result.count == 2)
        let keys = result.map(\.key)
        #expect(keys.contains("dashboard"))
        #expect(keys.contains("grades"))
        #expect(!keys.contains("admin"))
    }

    // MARK: - Recursion

    @Test("Children are filtered recursively")
    func childrenFilteredRecursively() {
        let children = [
            makeDTO(key: "child1", permissions: ["perm_a"]),
            makeDTO(key: "child2", permissions: ["perm_b"])
        ]
        let items = [
            makeDTO(key: "parent", permissions: [], children: children)
        ]

        let result = MenuFilter.filter(items: items, permissions: ["perm_a"])
        #expect(result.count == 1)
        #expect(result.first?.children.count == 1)
        #expect(result.first?.children.first?.key == "child1")
    }

    @Test("Parent visible if it has visible children even without own permission")
    func parentVisibleWithVisibleChildren() {
        let children = [
            makeDTO(key: "child1", permissions: ["perm_a"])
        ]
        let items = [
            makeDTO(key: "parent", permissions: ["admin_only"], children: children)
        ]

        let result = MenuFilter.filter(items: items, permissions: ["perm_a"])
        #expect(result.count == 1)
        #expect(result.first?.key == "parent")
        #expect(result.first?.children.count == 1)
    }

    @Test("Parent hidden if all children are hidden and no own permission")
    func parentHiddenWithNoVisibleChildren() {
        let children = [
            makeDTO(key: "child1", permissions: ["perm_a"])
        ]
        let items = [
            makeDTO(key: "parent", permissions: ["admin_only"], children: children)
        ]

        let result = MenuFilter.filter(items: items, permissions: ["unrelated"])
        #expect(result.isEmpty)
    }

    // MARK: - Sorting

    @Test("Results sorted by sortOrder")
    func resultsSortedBySortOrder() {
        let items = [
            makeDTO(key: "c", sortOrder: 3),
            makeDTO(key: "a", sortOrder: 1),
            makeDTO(key: "b", sortOrder: 2)
        ]

        let result = MenuFilter.filter(items: items, permissions: [])
        #expect(result.map(\.key) == ["a", "b", "c"])
    }

    // MARK: - Screen Mapping

    @Test("Screen mappings are preserved")
    func screenMappingsPreserved() {
        let items = [
            makeDTO(key: "dashboard", screens: ["main": "dashboard-teacher"])
        ]

        let result = MenuFilter.filter(items: items, permissions: [])
        #expect(result.first?.screens["main"] == "dashboard-teacher")
    }
}
