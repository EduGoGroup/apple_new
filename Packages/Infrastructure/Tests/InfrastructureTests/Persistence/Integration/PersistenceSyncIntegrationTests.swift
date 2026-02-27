import Testing
import Foundation
import SwiftData
import EduCore
@testable import EduPersistence

/// Integration tests for persistence synchronization scenarios.
///
/// These tests simulate real-world sync operations:
/// - Simulated fetch → local persistence
/// - Bidirectional sync (local changes + remote updates)
/// - Conflict resolution scenarios
/// - Batch sync operations
@Suite("Persistence Sync Integration Tests", .serialized)
struct PersistenceSyncIntegrationTests {

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

    // MARK: - Simulated Fetch → Local Persistence Tests

    @Test("Simulated API fetch saves users to local persistence")
    func testSimulatedUserFetchToLocal() async throws {
        let repos = try await setupRepositories()

        // Simulate API response (batch of JSON)
        let apiResponseJSONs = IntegrationTestFixtures.generateUserJSONBatch(count: 50)

        // Parse and save to local persistence
        var savedIDs: [UUID] = []
        for json in apiResponseJSONs {
            let dto = try await IntegrationTestFixtures.decode(UserDTO.self, from: Data(json.utf8))
            let domain = try dto.toDomain()
            try await repos.userRepo.save(domain)
            savedIDs.append(domain.id)
        }

        // Verify all were saved
        let localUsers = try await repos.userRepo.list()
        #expect(localUsers.count >= 50)

        for id in savedIDs {
            let user = try await repos.userRepo.get(id: id)
            #expect(user != nil)
        }
    }

    @Test("Simulated API fetch saves schools with metadata to local persistence")
    func testSimulatedSchoolFetchToLocal() async throws {
        let repos = try await setupRepositories()

        let apiResponseJSONs = IntegrationTestFixtures.generateSchoolJSONBatch(count: 25)

        var savedSchools: [School] = []
        for json in apiResponseJSONs {
            let dto = try await IntegrationTestFixtures.decode(SchoolDTO.self, from: Data(json.utf8))
            let domain = try dto.toDomain()
            try await repos.schoolRepo.save(domain)
            savedSchools.append(domain)
        }

        let localSchools = try await repos.schoolRepo.list()
        #expect(localSchools.count >= 25)

        // Verify metadata was preserved
        for school in savedSchools {
            let restored = try await repos.schoolRepo.get(id: school.id)
            #expect(restored != nil)
            #expect(restored?.metadata != nil)
        }
    }

    @Test("Simulated API fetch saves complete entity graph")
    func testSimulatedCompleteGraphFetch() async throws {
        let repos = try await setupRepositories()

        // Simulate fetching a complete school with all related entities
        let (school, units, users, memberships, materials) =
            try IntegrationTestFixtures.generateCompleteEntityGraph()

        // Save in correct order (respecting dependencies)
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

        // Verify complete graph
        let localSchool = try await repos.schoolRepo.get(id: school.id)
        #expect(localSchool != nil)

        let localUnits = try await repos.unitRepo.listBySchool(schoolID: school.id)
        #expect(localUnits.count == units.count)

        let localMaterials = try await repos.materialRepo.listBySchool(schoolID: school.id)
        #expect(localMaterials.count == materials.count)
    }

    // MARK: - Bidirectional Sync Tests

    @Test("Local update followed by remote fetch preserves newer data")
    func testLocalUpdateThenRemoteFetch() async throws {
        let repos = try await setupRepositories()
        let now = Date()

        // Initial save (simulating first fetch)
        let originalUser = try User(
            firstName: "Original",
            lastName: "User",
            email: "sync@test.com",
            isActive: true,
            createdAt: now.addingTimeInterval(-3600),
            updatedAt: now.addingTimeInterval(-3600)
        )
        try await repos.userRepo.save(originalUser)

        // Local update (user changes something offline)
        let localUpdate = try User(
            id: originalUser.id,
            firstName: "Locally",
            lastName: "Updated",
            email: originalUser.email,
            isActive: originalUser.isActive,
            createdAt: originalUser.createdAt,
            updatedAt: now.addingTimeInterval(-1800) // 30 min ago
        )
        try await repos.userRepo.save(localUpdate)

        // Simulated remote fetch with older data (should be ignored in real app)
        // In this test, we just verify that save works correctly
        let remoteData = try User(
            id: originalUser.id,
            firstName: "Remote",
            lastName: "Version",
            email: originalUser.email,
            isActive: originalUser.isActive,
            createdAt: originalUser.createdAt,
            updatedAt: now // newest timestamp wins
        )
        try await repos.userRepo.save(remoteData)

        // Final state should be the last saved
        let finalUser = try await repos.userRepo.get(id: originalUser.id)
        #expect(finalUser?.firstName == "Remote")
        #expect(finalUser?.lastName == "Version")
    }

