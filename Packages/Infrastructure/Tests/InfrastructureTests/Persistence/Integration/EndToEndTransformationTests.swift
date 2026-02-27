import Testing
import Foundation
import SwiftData
import EduCore
@testable import EduPersistence

/// End-to-end transformation tests for the complete chain:
/// JSON → DTO → Domain → SwiftData → Domain → DTO → JSON
///
/// These tests verify data integrity through the entire transformation pipeline,
/// ensuring no data loss or corruption occurs at any stage.
@Suite("End-to-End Transformation Tests", .serialized)
struct EndToEndTransformationTests {

    // MARK: - Setup Helper

    private func setupRepositories() async throws -> (
        userRepo: LocalUserRepository,
        schoolRepo: LocalSchoolRepository,
        membershipRepo: LocalMembershipRepository,
        materialRepo: LocalMaterialRepository,
        unitRepo: LocalAcademicUnitRepository
    ) {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return (
            LocalUserRepository(containerProvider: provider),
            LocalSchoolRepository(containerProvider: provider),
            LocalMembershipRepository(containerProvider: provider),
            LocalMaterialRepository(containerProvider: provider),
            LocalAcademicUnitRepository(containerProvider: provider)
        )
    }

    // MARK: - User E2E Tests

    @Test("User: JSON → DTO → Domain → SwiftData → Domain → DTO → JSON roundtrip")
    func testUserFullRoundtrip() async throws {
        let repos = try await setupRepositories()

        // Generate original JSON
        let originalJSONs = IntegrationTestFixtures.generateUserJSONBatch(count: 5)

        for originalJSON in originalJSONs {
            // JSON → DTO
            let jsonData = Data(originalJSON.utf8)
            let dto = try await IntegrationTestFixtures.decode(UserDTO.self, from: jsonData)

            // DTO → Domain
            let domain = try dto.toDomain()

            // Domain → SwiftData (save)
            try await repos.userRepo.save(domain)

            // SwiftData → Domain (fetch)
            let restored = try await repos.userRepo.get(id: domain.id)
            #expect(restored != nil)

            // Domain → DTO
            let restoredDTO = restored!.toDTO()

            // DTO → JSON
            let restoredJSONData = try await IntegrationTestFixtures.encode(restoredDTO)
            let restoredDTO2 = try await IntegrationTestFixtures.decode(UserDTO.self, from: restoredJSONData)

            // Verify data integrity
            #expect(restoredDTO2.id == dto.id)
            #expect(restoredDTO2.firstName == dto.firstName)
            #expect(restoredDTO2.lastName == dto.lastName)
            #expect(restoredDTO2.email == dto.email)
            #expect(restoredDTO2.isActive == dto.isActive)
        }
    }

    @Test("User batch: 100 entities through complete transformation chain")
    func testUserBatchTransformation() async throws {
        let repos = try await setupRepositories()

        // Generate DTOs
        let dtos = IntegrationTestFixtures.generateUserDTOBatch(count: 100)

        // DTO → Domain → SwiftData
        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.userRepo.save(domain)
        }

        // SwiftData → Domain → DTO
        let allUsers = try await repos.userRepo.list()
        #expect(allUsers.count >= 100)

        let restoredDTOs = allUsers.map { $0.toDTO() }
        #expect(restoredDTOs.count >= 100)

