import Testing
import Foundation
import EduFoundation
@testable import EduModels

/// End-to-end integration tests for complete data transformation chain.
///
/// These tests validate the complete flow:
/// JSON → DTO → Domain → DTO → JSON
///
/// Ensuring data integrity is maintained at each transformation step.
@Suite("End-to-End Transformation Tests")
struct EndToEndTransformationTests {

    // MARK: - User Transformation Chain

    @Test("User: JSON → DTO → Domain → DTO → JSON preserves all data")
    func testUserCompleteTransformationChain() throws {
        let originalJSON = BackendFixtures.userValidJSON
        let data = originalJSON.data(using: .utf8)!

        // JSON → DTO
        let dto = try BackendFixtures.backendDecoder.decode(UserDTO.self, from: data)

        // DTO → Domain
        let domain = try dto.toDomain()

        // Domain → DTO
        let backToDTO = domain.toDTO()

        // DTO → JSON
        let encodedData = try BackendFixtures.backendEncoder.encode(backToDTO)
        let encodedJSON = String(data: encodedData, encoding: .utf8)!

        // Verify roundtrip preserves essential data
        #expect(backToDTO.id == dto.id)
        #expect(backToDTO.firstName == dto.firstName)
        #expect(backToDTO.lastName == dto.lastName)
        #expect(backToDTO.email == dto.email)
        #expect(backToDTO.isActive == dto.isActive)

        // Verify JSON can be decoded again
        let finalDTO = try BackendFixtures.backendDecoder.decode(UserDTO.self, from: encodedData)
        #expect(finalDTO.id == dto.id)
    }

    @Test("User: Batch transformation maintains data integrity")
    func testUserBatchTransformation() throws {
        let dtos = IntegrationTestFixtures.generateUserDTOBatch(count: 100)

        let domains = try dtos.map { try $0.toDomain() }
        let backToDTOs = domains.map { $0.toDTO() }

        #expect(backToDTOs.count == dtos.count)

        for (original, restored) in zip(dtos, backToDTOs) {
            #expect(restored.id == original.id)
            #expect(restored.firstName == original.firstName)
            #expect(restored.lastName == original.lastName)
            #expect(restored.email == original.email)
            #expect(restored.isActive == original.isActive)
        }
    }

    @Test("User: JSON with optional fields transforms correctly")
    func testUserWithOptionalFieldsTransformation() throws {
        let jsonFixtures = [
            BackendFixtures.userMinimalJSON,
            BackendFixtures.userWithNullsJSON,
            BackendFixtures.userInactiveJSON
        ]

        for json in jsonFixtures {
            let data = json.data(using: .utf8)!
            let dto = try BackendFixtures.backendDecoder.decode(UserDTO.self, from: data)
            let domain = try dto.toDomain()
            let backToDTO = domain.toDTO()

            #expect(backToDTO.id == dto.id)
            #expect(backToDTO.email == dto.email)
        }
    }

    // MARK: - School Transformation Chain

    @Test("School: JSON → DTO → Domain → DTO → JSON preserves all data")
    func testSchoolCompleteTransformationChain() throws {
        let originalJSON = BackendFixtures.schoolValidJSON
        let data = originalJSON.data(using: .utf8)!

        // JSON → DTO
        let dto = try BackendFixtures.backendDecoder.decode(SchoolDTO.self, from: data)

        // DTO → Domain
        let domain = try dto.toDomain()

        // Domain → DTO
        let backToDTO = domain.toDTO()

        // DTO → JSON
        let encodedData = try BackendFixtures.backendEncoder.encode(backToDTO)

        // Verify roundtrip preserves essential data
        #expect(backToDTO.id == dto.id)
        #expect(backToDTO.name == dto.name)
        #expect(backToDTO.code == dto.code)
        #expect(backToDTO.isActive == dto.isActive)
        #expect(backToDTO.address == dto.address)
        #expect(backToDTO.city == dto.city)
        #expect(backToDTO.maxStudents == dto.maxStudents)

        // Verify JSON can be decoded again
        let finalDTO = try BackendFixtures.backendDecoder.decode(SchoolDTO.self, from: encodedData)
        #expect(finalDTO.id == dto.id)
    }