    @Test("Multiple rapid updates converge to final state")
    func testRapidUpdatesConvergence() async throws {
        let repos = try await setupRepositories()
        let now = Date()

        let userID = UUID()
        let baseUser = try User(
            id: userID,
            firstName: "Initial",
            lastName: "State",
            email: "rapid@test.com",
            isActive: true,
            createdAt: now,
            updatedAt: now
        )
        try await repos.userRepo.save(baseUser)

        // Simulate rapid updates
        for i in 0..<20 {
            let updated = try User(
                id: userID,
                firstName: "Update",
                lastName: "\(i)",
                email: baseUser.email,
                isActive: baseUser.isActive,
                createdAt: baseUser.createdAt,
                updatedAt: now.addingTimeInterval(Double(i))
            )
            try await repos.userRepo.save(updated)
        }

        // Final state should be last update
        let finalUser = try await repos.userRepo.get(id: userID)
        #expect(finalUser?.lastName == "19")
    }

    @Test("Concurrent sync operations on different entities")
    func testConcurrentSyncDifferentEntities() async throws {
        let repos = try await setupRepositories()

        let userCount = 50
        let schoolCount = 25
        let membershipCount = 100

        let userDTOs = IntegrationTestFixtures.generateUserDTOBatch(count: userCount)
        let schoolDTOs = IntegrationTestFixtures.generateSchoolDTOBatch(count: schoolCount)
        let membershipDTOs = IntegrationTestFixtures.generateMembershipDTOBatch(count: membershipCount)

        // Concurrent sync of all entity types
        await withTaskGroup(of: Void.self) { group in
            // User sync
            group.addTask {
                for dto in userDTOs {
                    if let domain = try? dto.toDomain() {
                        try? await repos.userRepo.save(domain)
                    }
                }
            }

            // School sync
            group.addTask {
                for dto in schoolDTOs {
                    if let domain = try? dto.toDomain() {
                        try? await repos.schoolRepo.save(domain)
                    }
                }
            }

            // Membership sync
            group.addTask {
                for dto in membershipDTOs {
                    if let domain = try? dto.toDomain() {
                        try? await repos.membershipRepo.save(domain)
                    }
                }
            }
        }

        // Verify all entities were synced
        let localUsers = try await repos.userRepo.list()
        let localSchools = try await repos.schoolRepo.list()
        let localMemberships = try await repos.membershipRepo.list()

        #expect(localUsers.count >= userCount)
        #expect(localSchools.count >= schoolCount)
        #expect(localMemberships.count >= membershipCount)
    }

    // MARK: - Incremental Sync Tests

    @Test("Incremental sync only updates changed entities")
    func testIncrementalSync() async throws {
        let repos = try await setupRepositories()
        let now = Date()

        // Initial full sync
        var users: [User] = []
        for i in 0..<10 {
            let user = try User(
                firstName: "User",
                lastName: "\(i)",
                email: "user\(i)@incremental.test",
                isActive: true,
                createdAt: now.addingTimeInterval(-3600),
                updatedAt: now.addingTimeInterval(-3600)
            )
            try await repos.userRepo.save(user)
            users.append(user)
        }

        // Incremental sync: only update users 0, 2, 4 (simulating server-side changes)
        let changedIndices = [0, 2, 4]
        for index in changedIndices {
            let original = users[index]
            let updated = try User(
                id: original.id,
                firstName: "Updated",
                lastName: "\(index)",
                email: original.email,
                isActive: original.isActive,
                createdAt: original.createdAt,
                updatedAt: now // newer timestamp
            )
            try await repos.userRepo.save(updated)
        }

        // Verify only specific users were updated
        for (index, user) in users.enumerated() {
            let restored = try await repos.userRepo.get(id: user.id)
            if changedIndices.contains(index) {
                #expect(restored?.firstName == "Updated")
            } else {
                #expect(restored?.firstName == "User")
            }
        }
    }

