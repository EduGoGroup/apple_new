import Testing
import Foundation
import EduFoundation
@testable import EduModels

@Suite("MembershipMapper Tests")
struct MembershipMapperTests {

    // MARK: - Test Data

    private let userID = UUID()
    private let unitID = UUID()

    // MARK: - toDomain Tests

    @Test("toDomain with valid DTO returns Membership")
    func toDomainWithValidDTO() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let enrolledAt = Date(timeIntervalSince1970: 1000)

        let dto = MembershipDTO(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: "teacher",
            isActive: true,
            enrolledAt: enrolledAt,
            withdrawnAt: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let membership = try MembershipMapper.toDomain(dto)

        #expect(membership.id == dto.id)
        #expect(membership.userID == userID)
        #expect(membership.unitID == unitID)
        #expect(membership.role == .teacher)
        #expect(membership.isActive == true)
        #expect(membership.enrolledAt == enrolledAt)
        #expect(membership.withdrawnAt == nil)
        #expect(membership.createdAt == createdAt)
        #expect(membership.updatedAt == updatedAt)
    }

    @Test("toDomain with withdrawn membership")
    func toDomainWithWithdrawnMembership() throws {
        let withdrawnAt = Date(timeIntervalSince1970: 3000)

        let dto = MembershipDTO(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: "student",
            isActive: false,
            enrolledAt: Date(),
            withdrawnAt: withdrawnAt,
            createdAt: Date(),
            updatedAt: Date()
        )

        let membership = try MembershipMapper.toDomain(dto)

        #expect(membership.isActive == false)
        #expect(membership.withdrawnAt == withdrawnAt)
        #expect(membership.isCurrentlyActive == false)
    }

    @Test("toDomain with all role types")
    func toDomainWithAllRoleTypes() throws {
        let roles = ["owner", "teacher", "assistant", "student", "guardian"]
        let expectedRoles: [MembershipRole] = [.owner, .teacher, .assistant, .student, .guardian]

        for (roleString, expectedRole) in zip(roles, expectedRoles) {
            let dto = MembershipDTO(
                id: UUID(),
                userID: userID,
                unitID: unitID,
                role: roleString,
                isActive: true,
                enrolledAt: Date(),
                withdrawnAt: nil,
                createdAt: Date(),
                updatedAt: Date()
            )

            let membership = try MembershipMapper.toDomain(dto)
            #expect(membership.role == expectedRole)
        }
    }