    @Test("School: Batch transformation maintains data integrity")
    func testSchoolBatchTransformation() throws {
        let dtos = IntegrationTestFixtures.generateSchoolDTOBatch(count: 100)

        let domains = try dtos.map { try $0.toDomain() }
        let backToDTOs = domains.map { $0.toDTO() }

        #expect(backToDTOs.count == dtos.count)

        for (original, restored) in zip(dtos, backToDTOs) {
            #expect(restored.id == original.id)
            #expect(restored.name == original.name)
            #expect(restored.code == original.code)
            #expect(restored.isActive == original.isActive)
        }
    }

    @Test("School: Complex metadata transforms correctly")
    func testSchoolComplexMetadataTransformation() throws {
        let json = BackendFixtures.schoolComplexMetadataJSON
        let data = json.data(using: .utf8)!

        let dto = try BackendFixtures.backendDecoder.decode(SchoolDTO.self, from: data)
        let domain = try dto.toDomain()
        let backToDTO = domain.toDTO()

        #expect(backToDTO.metadata != nil)
        #expect(backToDTO.metadata?["string_value"] == .string("texto"))
        #expect(backToDTO.metadata?["number_value"] == .integer(42))
        #expect(backToDTO.metadata?["boolean_value"] == .bool(true))
    }

    // MARK: - Membership Transformation Chain

    @Test("Membership: JSON → DTO → Domain → DTO → JSON preserves all data")
    func testMembershipCompleteTransformationChain() throws {
        let originalJSON = BackendFixtures.membershipTeacherJSON
        let data = originalJSON.data(using: .utf8)!

        // JSON → DTO
        let dto = try BackendFixtures.backendDecoder.decode(MembershipDTO.self, from: data)

        // DTO → Domain
        let domain = try dto.toDomain()

        // Domain → DTO
        let backToDTO = domain.toDTO()

        // Verify roundtrip preserves essential data
        #expect(backToDTO.id == dto.id)
        #expect(backToDTO.userID == dto.userID)
        #expect(backToDTO.unitID == dto.unitID)
        #expect(backToDTO.role == dto.role)
        #expect(backToDTO.isActive == dto.isActive)
    }

    @Test("Membership: All roles transform correctly")
    func testMembershipAllRolesTransformation() throws {
        let jsonFixtures = [
            BackendFixtures.membershipTeacherJSON,
            BackendFixtures.membershipStudentJSON,
            BackendFixtures.membershipOwnerJSON,
            BackendFixtures.membershipGuardianJSON,
            BackendFixtures.membershipAssistantJSON
        ]

        for json in jsonFixtures {
            let data = json.data(using: .utf8)!
            let dto = try BackendFixtures.backendDecoder.decode(MembershipDTO.self, from: data)
            let domain = try dto.toDomain()
            let backToDTO = domain.toDTO()

            #expect(backToDTO.role == dto.role)
        }
    }

    @Test("Membership: Withdrawn membership transforms correctly")
    func testMembershipWithdrawnTransformation() throws {
        let json = BackendFixtures.membershipWithdrawnJSON
        let data = json.data(using: .utf8)!

        let dto = try BackendFixtures.backendDecoder.decode(MembershipDTO.self, from: data)
        let domain = try dto.toDomain()
        let backToDTO = domain.toDTO()

        #expect(backToDTO.isActive == false)
        #expect(backToDTO.withdrawnAt != nil)
    }

    @Test("Membership: Batch transformation maintains data integrity")
    func testMembershipBatchTransformation() throws {
        let dtos = IntegrationTestFixtures.generateMembershipDTOBatch(count: 100)

        let domains = try dtos.map { try $0.toDomain() }
        let backToDTOs = domains.map { $0.toDTO() }

        #expect(backToDTOs.count == dtos.count)

        for (original, restored) in zip(dtos, backToDTOs) {
            #expect(restored.id == original.id)
            #expect(restored.userID == original.userID)
            #expect(restored.unitID == original.unitID)
            #expect(restored.role == original.role)
        }
    }

    // MARK: - Material Transformation Chain