        // Verify each original DTO has a matching restored DTO
        for dto in dtos {
            let matching = restoredDTOs.first { $0.id == dto.id }
            #expect(matching != nil)
            #expect(matching?.firstName == dto.firstName)
            #expect(matching?.lastName == dto.lastName)
            #expect(matching?.email == dto.email)
        }
    }

    // MARK: - School E2E Tests

    @Test("School: JSON → DTO → Domain → SwiftData → Domain → DTO → JSON roundtrip")
    func testSchoolFullRoundtrip() async throws {
        let repos = try await setupRepositories()

        let originalJSONs = IntegrationTestFixtures.generateSchoolJSONBatch(count: 5)

        for originalJSON in originalJSONs {
            let jsonData = Data(originalJSON.utf8)
            let dto = try await IntegrationTestFixtures.decode(SchoolDTO.self, from: jsonData)
            let domain = try dto.toDomain()

            try await repos.schoolRepo.save(domain)

            let restored = try await repos.schoolRepo.get(id: domain.id)
            #expect(restored != nil)

            let restoredDTO = restored!.toDTO()
            let restoredJSONData = try await IntegrationTestFixtures.encode(restoredDTO)
            let restoredDTO2 = try await IntegrationTestFixtures.decode(SchoolDTO.self, from: restoredJSONData)

            #expect(restoredDTO2.id == dto.id)
            #expect(restoredDTO2.name == dto.name)
            #expect(restoredDTO2.code == dto.code)
            #expect(restoredDTO2.isActive == dto.isActive)
            #expect(restoredDTO2.address == dto.address)
            #expect(restoredDTO2.city == dto.city)
            #expect(restoredDTO2.country == dto.country)
            #expect(restoredDTO2.contactEmail == dto.contactEmail)
            #expect(restoredDTO2.maxStudents == dto.maxStudents)
            #expect(restoredDTO2.maxTeachers == dto.maxTeachers)
            #expect(restoredDTO2.subscriptionTier == dto.subscriptionTier)
        }
    }

    @Test("School batch: 100 entities through complete transformation chain")
    func testSchoolBatchTransformation() async throws {
        let repos = try await setupRepositories()

        let dtos = IntegrationTestFixtures.generateSchoolDTOBatch(count: 100)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.schoolRepo.save(domain)
        }

        let allSchools = try await repos.schoolRepo.list()
        #expect(allSchools.count >= 100)

        let restoredDTOs = allSchools.map { $0.toDTO() }

        for dto in dtos {
            let matching = restoredDTOs.first { $0.id == dto.id }
            #expect(matching != nil)
            #expect(matching?.name == dto.name)
            #expect(matching?.code == dto.code)
        }
    }

    // MARK: - Membership E2E Tests

    @Test("Membership: JSON → DTO → Domain → SwiftData → Domain → DTO → JSON roundtrip")
    func testMembershipFullRoundtrip() async throws {
        let repos = try await setupRepositories()

        let originalJSONs = IntegrationTestFixtures.generateMembershipJSONBatch(count: 5)

        for originalJSON in originalJSONs {
            let jsonData = Data(originalJSON.utf8)
            let dto = try await IntegrationTestFixtures.decode(MembershipDTO.self, from: jsonData)
            let domain = try dto.toDomain()

            try await repos.membershipRepo.save(domain)

            let restored = try await repos.membershipRepo.get(id: domain.id)
            #expect(restored != nil)

            let restoredDTO = restored!.toDTO()
            let restoredJSONData = try await IntegrationTestFixtures.encode(restoredDTO)
            let restoredDTO2 = try await IntegrationTestFixtures.decode(MembershipDTO.self, from: restoredJSONData)

            #expect(restoredDTO2.id == dto.id)
            #expect(restoredDTO2.userID == dto.userID)
            #expect(restoredDTO2.unitID == dto.unitID)
            #expect(restoredDTO2.role == dto.role)
            #expect(restoredDTO2.isActive == dto.isActive)
        }
    }

    @Test("Membership batch: 100 entities through complete transformation chain")
    func testMembershipBatchTransformation() async throws {
        let repos = try await setupRepositories()

        let dtos = IntegrationTestFixtures.generateMembershipDTOBatch(count: 100)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.membershipRepo.save(domain)
        }

        let allMemberships = try await repos.membershipRepo.list()
        #expect(allMemberships.count >= 100)

        for dto in dtos {
            let matching = allMemberships.first { $0.id == dto.id }
            #expect(matching != nil)
            #expect(matching?.role.rawValue == dto.role)
        }
    }

    // MARK: - Material E2E Tests

    @Test("Material: JSON → DTO → Domain → SwiftData → Domain → DTO → JSON roundtrip")
    func testMaterialFullRoundtrip() async throws {
        let repos = try await setupRepositories()

        let schoolID = UUID()
        let originalJSONs = IntegrationTestFixtures.generateMaterialJSONBatch(count: 5, schoolID: schoolID)

        for originalJSON in originalJSONs {
            let jsonData = Data(originalJSON.utf8)
            let dto = try await IntegrationTestFixtures.decode(MaterialDTO.self, from: jsonData)
            let domain = try dto.toDomain()

            try await repos.materialRepo.save(domain)

            let restored = try await repos.materialRepo.get(id: domain.id)
            #expect(restored != nil)

            let restoredDTO = restored!.toDTO()
            let restoredJSONData = try await IntegrationTestFixtures.encode(restoredDTO)
            let restoredDTO2 = try await IntegrationTestFixtures.decode(MaterialDTO.self, from: restoredJSONData)

            #expect(restoredDTO2.id == dto.id)
            #expect(restoredDTO2.title == dto.title)
            #expect(restoredDTO2.status == dto.status)
            #expect(restoredDTO2.schoolID == dto.schoolID)
            #expect(restoredDTO2.isPublic == dto.isPublic)
        }
    }

    @Test("Material batch: 100 entities through complete transformation chain")
    func testMaterialBatchTransformation() async throws {
        let repos = try await setupRepositories()

        let schoolID = UUID()
        let dtos = IntegrationTestFixtures.generateMaterialDTOBatch(count: 100, schoolID: schoolID)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.materialRepo.save(domain)
        }

        let allMaterials = try await repos.materialRepo.list()
        #expect(allMaterials.count >= 100)

        for dto in dtos {
            let matching = allMaterials.first { $0.id == dto.id }
            #expect(matching != nil)
            #expect(matching?.title == dto.title)
        }
    }

    // MARK: - AcademicUnit E2E Tests

    @Test("AcademicUnit: JSON → DTO → Domain → SwiftData → Domain → DTO → JSON roundtrip")
    func testAcademicUnitFullRoundtrip() async throws {
        let repos = try await setupRepositories()

        let schoolID = UUID()
        let originalJSONs = IntegrationTestFixtures.generateAcademicUnitJSONBatch(count: 5, schoolID: schoolID)

        for originalJSON in originalJSONs {
            let jsonData = Data(originalJSON.utf8)
            let dto = try await IntegrationTestFixtures.decode(AcademicUnitDTO.self, from: jsonData)
            let domain = try dto.toDomain()

            try await repos.unitRepo.save(domain)

            let restored = try await repos.unitRepo.get(id: domain.id)
            #expect(restored != nil)

            let restoredDTO = restored!.toDTO()
            let restoredJSONData = try await IntegrationTestFixtures.encode(restoredDTO)
            let restoredDTO2 = try await IntegrationTestFixtures.decode(AcademicUnitDTO.self, from: restoredJSONData)

            #expect(restoredDTO2.id == dto.id)
            #expect(restoredDTO2.displayName == dto.displayName)
            #expect(restoredDTO2.type == dto.type)
            #expect(restoredDTO2.schoolID == dto.schoolID)
        }
    }

    @Test("AcademicUnit batch: 100 entities through complete transformation chain")
    func testAcademicUnitBatchTransformation() async throws {
        let repos = try await setupRepositories()

        let schoolID = UUID()
        let dtos = IntegrationTestFixtures.generateAcademicUnitDTOBatch(count: 100, schoolID: schoolID)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.unitRepo.save(domain)
        }

        let allUnits = try await repos.unitRepo.list()
        #expect(allUnits.count >= 100)

        for dto in dtos {
            let matching = allUnits.first { $0.id == dto.id }
            #expect(matching != nil)
            #expect(matching?.displayName == dto.displayName)
        }
    }

    // MARK: - Complete Entity Graph Tests

    @Test("Complete entity graph roundtrip preserves all relationships")
    func testCompleteEntityGraphRoundtrip() async throws {
        let repos = try await setupRepositories()

        // Generate complete graph
        let (school, units, users, memberships, materials) =
            try IntegrationTestFixtures.generateCompleteEntityGraph()

        // Save all entities
        try await repos.schoolRepo.save(school)

        for unit in units {
            try await repos.unitRepo.save(unit)
        }

        for user in users {
            try await repos.userRepo.save(user)
        }

        for membership in memberships {
            try await repos.membershipRepo.save(membership)
        }

        for material in materials {
            try await repos.materialRepo.save(material)
        }

        // Verify all entities are saved and retrievable
        let restoredSchool = try await repos.schoolRepo.get(id: school.id)
        #expect(restoredSchool != nil)
        #expect(restoredSchool?.name == school.name)

        let restoredUnits = try await repos.unitRepo.listBySchool(schoolID: school.id)
        #expect(restoredUnits.count == units.count)

        let restoredUsers = try await repos.userRepo.list()
        #expect(restoredUsers.count >= users.count)

        let restoredMemberships = try await repos.membershipRepo.list()
        #expect(restoredMemberships.count >= memberships.count)

        let restoredMaterials = try await repos.materialRepo.listBySchool(schoolID: school.id)
        #expect(restoredMaterials.count == materials.count)

        // Verify relationships are preserved
        for membership in memberships {
            let restored = try await repos.membershipRepo.get(id: membership.id)
            #expect(restored?.userID == membership.userID)
            #expect(restored?.unitID == membership.unitID)
        }

        for material in materials {
            let restored = try await repos.materialRepo.get(id: material.id)
            #expect(restored?.schoolID == material.schoolID)
        }
    }

    // MARK: - Error Handling Tests

    @Test("Invalid JSON produces decoding errors")
    func testInvalidJSONDecodingErrors() async throws {
        let invalidJSONs = IntegrationTestFixtures.generateInvalidUserJSON()

        for invalidJSON in invalidJSONs {
            let jsonData = Data(invalidJSON.utf8)
            do {
                _ = try await IntegrationTestFixtures.decode(UserDTO.self, from: jsonData)
                Issue.record("Expected decoding error for invalid JSON")
            } catch {
                // Expected: decoding should fail
            }
        }
    }

    @Test("Invalid enum values produce domain errors")
    func testInvalidEnumValueErrors() async throws {
        let invalidJSONs = IntegrationTestFixtures.generateInvalidEnumJSON()

        for invalidJSON in invalidJSONs {
            let jsonData = Data(invalidJSON.utf8)
            // DTOs decode strings for enums, validation happens in toDomain()
            do {
                if invalidJSON.contains("\"role\"") {
                    let dto = try await IntegrationTestFixtures.decode(MembershipDTO.self, from: jsonData)
                    _ = try dto.toDomain() // This should throw for invalid role
                    Issue.record("Expected domain error for invalid role")
                } else if invalidJSON.contains("\"status\"") {
                    let dto = try await IntegrationTestFixtures.decode(MaterialDTO.self, from: jsonData)
                    _ = try dto.toDomain() // This should throw for invalid status
                    Issue.record("Expected domain error for invalid status")
                } else if invalidJSON.contains("\"type\"") {
                    let dto = try await IntegrationTestFixtures.decode(AcademicUnitDTO.self, from: jsonData)
                    _ = try dto.toDomain() // This should throw for invalid type
                    Issue.record("Expected domain error for invalid type")
                }
            } catch {
                // Expected: domain conversion should fail for invalid enum values
            }
        }
    }

    // MARK: - Timestamp Precision Tests

    @Test("Timestamps maintain precision through transformation chain")
    func testTimestampPrecision() async throws {
        let repos = try await setupRepositories()

        // Create a timestamp with specific precision
        let specificDate = Date(timeIntervalSince1970: 1704067200.123)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: specificDate)

        let json = """
        {
            "id": "\(UUID().uuidString)",
            "first_name": "Timestamp",
            "last_name": "Test",
            "email": "timestamp@test.com",
            "is_active": true,
            "created_at": "\(dateString)",
            "updated_at": "\(dateString)"
        }
        """

        let jsonData = Data(json.utf8)

        // Note: Standard ISO8601DateFormatter may lose fractional seconds
        // This test verifies the transformation chain handles dates consistently
        let dto = try await IntegrationTestFixtures.decode(UserDTO.self, from: jsonData)
        let domain = try dto.toDomain()

        try await repos.userRepo.save(domain)

        let restored = try await repos.userRepo.get(id: domain.id)
        #expect(restored != nil)

        let restoredDTO = restored!.toDTO()
        _ = try await IntegrationTestFixtures.encode(restoredDTO)

        // Verify dates are consistent (within 1 second tolerance for precision loss)
        let timeDifference = abs(restored!.createdAt.timeIntervalSince(dto.createdAt))
        #expect(timeDifference < 1.0, "Date precision should be maintained within 1 second")
    }

    // MARK: - Performance Baseline Tests

    @Test("100 users transformation chain completes under 5 seconds")
    func testUserTransformationPerformance() async throws {
        let repos = try await setupRepositories()
        let startTime = ContinuousClock.now

        let dtos = IntegrationTestFixtures.generateUserDTOBatch(count: 100)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.userRepo.save(domain)
        }

        let allUsers = try await repos.userRepo.list()
        _ = allUsers.map { $0.toDTO() }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "Transformation should complete under 5 seconds")
    }

    @Test("100 schools transformation chain completes under 5 seconds")
    func testSchoolTransformationPerformance() async throws {
        let repos = try await setupRepositories()
        let startTime = ContinuousClock.now

        let dtos = IntegrationTestFixtures.generateSchoolDTOBatch(count: 100)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.schoolRepo.save(domain)
        }

        let allSchools = try await repos.schoolRepo.list()
        _ = allSchools.map { $0.toDTO() }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "Transformation should complete under 5 seconds")
    }

    @Test("100 memberships transformation chain completes under 5 seconds")
    func testMembershipTransformationPerformance() async throws {
        let repos = try await setupRepositories()
        let startTime = ContinuousClock.now

        let dtos = IntegrationTestFixtures.generateMembershipDTOBatch(count: 100)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.membershipRepo.save(domain)
        }

        let allMemberships = try await repos.membershipRepo.list()
        _ = allMemberships.map { $0.toDTO() }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "Transformation should complete under 5 seconds")
    }

    @Test("100 materials transformation chain completes under 5 seconds")
    func testMaterialTransformationPerformance() async throws {
        let repos = try await setupRepositories()
        let startTime = ContinuousClock.now

        let schoolID = UUID()
        let dtos = IntegrationTestFixtures.generateMaterialDTOBatch(count: 100, schoolID: schoolID)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.materialRepo.save(domain)
        }

        let allMaterials = try await repos.materialRepo.list()
        _ = allMaterials.map { $0.toDTO() }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "Transformation should complete under 5 seconds")
    }

    @Test("100 academic units transformation chain completes under 5 seconds")
    func testAcademicUnitTransformationPerformance() async throws {
        let repos = try await setupRepositories()
        let startTime = ContinuousClock.now

        let schoolID = UUID()
        let dtos = IntegrationTestFixtures.generateAcademicUnitDTOBatch(count: 100, schoolID: schoolID)

        for dto in dtos {
            let domain = try dto.toDomain()
            try await repos.unitRepo.save(domain)
        }

        let allUnits = try await repos.unitRepo.list()
        _ = allUnits.map { $0.toDTO() }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "Transformation should complete under 5 seconds")
    }
}
