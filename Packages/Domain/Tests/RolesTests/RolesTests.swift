import Testing
@testable import EduDomain

// MARK: - SystemRole Tests

@Suite("SystemRole Tests")
struct SystemRoleTests {

    @Test("Init from raw value with valid values")
    func testInitFromRawValue_validValues() {
        #expect(SystemRole(rawValue: "admin") == .admin)
        #expect(SystemRole(rawValue: "teacher") == .teacher)
        #expect(SystemRole(rawValue: "student") == .student)
        #expect(SystemRole(rawValue: "guardian") == .guardian)
    }

    @Test("Init from raw value with invalid value returns nil")
    func testInitFromRawValue_invalidValue() {
        #expect(SystemRole(rawValue: "invalid") == nil)
        #expect(SystemRole(rawValue: "ADMIN") == nil)
        #expect(SystemRole(rawValue: "") == nil)
    }

    @Test("Level returns correct hierarchy")
    func testLevel_returnsCorrectHierarchy() {
        #expect(SystemRole.admin.level == 100)
        #expect(SystemRole.teacher.level == 50)
        #expect(SystemRole.student.level == 30)
        #expect(SystemRole.guardian.level == 20)
    }

    @Test("hasAtLeast with higher role returns true")
    func testHasAtLeast_higherRole_returnsTrue() {
        #expect(SystemRole.admin.hasAtLeast(.teacher) == true)
        #expect(SystemRole.admin.hasAtLeast(.student) == true)
        #expect(SystemRole.admin.hasAtLeast(.guardian) == true)
        #expect(SystemRole.teacher.hasAtLeast(.student) == true)
    }

    @Test("hasAtLeast with lower role returns false")
    func testHasAtLeast_lowerRole_returnsFalse() {
        #expect(SystemRole.student.hasAtLeast(.teacher) == false)
        #expect(SystemRole.guardian.hasAtLeast(.admin) == false)
        #expect(SystemRole.teacher.hasAtLeast(.admin) == false)
    }

    @Test("hasAtLeast with same role returns true")
    func testHasAtLeast_sameRole_returnsTrue() {
        #expect(SystemRole.admin.hasAtLeast(.admin) == true)
        #expect(SystemRole.teacher.hasAtLeast(.teacher) == true)
        #expect(SystemRole.student.hasAtLeast(.student) == true)
        #expect(SystemRole.guardian.hasAtLeast(.guardian) == true)
    }

    @Test("CaseIterable contains all roles")
    func testCaseIterable_containsAllRoles() {
        let allRoles = SystemRole.allCases
        #expect(allRoles.count == 4)
        #expect(allRoles.contains(.admin))
        #expect(allRoles.contains(.teacher))
        #expect(allRoles.contains(.student))
        #expect(allRoles.contains(.guardian))
    }

    @Test("displayName returns localized name")
    func testDisplayName_returnsLocalizedName() {
        #expect(SystemRole.admin.displayName == "Administrador")
        #expect(SystemRole.teacher.displayName == "Profesor")
        #expect(SystemRole.student.displayName == "Estudiante")
        #expect(SystemRole.guardian.displayName == "Acudiente")
    }
}

// MARK: - Permission Tests

@Suite("Permission Tests")
struct PermissionTests {

    @Test("Single permission has correct bit")
    func testSinglePermission_hasCorrectBit() {
        #expect(Permission.viewMaterials.rawValue == 1 << 0)
        #expect(Permission.uploadMaterials.rawValue == 1 << 1)
        #expect(Permission.takeQuizzes.rawValue == 1 << 10)
        #expect(Permission.viewOwnProgress.rawValue == 1 << 20)
        #expect(Permission.viewUsers.rawValue == 1 << 30)
        #expect(Permission.viewReports.rawValue == 1 << 40)
    }