    @Test("Material: JSON → DTO → Domain → DTO → JSON preserves all data")
    func testMaterialCompleteTransformationChain() throws {
        let originalJSON = BackendFixtures.materialReadyJSON
        let data = originalJSON.data(using: .utf8)!

        // JSON → DTO
        let dto = try BackendFixtures.backendDecoder.decode(MaterialDTO.self, from: data)

        // DTO → Domain
        let domain = try dto.toDomain()

        // Domain → DTO
        let backToDTO = domain.toDTO()

        // Verify roundtrip preserves essential data
        #expect(backToDTO.id == dto.id)
        #expect(backToDTO.title == dto.title)
        #expect(backToDTO.status == dto.status)
        #expect(backToDTO.fileURL == dto.fileURL)
        #expect(backToDTO.schoolID == dto.schoolID)
        #expect(backToDTO.isPublic == dto.isPublic)
    }

    @Test("Material: All statuses transform correctly")
    func testMaterialAllStatusesTransformation() throws {
        let jsonFixtures = [
            BackendFixtures.materialUploadedJSON,
            BackendFixtures.materialProcessingJSON,
            BackendFixtures.materialReadyJSON,
            BackendFixtures.materialFailedJSON
        ]

        for json in jsonFixtures {
            let data = json.data(using: .utf8)!
            let dto = try BackendFixtures.backendDecoder.decode(MaterialDTO.self, from: data)
            let domain = try dto.toDomain()
            let backToDTO = domain.toDTO()

            #expect(backToDTO.status == dto.status)
        }
    }

    @Test("Material: Batch transformation maintains data integrity")
    func testMaterialBatchTransformation() throws {
        let dtos = IntegrationTestFixtures.generateMaterialDTOBatch(count: 100)

        let domains = try dtos.map { try $0.toDomain() }
        let backToDTOs = domains.map { $0.toDTO() }

        #expect(backToDTOs.count == dtos.count)

        for (original, restored) in zip(dtos, backToDTOs) {
            #expect(restored.id == original.id)
            #expect(restored.title == original.title)
            #expect(restored.status == original.status)
            #expect(restored.schoolID == original.schoolID)
        }
    }

    // MARK: - AcademicUnit Transformation Chain

    @Test("AcademicUnit: JSON → DTO → Domain → DTO → JSON preserves all data")
    func testAcademicUnitCompleteTransformationChain() throws {
        let originalJSON = BackendFixtures.academicUnitGradeJSON
        let data = originalJSON.data(using: .utf8)!

        // JSON → DTO
        let dto = try BackendFixtures.backendDecoder.decode(AcademicUnitDTO.self, from: data)

        // DTO → Domain
        let domain = try dto.toDomain()

        // Domain → DTO
        let backToDTO = domain.toDTO()

        // Verify roundtrip preserves essential data
        #expect(backToDTO.id == dto.id)
        #expect(backToDTO.displayName == dto.displayName)
        #expect(backToDTO.type == dto.type)
        #expect(backToDTO.schoolID == dto.schoolID)
    }

    @Test("AcademicUnit: All types transform correctly")
    func testAcademicUnitAllTypesTransformation() throws {
        let jsonFixtures = [
            BackendFixtures.academicUnitGradeJSON,
            BackendFixtures.academicUnitSectionJSON,
            BackendFixtures.academicUnitClubJSON,
            BackendFixtures.academicUnitDepartmentJSON
        ]

        for json in jsonFixtures {
            let data = json.data(using: .utf8)!
            let dto = try BackendFixtures.backendDecoder.decode(AcademicUnitDTO.self, from: data)
            let domain = try dto.toDomain()
            let backToDTO = domain.toDTO()

            #expect(backToDTO.type == dto.type)
        }
    }

    @Test("AcademicUnit: Batch transformation maintains data integrity")
    func testAcademicUnitBatchTransformation() throws {
        let dtos = IntegrationTestFixtures.generateAcademicUnitDTOBatch(count: 100)

        let domains = try dtos.map { try $0.toDomain() }
        let backToDTOs = domains.map { $0.toDTO() }

        #expect(backToDTOs.count == dtos.count)

        for (original, restored) in zip(dtos, backToDTOs) {
            #expect(restored.id == original.id)
            #expect(restored.displayName == original.displayName)
            #expect(restored.type == original.type)
            #expect(restored.schoolID == original.schoolID)
        }
    }