    @Test("toDomain with unknown role throws")
    func toDomainWithUnknownRole() {
        let dto = MembershipDTO(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: "unknown_role",
            isActive: true,
            enrolledAt: Date(),
            withdrawnAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(throws: DomainError.self) {
            _ = try MembershipMapper.toDomain(dto)
        }
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts Membership correctly")
    func toDTOConvertsCorrectly() {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let membership = Membership(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: .guardian,
            isActive: false,
            enrolledAt: createdAt,
            withdrawnAt: updatedAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let dto = MembershipMapper.toDTO(membership)

        #expect(dto.id == membership.id)
        #expect(dto.userID == membership.userID)
        #expect(dto.unitID == membership.unitID)
        #expect(dto.role == "guardian")
        #expect(dto.isActive == false)
        #expect(dto.withdrawnAt == updatedAt)
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves data")
    func roundtripPreservesData() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)
        let enrolledAt = Date(timeIntervalSince1970: 1000)

        let original = Membership(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: .assistant,
            isActive: true,
            enrolledAt: enrolledAt,
            withdrawnAt: nil,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let dto = MembershipMapper.toDTO(original)
        let converted = try MembershipMapper.toDomain(dto)

        #expect(original == converted)
    }

    @Test("roundtrip with withdrawn membership preserves data")
    func roundtripWithWithdrawnMembership() throws {
        let withdrawnAt = Date(timeIntervalSince1970: 3000)

        let original = Membership(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: .student,
            isActive: false,
            enrolledAt: Date(timeIntervalSince1970: 1000),
            withdrawnAt: withdrawnAt,
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 2000)
        )

        let dto = MembershipMapper.toDTO(original)
        let converted = try MembershipMapper.toDomain(dto)

        #expect(original == converted)
    }

    // MARK: - Extension Method Tests

    @Test("MembershipDTO.toDomain() works correctly")
    func dtoToDomainExtension() throws {
        let dto = MembershipDTO(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: "owner",
            isActive: true,
            enrolledAt: Date(),
            withdrawnAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let membership = try dto.toDomain()

        #expect(membership.id == dto.id)
        #expect(membership.role == .owner)
    }

    @Test("Membership.toDTO() works correctly")
    func membershipToDTOExtension() {
        let membership = Membership(
            userID: userID,
            unitID: unitID,
            role: .teacher
        )

        let dto = membership.toDTO()

        #expect(dto.id == membership.id)
        #expect(dto.role == "teacher")
    }

    // MARK: - JSON Serialization Tests

    @Test("MembershipDTO encodes to JSON with snake_case keys")
    func dtoEncodesToSnakeCaseJSON() throws {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1705318200)
        let updatedAt = Date(timeIntervalSince1970: 1705459500)
        let enrolledAt = Date(timeIntervalSince1970: 1705318200)
        let withdrawnAt = Date(timeIntervalSince1970: 1705400000)

        let dto = MembershipDTO(
            id: id,
            userID: userID,
            unitID: unitID,
            role: "student",
            isActive: true,
            enrolledAt: enrolledAt,
            withdrawnAt: withdrawnAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"user_id\""))
        #expect(json.contains("\"unit_id\""))
        #expect(json.contains("\"is_active\""))
        #expect(json.contains("\"enrolled_at\""))
        #expect(json.contains("\"withdrawn_at\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))
        #expect(!json.contains("\"userID\""))
        #expect(!json.contains("\"unitID\""))
    }

    @Test("MembershipDTO decodes from JSON with snake_case keys")
    func dtoDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "660e8400-e29b-41d4-a716-446655440001",
            "unit_id": "770e8400-e29b-41d4-a716-446655440002",
            "role": "teacher",
            "is_active": true,
            "enrolled_at": "2024-01-15T10:30:00Z",
            "withdrawn_at": null,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-20T14:45:00Z"
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(MembershipDTO.self, from: data)

        #expect(dto.role == "teacher")
        #expect(dto.isActive == true)
        #expect(dto.withdrawnAt == nil)
    }

    @Test("MembershipDTO decodes from JSON with withdrawn_at")
    func dtoDecodesFromJSONWithWithdrawnAt() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "user_id": "660e8400-e29b-41d4-a716-446655440001",
            "unit_id": "770e8400-e29b-41d4-a716-446655440002",
            "role": "student",
            "is_active": false,
            "enrolled_at": "2024-01-15T10:30:00Z",
            "withdrawn_at": "2024-06-15T10:30:00Z",
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-06-15T10:30:00Z"
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(MembershipDTO.self, from: data)

