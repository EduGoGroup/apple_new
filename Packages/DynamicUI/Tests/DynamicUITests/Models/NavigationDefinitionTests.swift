import Testing
import Foundation
@testable import EduDynamicUI

@Suite("NavigationDefinition Tests")
struct NavigationDefinitionTests {

    @Test("Decodes navigation with bottom nav items")
    func decodeBottomNav() throws {
        let json = """
        {
            "bottomNav": [
                {
                    "key": "home",
                    "label": "Inicio",
                    "icon": "house.fill",
                    "screenKey": "home_dashboard",
                    "sortOrder": 1
                },
                {
                    "key": "courses",
                    "label": "Cursos",
                    "icon": "book.fill",
                    "screenKey": "course_list",
                    "sortOrder": 2
                }
            ],
            "version": 3
        }
        """.data(using: .utf8)!

        let nav = try JSONDecoder().decode(NavigationDefinition.self, from: json)
        #expect(nav.bottomNav.count == 2)
        #expect(nav.version == 3)
        #expect(nav.drawerItems == nil)

        let home = nav.bottomNav[0]
        #expect(home.key == "home")
        #expect(home.label == "Inicio")
        #expect(home.icon == "house.fill")
        #expect(home.screenKey == "home_dashboard")
        #expect(home.sortOrder == 1)
        #expect(home.id == "home")
    }

    @Test("Decodes navigation with drawer items")
    func decodeDrawerItems() throws {
        let json = """
        {
            "bottomNav": [],
            "drawerItems": [
                {
                    "key": "settings",
                    "label": "Ajustes",
                    "icon": "gear",
                    "screenKey": "settings_screen",
                    "sortOrder": 1
                }
            ],
            "version": 1
        }
        """.data(using: .utf8)!

        let nav = try JSONDecoder().decode(NavigationDefinition.self, from: json)
        #expect(nav.bottomNav.isEmpty)
        #expect(nav.drawerItems?.count == 1)
        #expect(nav.drawerItems?[0].key == "settings")
    }

    @Test("NavItem with children decodes correctly")
    func decodeNavItemWithChildren() throws {
        let json = """
        {
            "key": "admin",
            "label": "Admin",
            "icon": "person.badge.key",
            "screenKey": "admin_panel",
            "sortOrder": 1,
            "children": [
                {
                    "key": "users",
                    "label": "Usuarios",
                    "icon": "person.2",
                    "screenKey": "user_list",
                    "sortOrder": 1
                }
            ]
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(NavItem.self, from: json)
        #expect(item.children?.count == 1)
        #expect(item.children?[0].key == "users")
        #expect(item.children?[0].children == nil)
    }

    @Test("NavItem without children has nil children")
    func decodeNavItemWithoutChildren() throws {
        let json = """
        {
            "key": "home",
            "label": "Home",
            "icon": "house",
            "screenKey": "home",
            "sortOrder": 0
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(NavItem.self, from: json)
        #expect(item.children == nil)
    }
}
