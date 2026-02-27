// MenuServiceTests.swift
// EduDomainTests

import Testing
import Foundation
import EduCore
@testable import EduDomain

@Suite("MenuService Tests")
struct MenuServiceTests {

    // MARK: - Helpers

    private func makeBundle(
        menu: [MenuItemDTO] = [],
        permissions: [String] = [],
        availableContexts: [UserContextDTO] = []
    ) -> UserDataBundle {
        UserDataBundle(
            menu: menu,
            permissions: permissions,
            screens: [:],
            availableContexts: availableContexts,
            hashes: [:],
            syncedAt: Date()
        )
    }

    private func makeDTO(
        key: String,
        displayName: String = "Item",
        sortOrder: Int = 0,
        permissions: [String] = []
    ) -> MenuItemDTO {
        MenuItemDTO(
            key: key,
            displayName: displayName,
            scope: "global",
            sortOrder: sortOrder,
            permissions: permissions,
            screens: [:]
        )
    }

    // MARK: - Update Menu

    @Test("updateMenu filters items and updates currentMenu")
    func updateMenuFiltersAndUpdates() async {
        let service = MenuService()
        let bundle = makeBundle(
            menu: [
                makeDTO(key: "dashboard", permissions: []),
                makeDTO(key: "admin", permissions: ["admin_access"])
            ]
        )

        await service.updateMenu(from: bundle, permissions: ["view_dashboard"])

        let menu = await service.currentMenu
        #expect(menu.count == 1)
        #expect(menu.first?.key == "dashboard")
    }

    @Test("updateMenu yields to menuStream")
    func updateMenuYieldsToStream() async {
        let service = MenuService()

        // Acceder al stream primero para inicializarlo
        let stream = await service.menuStream

        let bundle = makeBundle(
            menu: [makeDTO(key: "home", permissions: [])]
        )

        await service.updateMenu(from: bundle, permissions: [])

        // Verificar que el stream emite el menu
        var received: [MenuItem]?
        for await menu in stream {
            received = menu
            break
        }

        #expect(received?.count == 1)
        #expect(received?.first?.key == "home")
    }

    @Test("updateMenu replaces previous menu on context change")
    func updateMenuReplacesOnContextChange() async {
        let service = MenuService()

        // Primer contexto: teacher
        let teacherBundle = makeBundle(
            menu: [
                makeDTO(key: "grades", permissions: ["view_grades"]),
                makeDTO(key: "dashboard", permissions: [])
            ]
        )
        await service.updateMenu(from: teacherBundle, permissions: ["view_grades"])
        let teacherMenu = await service.currentMenu
        #expect(teacherMenu.count == 2)

        // Segundo contexto: student (sin view_grades)
        let studentBundle = makeBundle(
            menu: [
                makeDTO(key: "grades", permissions: ["view_grades"]),
                makeDTO(key: "dashboard", permissions: [])
            ]
        )
        await service.updateMenu(from: studentBundle, permissions: ["view_own_grades"])
        let studentMenu = await service.currentMenu
        #expect(studentMenu.count == 1)
        #expect(studentMenu.first?.key == "dashboard")
    }
}