        #expect(dto.isActive == false)
        #expect(dto.withdrawnAt != nil)
    }

    // MARK: - Backend Fixture Tests

    @Test("Membership teacher decodes from backend JSON fixture")
    func membershipTeacherFromBackendFixture() throws {
        let json = BackendFixtures.membershipTeacherJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(MembershipDTO.self, from: data)
        let membership = try dto.toDomain()

        #expect(membership.role == .teacher)
        #expect(membership.isActive == true)
        #expect(membership.withdrawnAt == nil)
        #expect(membership.isCurrentlyActive == true)
    }

    @Test("Membership student decodes from backend JSON fixture")
    func membershipStudentFromBackendFixture() throws {
        let json = BackendFixtures.membershipStudentJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(MembershipDTO.self, from: data)
        let membership = try dto.toDomain()

        #expect(membership.role == .student)
        #expect(membership.isActive == true)
    }

    @Test("Membership owner decodes from backend JSON fixture")
    func membershipOwnerFromBackendFixture() throws {
        let json = BackendFixtures.membershipOwnerJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(MembershipDTO.self, from: data)
        let membership = try dto.toDomain()

        #expect(membership.role == .owner)
        #expect(membership.isActive == true)
    }

    @Test("Membership guardian decodes from backend JSON fixture")
    func membershipGuardianFromBackendFixture() throws {
        let json = BackendFixtures.membershipGuardianJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(MembershipDTO.self, from: data)
        let membership = try dto.toDomain()

        #expect(membership.role == .guardian)
        #expect(membership.isActive == true)
    }

    @Test("Membership assistant decodes from backend JSON fixture")
    func membershipAssistantFromBackendFixture() throws {
        let json = BackendFixtures.membershipAssistantJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(MembershipDTO.self, from: data)
        let membership = try dto.toDomain()

        #expect(membership.role == .assistant)
        #expect(membership.isActive == true)
    }

    @Test("Membership withdrawn decodes from backend JSON fixture")
    func membershipWithdrawnFromBackendFixture() throws {
        let json = BackendFixtures.membershipWithdrawnJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(MembershipDTO.self, from: data)
        let membership = try dto.toDomain()

        #expect(membership.role == .student)
        #expect(membership.isActive == false)
        #expect(membership.withdrawnAt != nil)
        #expect(membership.isCurrentlyActive == false)
    }

    @Test("Membership full serialization roundtrip with backend fixture")
    func membershipFullSerializationRoundtrip() throws {
        let json = BackendFixtures.membershipTeacherJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dto = try decoder.decode(MembershipDTO.self, from: data)
        let membership = try dto.toDomain()

        // Serialize back to DTO and JSON
        let backToDTO = membership.toDTO()
        let encoder = BackendFixtures.backendEncoder
        let encodedData = try encoder.encode(backToDTO)
        let encodedJSON = String(data: encodedData, encoding: .utf8)!

        // Verify snake_case keys
        #expect(encodedJSON.contains("\"user_id\""))
        #expect(encodedJSON.contains("\"unit_id\""))
        #expect(encodedJSON.contains("\"is_active\""))
        #expect(encodedJSON.contains("\"enrolled_at\""))
        #expect(encodedJSON.contains("\"created_at\""))
        #expect(encodedJSON.contains("\"updated_at\""))

        // Deserialize again and verify equality
        let decodedDTO = try decoder.decode(MembershipDTO.self, from: encodedData)
        let decodedMembership = try decodedDTO.toDomain()

        #expect(membership == decodedMembership)
    }

    @Test("Membership JSON keys match backend specification")
    func membershipJSONKeysMatchBackendSpec() throws {
        let membership = Membership(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: .teacher,
            isActive: true,
            enrolledAt: Date(),
            withdrawnAt: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        let dto = membership.toDTO()
        let encoder = BackendFixtures.backendEncoder
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!

        // Expected keys from edu-admin swagger.json
        #expect(json.contains("\"id\""))
        #expect(json.contains("\"user_id\""))
        #expect(json.contains("\"unit_id\""))
        #expect(json.contains("\"role\""))
        #expect(json.contains("\"is_active\""))
        #expect(json.contains("\"enrolled_at\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))

        // Should NOT contain camelCase keys
        #expect(!json.contains("\"userID\""))
        #expect(!json.contains("\"unitID\""))
        #expect(!json.contains("\"isActive\""))
        #expect(!json.contains("\"enrolledAt\""))
        #expect(!json.contains("\"withdrawnAt\""))
    }

    @Test("Memberships array from backend fixture")
    func membershipsArrayFromBackendFixture() throws {
        let json = BackendFixtures.membershipsArrayJSON
        let data = json.data(using: .utf8)!

        let decoder = BackendFixtures.backendDecoder
        let dtos = try decoder.decode([MembershipDTO].self, from: data)
        let memberships = try dtos.map { try $0.toDomain() }

        #expect(memberships.count == 2)
        #expect(memberships[0].role == .teacher)
        #expect(memberships[1].role == .student)
    }
}