    @Test("Union combines permissions")
    func testUnion_combinesPermissions() {
        let perms: Permission = [.viewMaterials, .uploadMaterials]
        #expect(perms.contains(.viewMaterials))
        #expect(perms.contains(.uploadMaterials))
        #expect(!perms.contains(.deleteMaterials))
    }

    @Test("Intersection finds common permissions")
    func testIntersection_findsCommonPermissions() {
        let permsA: Permission = [.viewMaterials, .uploadMaterials, .takeQuizzes]
        let permsB: Permission = [.uploadMaterials, .gradeQuizzes]

        let common = permsA.intersection(permsB)

        #expect(common == .uploadMaterials)
    }

    @Test("Contains detects single permission")
    func testContains_detectsSinglePermission() {
        let perms: Permission = [.viewMaterials, .takeQuizzes]
        #expect(perms.contains(.viewMaterials))
        #expect(perms.contains(.takeQuizzes))
        #expect(!perms.contains(.createQuizzes))
    }

    @Test("Contains detects multiple permissions")
    func testContains_detectsMultiplePermissions() {
        let perms: Permission = [.viewMaterials, .uploadMaterials, .takeQuizzes]

        #expect(perms.contains([.viewMaterials, .takeQuizzes]))
        #expect(!perms.contains([.viewMaterials, .deleteMaterials]))
    }

    @Test("Student permissions contains expected permissions")
    func testStudentPermissions_containsExpected() {
        let perms = Permission.studentPermissions
        #expect(perms.contains(.viewMaterials))
        #expect(perms.contains(.takeQuizzes))
        #expect(perms.contains(.viewOwnProgress))
        #expect(!perms.contains(.uploadMaterials))
        #expect(!perms.contains(.manageUsers))
    }

    @Test("Guardian permissions contains expected permissions")
    func testGuardianPermissions_containsExpected() {
        let perms = Permission.guardianPermissions
        #expect(perms.contains(.viewOwnProgress))
        #expect(!perms.contains(.viewMaterials))
        #expect(!perms.contains(.takeQuizzes))
    }

    @Test("Teacher permissions contains expected permissions")
    func testTeacherPermissions_containsExpected() {
        let perms = Permission.teacherPermissions
        #expect(perms.contains(.viewMaterials))
        #expect(perms.contains(.uploadMaterials))
        #expect(perms.contains(.editMaterials))
        #expect(perms.contains(.createQuizzes))
        #expect(perms.contains(.gradeQuizzes))
        #expect(perms.contains(.viewStudentProgress))
        #expect(perms.contains(.viewReports))
        #expect(!perms.contains(.deleteMaterials))
        #expect(!perms.contains(.manageUsers))
    }

    @Test("Admin permissions contains all permissions")
    func testAdminPermissions_containsAll() {
        let perms = Permission.adminPermissions
        #expect(perms.contains(.viewMaterials))
        #expect(perms.contains(.uploadMaterials))
        #expect(perms.contains(.editMaterials))
        #expect(perms.contains(.deleteMaterials))
        #expect(perms.contains(.takeQuizzes))
        #expect(perms.contains(.createQuizzes))
        #expect(perms.contains(.gradeQuizzes))
        #expect(perms.contains(.viewOwnProgress))
        #expect(perms.contains(.viewStudentProgress))
        #expect(perms.contains(.viewUsers))
        #expect(perms.contains(.manageUsers))
        #expect(perms.contains(.viewReports))
        #expect(perms.contains(.exportReports))
    }

    @Test("defaultPermissions returns correct set for role")
    func testDefaultPermissions_returnsCorrectSet() {
        #expect(Permission.defaultPermissions(for: .student) == Permission.studentPermissions)
        #expect(Permission.defaultPermissions(for: .guardian) == Permission.guardianPermissions)
        #expect(Permission.defaultPermissions(for: .teacher) == Permission.teacherPermissions)
        #expect(Permission.defaultPermissions(for: .admin) == Permission.adminPermissions)
    }
}