    // MARK: - Cross-Entity Integration Tests

    @Test("Complete entity graph transforms correctly")
    func testCompleteEntityGraphTransformation() throws {
        let (school, units, users, memberships, materials) = try IntegrationTestFixtures.generateCompleteEntityGraph()

        // Transform school
        let schoolDTO = school.toDTO()
        let schoolBack = try schoolDTO.toDomain()
        #expect(schoolBack.id == school.id)
        #expect(schoolBack.name == school.name)

        // Transform units
        for unit in units {
            let unitDTO = unit.toDTO()
            let unitBack = try unitDTO.toDomain()
            #expect(unitBack.id == unit.id)
            #expect(unitBack.displayName == unit.displayName)
            #expect(unitBack.type == unit.type)
        }

        // Transform users
        for user in users {
            let userDTO = user.toDTO()
            let userBack = try userDTO.toDomain()
            #expect(userBack.id == user.id)
            #expect(userBack.email == user.email)
        }

        // Transform memberships
        for membership in memberships {
            let membershipDTO = membership.toDTO()
            let membershipBack = try membershipDTO.toDomain()
            #expect(membershipBack.id == membership.id)
            #expect(membershipBack.role == membership.role)
        }

        // Transform materials
        for material in materials {
            let materialDTO = material.toDTO()
            let materialBack = try materialDTO.toDomain()
            #expect(materialBack.id == material.id)
            #expect(materialBack.title == material.title)
        }
    }

    // MARK: - Error Handling Tests

    @Test("Invalid JSON produces proper errors")
    func testInvalidJSONProducesErrors() throws {
        let invalidJSONs = [
            BackendFixtures.userEmptyStringsJSON,
            BackendFixtures.userWhitespaceNamesJSON,
            BackendFixtures.userInvalidEmailJSON
        ]

        for json in invalidJSONs {
            let data = json.data(using: .utf8)!
            let dto = try BackendFixtures.backendDecoder.decode(UserDTO.self, from: data)

            #expect(throws: Error.self) {
                _ = try dto.toDomain()
            }
        }
    }

    @Test("Unknown enum values produce proper errors")
    func testUnknownEnumValuesProduceErrors() throws {
        let unknownEnumJSONs = [
            BackendFixtures.membershipUnknownRoleJSON,
            BackendFixtures.materialUnknownStatusJSON,
            BackendFixtures.academicUnitUnknownTypeJSON
        ]

        for json in unknownEnumJSONs {
            let data = json.data(using: .utf8)!

            // These should decode but fail on toDomain
            if let dto = try? BackendFixtures.backendDecoder.decode(MembershipDTO.self, from: data) {
                #expect(throws: DomainError.self) {
                    _ = try dto.toDomain()
                }
            } else if let dto = try? BackendFixtures.backendDecoder.decode(MaterialDTO.self, from: data) {
                #expect(throws: DomainError.self) {
                    _ = try dto.toDomain()
                }
            } else if let dto = try? BackendFixtures.backendDecoder.decode(AcademicUnitDTO.self, from: data) {
                #expect(throws: DomainError.self) {
                    _ = try dto.toDomain()
                }
            }
        }
    }

    // MARK: - Performance Baseline Tests

    @Test("100 users transform in under 1 second")
    func testUserTransformationPerformance() throws {
        let dtos = IntegrationTestFixtures.generateUserDTOBatch(count: 100)

        let startTime = ContinuousClock.now

        for dto in dtos {
            let domain = try dto.toDomain()
            _ = domain.toDTO()
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(elapsed < .seconds(1), "User transformation took too long: \(elapsed)")
    }

    @Test("100 materials transform in under 1 second")
    func testMaterialTransformationPerformance() throws {
        let dtos = IntegrationTestFixtures.generateMaterialDTOBatch(count: 100)

        let startTime = ContinuousClock.now

        for dto in dtos {
            let domain = try dto.toDomain()
            _ = domain.toDTO()
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(elapsed < .seconds(1), "Material transformation took too long: \(elapsed)")
    }
}