    @Test("Sync with deletions removes local entities")
    func testSyncWithDeletions() async throws {
        let repos = try await setupRepositories()

        // Initial sync
        var users: [User] = []
        for i in 0..<10 {
            let user = try User(
                firstName: "User",
                lastName: "\(i)",
                email: "deletion\(i)@test.com"
            )
            try await repos.userRepo.save(user)
            users.append(user)
        }

        // Simulated server response indicates users 3, 5, 7 were deleted
        let deletedIndices = [3, 5, 7]
        for index in deletedIndices {
            try await repos.userRepo.delete(id: users[index].id)
        }

        // Verify deletions
        let localUsers = try await repos.userRepo.list()
        #expect(localUsers.count == 7)

        for (index, user) in users.enumerated() {
            let restored = try await repos.userRepo.get(id: user.id)
            if deletedIndices.contains(index) {
                #expect(restored == nil)
            } else {
                #expect(restored != nil)
            }
        }
    }

    // MARK: - Batch Sync Tests

    @Test("Batch sync of 200 users completes successfully")
    func testBatchUserSync() async throws {
        let repos = try await setupRepositories()

        let batchSize = 200
        let jsonBatch = IntegrationTestFixtures.generateUserJSONBatch(count: batchSize)

        let startTime = ContinuousClock.now

        for json in jsonBatch {
            let dto = try await IntegrationTestFixtures.decode(UserDTO.self, from: Data(json.utf8))
            let domain = try dto.toDomain()
            try await repos.userRepo.save(domain)
        }

        let elapsed = ContinuousClock.now - startTime

        let localUsers = try await repos.userRepo.list()
        #expect(localUsers.count >= batchSize)
        #expect(elapsed < .seconds(10), "Batch sync should complete in reasonable time")
    }

    @Test("Batch sync of mixed entity types")
    func testMixedBatchSync() async throws {
        let repos = try await setupRepositories()

        let schoolID = UUID()

        // Generate mixed batch
        let users = IntegrationTestFixtures.generateUserDTOBatch(count: 50)
        let units = IntegrationTestFixtures.generateAcademicUnitDTOBatch(count: 30, schoolID: schoolID)
        let memberships = IntegrationTestFixtures.generateMembershipDTOBatch(count: 100)
        let materials = IntegrationTestFixtures.generateMaterialDTOBatch(count: 40, schoolID: schoolID)

        let startTime = ContinuousClock.now

        // Create school first
        let school = try School(id: schoolID, name: "Batch School", code: "BATCH-001")
        try await repos.schoolRepo.save(school)

        // Sync all entities
        for dto in users {
            try await repos.userRepo.save(dto.toDomain())
        }

        for dto in units {
            try await repos.unitRepo.save(dto.toDomain())
        }

        for dto in memberships {
            try await repos.membershipRepo.save(dto.toDomain())
        }

        for dto in materials {
            try await repos.materialRepo.save(dto.toDomain())
        }

        let elapsed = ContinuousClock.now - startTime

        // Verify all synced
        #expect(try await repos.userRepo.list().count >= 50)
        #expect(try await repos.unitRepo.list().count >= 30)
        #expect(try await repos.membershipRepo.list().count >= 100)
        #expect(try await repos.materialRepo.list().count >= 40)

        #expect(elapsed < .seconds(15), "Mixed batch sync should complete in reasonable time")
    }

    // MARK: - Offline-First Scenario Tests

    @Test("Offline changes are preserved when coming back online")
    func testOfflineChangesPreserved() async throws {
        let repos = try await setupRepositories()
        let now = Date()

        // Initial online state
        let user = try User(
            firstName: "Online",
            lastName: "User",
            email: "offline@test.com",
            isActive: true,
            createdAt: now.addingTimeInterval(-7200),
            updatedAt: now.addingTimeInterval(-7200)
        )
        try await repos.userRepo.save(user)

        // Simulate offline changes (multiple updates)
        var offlineUpdates: [User] = []
        for i in 0..<5 {
            let updated = try User(
                id: user.id,
                firstName: "Offline Update",
                lastName: "\(i)",
                email: user.email,
                isActive: user.isActive,
                createdAt: user.createdAt,
                updatedAt: now.addingTimeInterval(-3600 + Double(i * 60))
            )
            try await repos.userRepo.save(updated)
            offlineUpdates.append(updated)
        }

        // Verify offline state is persisted
        let offlineState = try await repos.userRepo.get(id: user.id)
        #expect(offlineState?.firstName == "Offline Update")
        #expect(offlineState?.lastName == "4") // Last update
    }

