import Testing
import Foundation
import EduFoundation
@testable import EduModels

@Suite("RoleMapper Tests")
struct RoleMapperTests {

    // MARK: - toDomain Tests (Valid Levels)

    @Test("toDomain with student level (1) returns Role with .student")
    func toDomainWithStudentLevel() throws {
        let dto = RoleDTO(id: UUID(), name: "Student Role", level: 1, permissionIDs: [])

        let role = try RoleMapper.toDomain(dto)

        #expect(role.level == .student)
        #expect(role.name == "Student Role")
    }

    @Test("toDomain with teacher level (2) returns Role with .teacher")
    func toDomainWithTeacherLevel() throws {
        let dto = RoleDTO(id: UUID(), name: "Teacher Role", level: 2, permissionIDs: [])

        let role = try RoleMapper.toDomain(dto)

        #expect(role.level == .teacher)
    }

    @Test("toDomain with admin level (3) returns Role with .admin")
    func toDomainWithAdminLevel() throws {
        let dto = RoleDTO(id: UUID(), name: "Admin Role", level: 3, permissionIDs: [])

        let role = try RoleMapper.toDomain(dto)

        #expect(role.level == .admin)
    }

    // MARK: - toDomain Tests (Invalid Levels)

    @Test("toDomain with level zero throws DomainError")
    func toDomainWithLevelZero() {
        let dto = RoleDTO(id: UUID(), name: "Invalid", level: 0, permissionIDs: [])

        #expect(throws: DomainError.self) {
            _ = try RoleMapper.toDomain(dto)
        }
    }

    @Test("toDomain with level four throws DomainError")
    func toDomainWithLevelFour() {
        let dto = RoleDTO(id: UUID(), name: "Invalid", level: 4, permissionIDs: [])

        #expect(throws: DomainError.self) {
            _ = try RoleMapper.toDomain(dto)
        }
    }

    @Test("toDomain with negative level throws DomainError")
    func toDomainWithNegativeLevel() {
        let dto = RoleDTO(id: UUID(), name: "Invalid", level: -1, permissionIDs: [])

        #expect(throws: DomainError.self) {
            _ = try RoleMapper.toDomain(dto)
        }
    }

    // MARK: - toDomain Tests (Name Validation)

    @Test("toDomain with empty name throws RoleValidationError.emptyName")
    func toDomainWithEmptyName() {
        let dto = RoleDTO(id: UUID(), name: "", level: 1, permissionIDs: [])

        #expect(throws: RoleValidationError.emptyName) {
            _ = try RoleMapper.toDomain(dto)
        }
    }

    @Test("toDomain with whitespace-only name throws RoleValidationError.emptyName")
    func toDomainWithWhitespaceName() {
        let dto = RoleDTO(id: UUID(), name: "   ", level: 1, permissionIDs: [])

        #expect(throws: RoleValidationError.emptyName) {
            _ = try RoleMapper.toDomain(dto)
        }
    }

    // MARK: - toDomain Tests (PermissionIDs)

    @Test("toDomain converts permissionIDs array to set removing duplicates")
    func toDomainConvertsPermissionIDsArrayToSet() throws {
        let permID1 = UUID()
        let permID2 = UUID()
        let dto = RoleDTO(id: UUID(), name: "Test", level: 1, permissionIDs: [permID1, permID2, permID1])

        let role = try RoleMapper.toDomain(dto)

        #expect(role.permissionIDs.count == 2)
        #expect(role.permissionIDs.contains(permID1))
        #expect(role.permissionIDs.contains(permID2))
    }

    @Test("toDomain preserves all fields correctly")
    func toDomainPreservesAllFields() throws {
        let id = UUID()
        let permID = UUID()
        let dto = RoleDTO(id: id, name: "Full Role", level: 2, permissionIDs: [permID])

        let role = try RoleMapper.toDomain(dto)

        #expect(role.id == id)
        #expect(role.name == "Full Role")
        #expect(role.level == .teacher)
        #expect(role.permissionIDs.contains(permID))
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts level to rawValue")
    func toDTOConvertsLevelToRawValue() throws {
        let role = try Role(id: UUID(), name: "Admin", level: .admin, permissionIDs: [])

        let dto = RoleMapper.toDTO(role)

        #expect(dto.level == 3)
    }

    @Test("toDTO converts student level to 1")
    func toDTOConvertsStudentLevel() throws {
        let role = try Role(id: UUID(), name: "Student", level: .student, permissionIDs: [])

        let dto = RoleMapper.toDTO(role)

        #expect(dto.level == 1)
    }

    @Test("toDTO converts permissionIDs set to array")
    func toDTOConvertsPermissionIDsSetToArray() throws {
        let permID = UUID()
        let role = try Role(id: UUID(), name: "Test", level: .student, permissionIDs: [permID])

        let dto = RoleMapper.toDTO(role)

        #expect(dto.permissionIDs.count == 1)
        #expect(dto.permissionIDs.contains(permID))
    }

    @Test("toDTO with empty permissionIDs returns empty array")
    func toDTOWithEmptyPermissionIDs() throws {
        let role = try Role(id: UUID(), name: "Test", level: .student, permissionIDs: [])

        let dto = RoleMapper.toDTO(role)

        #expect(dto.permissionIDs.isEmpty)
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves data")
    func roundtripPreservesData() throws {
        let permID = UUID()
        let original = try Role(id: UUID(), name: "Test Role", level: .teacher, permissionIDs: [permID])

        let dto = RoleMapper.toDTO(original)
        let converted = try RoleMapper.toDomain(dto)

        #expect(original == converted)
    }

    @Test("roundtrip preserves all three levels")
    func roundtripPreservesAllLevels() throws {
        let levels: [RoleLevel] = [.student, .teacher, .admin]

        for level in levels {
            let original = try Role(id: UUID(), name: "Level Test", level: level, permissionIDs: [])
            let dto = RoleMapper.toDTO(original)
            let converted = try RoleMapper.toDomain(dto)

            #expect(original == converted)
        }
    }
}
