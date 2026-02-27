import Testing
import Foundation
@testable import EduModels

@Suite("AuthContext Tests")
struct AuthContextTests {

    // MARK: - Permission Tests

    @Test("hasPermission returns true for existing permission")
    func testHasPermissionTrue() {
        let context = AuthContext(
            roleId: "role-1",
            roleName: "teacher",
            permissions: ["view_dashboard", "edit_grades", "view_students"]
        )

        #expect(context.hasPermission("edit_grades") == true)
    }

    @Test("hasPermission returns false for missing permission")
    func testHasPermissionFalse() {
        let context = AuthContext(
            roleId: "role-1",
            roleName: "teacher",
            permissions: ["view_dashboard", "edit_grades"]
        )

        #expect(context.hasPermission("delete_users") == false)
    }

    @Test("hasPermission returns false for empty permissions")
    func testHasPermissionEmpty() {
        let context = AuthContext(roleId: "role-1", roleName: "guest")

        #expect(context.hasPermission("anything") == false)
    }

    @Test("hasAnyPermission returns true with partial match")
    func testHasAnyPermissionPartialMatch() {
        let context = AuthContext(
            roleId: "role-1",
            roleName: "teacher",
            permissions: ["view_dashboard", "edit_grades"]
        )

        #expect(context.hasAnyPermission(["admin_panel", "edit_grades"]) == true)
    }

    @Test("hasAnyPermission returns false with no match")
    func testHasAnyPermissionNoMatch() {
        let context = AuthContext(
            roleId: "role-1",
            roleName: "student",
            permissions: ["view_dashboard"]
        )

        #expect(context.hasAnyPermission(["admin_panel", "edit_grades"]) == false)
    }

    @Test("hasAnyPermission returns false for empty required list")
    func testHasAnyPermissionEmptyRequired() {
        let context = AuthContext(
            roleId: "role-1",
            roleName: "teacher",
            permissions: ["view_dashboard"]
        )

        #expect(context.hasAnyPermission([]) == false)
    }

    @Test("hasAllPermissions returns true when all present")
    func testHasAllPermissionsTrue() {
        let context = AuthContext(
            roleId: "role-1",
            roleName: "admin",
            permissions: ["read", "write", "delete", "admin"]
        )

        #expect(context.hasAllPermissions(["read", "write", "delete"]) == true)
    }

    @Test("hasAllPermissions returns false with partial match")
    func testHasAllPermissionsFalse() {
        let context = AuthContext(
            roleId: "role-1",
            roleName: "teacher",
            permissions: ["read", "write"]
        )

        #expect(context.hasAllPermissions(["read", "write", "delete"]) == false)
    }

    @Test("hasAllPermissions returns true for empty required list")
    func testHasAllPermissionsEmpty() {
        let context = AuthContext(
            roleId: "role-1",
            roleName: "student",
            permissions: ["view_dashboard"]
        )

        #expect(context.hasAllPermissions([]) == true)
    }

    // MARK: - Factory Method

    @Test("AuthContext.from(dto:) maps all fields correctly")
    func testFactoryFromDTO() {
        let dto = UserContextDTO(
            roleId: "role-admin",
            roleName: "admin",
            schoolId: "school-1",
            schoolName: "Test School",
            academicUnitId: "unit-1",
            permissions: ["read", "write"]
        )

        let context = AuthContext.from(dto: dto)

        #expect(context.roleId == "role-admin")
        #expect(context.roleName == "admin")
        #expect(context.schoolId == "school-1")
        #expect(context.schoolName == "Test School")
        #expect(context.academicUnitId == "unit-1")
        #expect(context.permissions == ["read", "write"])
    }

    @Test("AuthContext.from(dto:) handles nil optionals")
    func testFactoryFromDTOWithNils() {
        let dto = UserContextDTO(
            roleId: "role-superadmin",
            roleName: "superadmin"
        )

        let context = AuthContext.from(dto: dto)

        #expect(context.schoolId == nil)
        #expect(context.schoolName == nil)
        #expect(context.academicUnitId == nil)
        #expect(context.permissions.isEmpty)
    }

    // MARK: - Equatable / Hashable

    @Test("AuthContext conforms to Equatable")
    func testEquatable() {
        let a = AuthContext(roleId: "r1", roleName: "admin", permissions: ["read"])
        let b = AuthContext(roleId: "r1", roleName: "admin", permissions: ["read"])
        let c = AuthContext(roleId: "r2", roleName: "teacher", permissions: ["read"])

        #expect(a == b)
        #expect(a != c)
    }
}