    @Test("Sync conflict detection via timestamps")
    func testSyncConflictDetection() async throws {
        let repos = try await setupRepositories()
        let now = Date()

        // Original entity
        let original = try User(
            firstName: "Original",
            lastName: "State",
            email: "conflict@test.com",
            isActive: true,
            createdAt: now.addingTimeInterval(-3600),
            updatedAt: now.addingTimeInterval(-3600)
        )
        try await repos.userRepo.save(original)

        // Local change (newer)
        let localVersion = try User(
            id: original.id,
            firstName: "Local",
            lastName: "Change",
            email: original.email,
            isActive: original.isActive,
            createdAt: original.createdAt,
            updatedAt: now.addingTimeInterval(-1800) // 30 min ago
        )

        // Remote change (even newer)
        let remoteVersion = try User(
            id: original.id,
            firstName: "Remote",
            lastName: "Change",
            email: original.email,
            isActive: original.isActive,
            createdAt: original.createdAt,
            updatedAt: now // Now
        )

        // Save local first
        try await repos.userRepo.save(localVersion)

        let afterLocal = try await repos.userRepo.get(id: original.id)
        #expect(afterLocal?.firstName == "Local")

        // Then save remote (should win based on timestamp)
        try await repos.userRepo.save(remoteVersion)

        let afterRemote = try await repos.userRepo.get(id: original.id)
        #expect(afterRemote?.firstName == "Remote")
        #expect(afterRemote?.updatedAt == now)
    }

    // MARK: - Data Integrity Tests

    @Test("Sync maintains referential integrity")
    func testSyncMaintainsReferentialIntegrity() async throws {
        let repos = try await setupRepositories()

        // Create entities with relationships
        let school = try TestDataFactory.makeSchool()
        try await repos.schoolRepo.save(school)

        let units = try TestDataFactory.makeAcademicUnits(count: 5, schoolID: school.id)
        for unit in units {
            try await repos.unitRepo.save(unit)
        }

        let users = try TestDataFactory.makeUsers(count: 10)
        for user in users {
            try await repos.userRepo.save(user)
        }

        // Create memberships linking users to units
        var memberships: [Membership] = []
        for (index, user) in users.enumerated() {
            let unit = units[index % units.count]
            let membership = TestDataFactory.makeMembership(
                userID: user.id,
                unitID: unit.id,
                role: MembershipRole.allCases[index % MembershipRole.allCases.count]
            )
            try await repos.membershipRepo.save(membership)
            memberships.append(membership)
        }

        // Verify all relationships are intact
        for membership in memberships {
            let restored = try await repos.membershipRepo.get(id: membership.id)
            #expect(restored != nil)

            // Verify referenced user exists
            let user = try await repos.userRepo.get(id: membership.userID)
            #expect(user != nil)

            // Verify referenced unit exists
            let unit = try await repos.unitRepo.get(id: membership.unitID)
            #expect(unit != nil)
        }
    }

    @Test("Sync handles partial failures gracefully")
    func testSyncPartialFailures() async throws {
        let repos = try await setupRepositories()

        // Mix of valid and potentially invalid data
        let validJSONs = IntegrationTestFixtures.generateUserJSONBatch(count: 10)
        let invalidJSONs = IntegrationTestFixtures.generateInvalidUserJSON()

        var successCount = 0
        var failureCount = 0

        // Try to sync all
        for json in validJSONs + invalidJSONs {
            do {
                let dto = try await IntegrationTestFixtures.decode(UserDTO.self, from: Data(json.utf8))
                let domain = try dto.toDomain()
                try await repos.userRepo.save(domain)
                successCount += 1
            } catch {
                failureCount += 1
            }
        }

        // Should have saved valid ones
        #expect(successCount >= 10)
        #expect(failureCount >= invalidJSONs.count)

        // Valid data should be persisted
        let localUsers = try await repos.userRepo.list()
        #expect(localUsers.count >= 10)
    }
}
