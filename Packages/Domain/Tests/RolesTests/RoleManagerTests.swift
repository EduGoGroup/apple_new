import Testing
import Foundation
@testable import EduDomain

// MARK: - RoleManager Tests

@Suite("RoleManager Tests")
struct RoleManagerTests {

    // MARK: - Initial State Tests

    @Test("Initial state is student with default permissions")
    func testInitialState_isStudentWithDefaultPermissions() async {
        let manager = RoleManager()

        let role = await manager.getCurrentRole()
        let permissions = await manager.getCurrentPermissions()

        #expect(role == .student)
        #expect(permissions == Permission.studentPermissions)
    }

    // MARK: - setRole Tests

    @Test("setRole updates current role")
    func testSetRole_updatesCurrentRole() async {
        let manager = RoleManager()

        await manager.setRole(.teacher)
        let role = await manager.getCurrentRole()

        #expect(role == .teacher)
    }

    @Test("setRole updates permissions automatically")
    func testSetRole_updatesPermissionsAutomatically() async {
        let manager = RoleManager()

        await manager.setRole(.teacher)
        let permissions = await manager.getCurrentPermissions()

        #expect(permissions == Permission.teacherPermissions)
    }

    @Test("setRole with admin grants all permissions")
    func testSetRole_adminGrantsAllPermissions() async {
        let manager = RoleManager()

        await manager.setRole(.admin)
        let permissions = await manager.getCurrentPermissions()

        #expect(permissions == Permission.adminPermissions)
        #expect(permissions == Permission.all)
    }

    @Test("setRole clears previous custom permissions")
    func testSetRole_clearsPreviousCustomPermissions() async {
        let manager = RoleManager()

        // Set role with custom permissions
        await manager.setRole(.student, withAdditionalPermissions: .exportReports)

        // Change role without custom permissions
        await manager.setRole(.teacher)

        let customPerms = await manager.getCustomPermissions()
        #expect(customPerms == [])
    }

    // MARK: - setRole with Additional Permissions Tests

    @Test("setRole with additional permissions combines them")
    func testSetRoleWithAdditionalPermissions_combinesPermissions() async {
        let manager = RoleManager()

        await manager.setRole(.student, withAdditionalPermissions: .exportReports)

        let permissions = await manager.getCurrentPermissions()
        let customPerms = await manager.getCustomPermissions()

        // Should have student permissions + exportReports
        #expect(permissions.contains(.viewMaterials)) // from student
        #expect(permissions.contains(.takeQuizzes))   // from student
        #expect(permissions.contains(.exportReports)) // custom
        #expect(customPerms == .exportReports)
    }

    @Test("setRole with multiple additional permissions")
    func testSetRoleWithMultipleAdditionalPermissions() async {
        let manager = RoleManager()

        let extraPerms: Permission = [.exportReports, .manageUsers]
        await manager.setRole(.student, withAdditionalPermissions: extraPerms)

        let permissions = await manager.getCurrentPermissions()

        #expect(permissions.contains(.exportReports))
        #expect(permissions.contains(.manageUsers))
        #expect(permissions.contains(.viewMaterials)) // base permission
    }

    // MARK: - hasPermission Tests

    @Test("hasPermission returns true for granted permission")
    func testHasPermission_returnsTrueForGrantedPermission() async {
        let manager = RoleManager()
        await manager.setRole(.teacher)

        let canCreate = await manager.hasPermission(.createQuizzes)

        #expect(canCreate == true)
    }

    @Test("hasPermission returns false for denied permission")
    func testHasPermission_returnsFalseForDeniedPermission() async {
        let manager = RoleManager()
        await manager.setRole(.student)

        let canManage = await manager.hasPermission(.manageUsers)

        #expect(canManage == false)
    }

    // MARK: - hasAllPermissions Tests

    @Test("hasAllPermissions returns true when all present")
    func testHasAllPermissions_returnsTrueWhenAllPresent() async {
        let manager = RoleManager()
        await manager.setRole(.teacher)

        let required: Permission = [.viewMaterials, .uploadMaterials]
        let hasAll = await manager.hasAllPermissions(required)

        #expect(hasAll == true)
    }

    @Test("hasAllPermissions returns false when some missing")
    func testHasAllPermissions_returnsFalseWhenSomeMissing() async {
        let manager = RoleManager()
        await manager.setRole(.student)

        let required: Permission = [.viewMaterials, .uploadMaterials]
        let hasAll = await manager.hasAllPermissions(required)

        #expect(hasAll == false) // student can't upload
    }

    // MARK: - hasAnyPermission Tests

    @Test("hasAnyPermission returns true when at least one present")
    func testHasAnyPermission_returnsTrueWhenAtLeastOnePresent() async {
        let manager = RoleManager()
        await manager.setRole(.student)

        let anyOf: Permission = [.viewMaterials, .manageUsers]
        let hasAny = await manager.hasAnyPermission(anyOf)

        #expect(hasAny == true) // student can view materials
    }

    @Test("hasAnyPermission returns false when none present")
    func testHasAnyPermission_returnsFalseWhenNonePresent() async {
        let manager = RoleManager()
        await manager.setRole(.student)

        let anyOf: Permission = [.manageUsers, .exportReports]
        let hasAny = await manager.hasAnyPermission(anyOf)

        #expect(hasAny == false)
    }

    // MARK: - hasRole Tests

    @Test("hasRole checks hierarchy correctly - higher role")
    func testHasRole_higherRoleReturnsTrue() async {
        let manager = RoleManager()
        await manager.setRole(.admin)

        let hasStudentLevel = await manager.hasRole(.student)

        #expect(hasStudentLevel == true)
    }

    @Test("hasRole checks hierarchy correctly - same role")
    func testHasRole_sameRoleReturnsTrue() async {
        let manager = RoleManager()
        await manager.setRole(.teacher)

        let hasTeacherLevel = await manager.hasRole(.teacher)

        #expect(hasTeacherLevel == true)
    }

    @Test("hasRole checks hierarchy correctly - lower role")
    func testHasRole_lowerRoleReturnsFalse() async {
        let manager = RoleManager()
        await manager.setRole(.student)

        let hasAdminLevel = await manager.hasRole(.admin)

        #expect(hasAdminLevel == false)
    }

    // MARK: - reset Tests

    @Test("reset clears to initial state")
    func testReset_clearsToInitialState() async {
        let manager = RoleManager()

        // Set to admin with custom permissions
        await manager.setRole(.admin, withAdditionalPermissions: .exportReports)

        // Reset
        await manager.reset()

        let role = await manager.getCurrentRole()
        let permissions = await manager.getCurrentPermissions()
        let customPerms = await manager.getCustomPermissions()

        #expect(role == .student)
        #expect(permissions == Permission.studentPermissions)
        #expect(customPerms == [])
    }

    // MARK: - Codable Integration Tests

    @Test("SystemRole can be encoded and decoded from JSON")
    func testSystemRole_codable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let original = SystemRole.teacher
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(SystemRole.self, from: data)

        #expect(decoded == original)
    }

    @Test("SystemRole decodes from backend JSON string")
    func testSystemRole_decodesFromBackendJSON() throws {
        let jsonString = "\"teacher\""
        let data = jsonString.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(SystemRole.self, from: data)

        #expect(decoded == .teacher)
    }
}
