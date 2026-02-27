import Testing
import Foundation
@testable import EduModels

@Suite("Role Entity Tests")
struct RoleTests {

    // MARK: - RoleLevel Tests

    @Test("RoleLevel raw values are ordered correctly")
    func testRoleLevelOrder() {
        #expect(RoleLevel.student.rawValue < RoleLevel.teacher.rawValue)
        #expect(RoleLevel.teacher.rawValue < RoleLevel.admin.rawValue)
    }

    @Test("RoleLevel is Comparable")
    func testRoleLevelComparable() {
        #expect(RoleLevel.student < RoleLevel.teacher)
        #expect(RoleLevel.teacher < RoleLevel.admin)
        #expect(RoleLevel.admin > RoleLevel.student)
    }

    @Test("RoleLevel has all expected cases")
    func testRoleLevelCases() {
        let allCases = RoleLevel.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.admin))
        #expect(allCases.contains(.teacher))
        #expect(allCases.contains(.student))
    }

    @Test("RoleLevel has meaningful descriptions")
    func testRoleLevelDescriptions() {
        #expect(RoleLevel.admin.description == "Administrator")
        #expect(RoleLevel.teacher.description == "Teacher")
        #expect(RoleLevel.student.description == "Student")
    }

    // MARK: - Role Initialization Tests

    @Test("Role creation with valid data")
    func testValidRoleCreation() throws {
        let role = try Role(
            name: "Administrator",
            level: .admin
        )

        #expect(role.name == "Administrator")
        #expect(role.level == .admin)
        #expect(role.permissionIDs.isEmpty)
    }

    @Test("Role creation trims whitespace from name")
    func testNameTrimming() throws {
        let role = try Role(
            name: "  Teacher  ",
            level: .teacher
        )

        #expect(role.name == "Teacher")
    }

    @Test("Role creation with custom ID")
    func testCustomID() throws {
        let customID = UUID()
        let role = try Role(
            id: customID,
            name: "Student",
            level: .student
        )

        #expect(role.id == customID)
    }

    @Test("Role creation with initial permissions")
    func testInitialPermissions() throws {
        let permID1 = UUID()
        let permID2 = UUID()
        let role = try Role(
            name: "Admin",
            level: .admin,
            permissionIDs: [permID1, permID2]
        )

        #expect(role.permissionIDs.count == 2)
        #expect(role.permissionIDs.contains(permID1))
        #expect(role.permissionIDs.contains(permID2))
    }

    // MARK: - Role Validation Tests

    @Test("Role creation fails with empty name")
    func testEmptyNameFails() {
        #expect(throws: RoleValidationError.emptyName) {
            _ = try Role(name: "", level: .student)
        }
    }

    @Test("Role creation fails with whitespace-only name")
    func testWhitespaceNameFails() {
        #expect(throws: RoleValidationError.emptyName) {
            _ = try Role(name: "   ", level: .teacher)
        }
    }

    // MARK: - Copy Method Tests

    @Test("with(name:) creates copy with new name")
    func testWithName() throws {
        let role = try Role(name: "Old Name", level: .teacher)
        let updated = try role.with(name: "New Name")

        #expect(updated.name == "New Name")
        #expect(updated.id == role.id)
        #expect(updated.level == role.level)
    }

    @Test("with(level:) creates copy with new level")
    func testWithLevel() throws {
        let role = try Role(name: "Role", level: .student)
        let updated = role.with(level: .teacher)

        #expect(updated.level == .teacher)
        #expect(updated.id == role.id)
        #expect(updated.name == role.name)
    }

    // MARK: - Permission Management Tests

    @Test("addPermission adds permission to role")
    func testAddPermission() throws {
        let role = try Role(name: "Admin", level: .admin)
        let permID = UUID()
        let updated = role.addPermission(permID)

        #expect(updated.permissionIDs.contains(permID))
        #expect(updated.permissionIDs.count == 1)
    }

    @Test("addPermission is idempotent")
    func testAddPermissionIdempotent() throws {
        let role = try Role(name: "Admin", level: .admin)
        let permID = UUID()
        let updated = role.addPermission(permID).addPermission(permID)

        #expect(updated.permissionIDs.count == 1)
    }

    @Test("removePermission removes permission from role")
    func testRemovePermission() throws {
        let permID = UUID()
        let role = try Role(
            name: "Admin",
            level: .admin,
            permissionIDs: [permID]
        )
        let updated = role.removePermission(permID)

        #expect(!updated.permissionIDs.contains(permID))
        #expect(updated.permissionIDs.isEmpty)
    }

    @Test("hasPermission returns correct value")
    func testHasPermission() throws {
        let permID = UUID()
        let otherPermID = UUID()
        let role = try Role(
            name: "Admin",
            level: .admin,
            permissionIDs: [permID]
        )

        #expect(role.hasPermission(permID))
        #expect(!role.hasPermission(otherPermID))
    }

    // MARK: - Role Comparable Tests

    @Test("Roles are comparable by level")
    func testRoleComparable() throws {
        let studentRole = try Role(name: "Student", level: .student)
        let teacherRole = try Role(name: "Teacher", level: .teacher)
        let adminRole = try Role(name: "Admin", level: .admin)

        #expect(studentRole < teacherRole)
        #expect(teacherRole < adminRole)
        #expect(adminRole > studentRole)
    }

    @Test("Roles with same level are equal in comparison")
    func testRoleSameLevelComparison() throws {
        let teacher1 = try Role(name: "Teacher 1", level: .teacher)
        let teacher2 = try Role(name: "Teacher 2", level: .teacher)

        #expect(!(teacher1 < teacher2))
        #expect(!(teacher2 < teacher1))
    }

    // MARK: - Protocol Conformance Tests

    @Test("Role conforms to Equatable")
    func testEquatable() throws {
        let id = UUID()
        let role1 = try Role(id: id, name: "Admin", level: .admin)
        let role2 = try Role(id: id, name: "Admin", level: .admin)
        let role3 = try Role(name: "Admin", level: .admin)

        #expect(role1 == role2)
        #expect(role1 != role3)
    }

    @Test("Role conforms to Hashable")
    func testHashable() throws {
        let role1 = try Role(name: "Admin", level: .admin)
        let role2 = try Role(name: "Teacher", level: .teacher)

        var roleSet: Set<Role> = []
        roleSet.insert(role1)
        roleSet.insert(role2)

        #expect(roleSet.count == 2)
    }

    // MARK: - Error Description Tests

    @Test("RoleValidationError has meaningful description")
    func testErrorDescription() {
        let error = RoleValidationError.emptyName
        #expect(error.errorDescription?.contains("empty") == true)
    }
}
