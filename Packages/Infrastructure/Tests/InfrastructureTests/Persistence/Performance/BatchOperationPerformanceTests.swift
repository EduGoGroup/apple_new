import Testing
import Foundation
import SwiftData
import EduCore
@testable import EduPersistence

/// Performance tests for batch operations on local persistence.
///
/// These tests verify that batch operations meet performance requirements:
/// - 100+ entities should complete in under 5 seconds
/// - Batch reads should scale linearly
/// - Memory usage should remain stable during large batches
@Suite("Batch Operation Performance Tests", .serialized)
struct BatchOperationPerformanceTests {

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

    // MARK: - User Batch Performance Tests

    @Test("100 user saves complete under 5 seconds")
    func testBatchUserSaves100() async throws {
        let repos = try await setupRepositories()
        let users = try TestDataFactory.makeUsers(count: 100)

        let startTime = ContinuousClock.now

        for user in users {
            try await repos.userRepo.save(user)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "100 user saves took \(elapsed)")
    }

    @Test("250 user saves complete under 10 seconds")
    func testBatchUserSaves250() async throws {
        let repos = try await setupRepositories()
        let users = try TestDataFactory.makeUsers(count: 250)

        let startTime = ContinuousClock.now

        for user in users {
            try await repos.userRepo.save(user)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(10), "250 user saves took \(elapsed)")
    }

    @Test("100 user reads after batch save complete under 2 seconds")
    func testBatchUserReads100() async throws {
        let repos = try await setupRepositories()
        let users = try TestDataFactory.makeUsers(count: 100)

        for user in users {
            try await repos.userRepo.save(user)
        }

        let startTime = ContinuousClock.now

        for user in users {
            _ = try await repos.userRepo.get(id: user.id)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(2), "100 user reads took \(elapsed)")
    }

    @Test("List 500 users completes under 1 second")
    func testListUsers500() async throws {
        let repos = try await setupRepositories()
        let users = try TestDataFactory.makeUsers(count: 500)

        for user in users {
            try await repos.userRepo.save(user)
        }

        let startTime = ContinuousClock.now

        let listed = try await repos.userRepo.list()

        let elapsed = ContinuousClock.now - startTime
        #expect(listed.count >= 500)
        #expect(elapsed < .seconds(1), "Listing 500 users took \(elapsed)")
    }

    // MARK: - School Batch Performance Tests

    @Test("100 school saves complete under 5 seconds")
    func testBatchSchoolSaves100() async throws {
        let repos = try await setupRepositories()
        let schools = try TestDataFactory.makeSchools(count: 100)

        let startTime = ContinuousClock.now

        for school in schools {
            try await repos.schoolRepo.save(school)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "100 school saves took \(elapsed)")
    }

    @Test("100 school saves with metadata complete under 6 seconds")
    func testBatchSchoolSavesWithMetadata100() async throws {
        let repos = try await setupRepositories()

        let startTime = ContinuousClock.now

        for i in 0..<100 {
            let school = try School(
                name: "Performance School \(i)",
                code: "PERF-\(i)",
                isActive: true,
                address: "Address \(i)",
                city: "City \(i)",
                country: "Country",
                contactEmail: "school\(i)@perf.test",
                contactPhone: "+1-555-\(String(format: "%04d", i))",
                maxStudents: 100 + i * 10,
                maxTeachers: 10 + i,
                subscriptionTier: "standard",
                metadata: [
                    "test_index": .integer(i),
                    "has_gym": .bool(i % 2 == 0),
                    "founded_year": .integer(1990 + i)
                ]
            )
            try await repos.schoolRepo.save(school)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(6), "100 school saves with metadata took \(elapsed)")
    }

    // MARK: - Membership Batch Performance Tests

    @Test("200 membership saves complete under 5 seconds")
    func testBatchMembershipSaves200() async throws {
        let repos = try await setupRepositories()
        let memberships = TestDataFactory.makeMemberships(count: 200)

        let startTime = ContinuousClock.now

        for membership in memberships {
            try await repos.membershipRepo.save(membership)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "200 membership saves took \(elapsed)")
    }

    @Test("Query memberships by user across 500 memberships under 1 second")
    func testQueryMembershipsByUser() async throws {
        let repos = try await setupRepositories()
        let targetUserID = UUID()

        // Create memberships: 50 for target user, 450 for random users
        for i in 0..<500 {
            let membership = TestDataFactory.makeMembership(
                userID: i < 50 ? targetUserID : UUID(),
                role: MembershipRole.allCases[i % MembershipRole.allCases.count]
            )
            try await repos.membershipRepo.save(membership)
        }

        let startTime = ContinuousClock.now

        let userMemberships = try await repos.membershipRepo.listByUser(userID: targetUserID)

        let elapsed = ContinuousClock.now - startTime
        #expect(userMemberships.count == 50)
        #expect(elapsed < .seconds(1), "Query memberships by user took \(elapsed)")
    }

    // MARK: - Material Batch Performance Tests

    @Test("150 material saves complete under 5 seconds")
    func testBatchMaterialSaves150() async throws {
        let repos = try await setupRepositories()
        let schoolID = UUID()
        let materials = try TestDataFactory.makeMaterials(count: 150, schoolID: schoolID)

        let startTime = ContinuousClock.now

        for material in materials {
            try await repos.materialRepo.save(material)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "150 material saves took \(elapsed)")
    }

    @Test("Query materials by school across 300 materials under 1 second")
    func testQueryMaterialsBySchool() async throws {
        let repos = try await setupRepositories()
        let targetSchoolID = UUID()

        // Create materials: 100 for target school, 200 for other schools
        for i in 0..<300 {
            let material = try TestDataFactory.makeMaterial(
                title: "Performance Material \(i)",
                status: MaterialStatus.allCases[i % MaterialStatus.allCases.count],
                schoolID: i < 100 ? targetSchoolID : UUID()
            )
            try await repos.materialRepo.save(material)
        }

        let startTime = ContinuousClock.now

        let schoolMaterials = try await repos.materialRepo.listBySchool(schoolID: targetSchoolID)

        let elapsed = ContinuousClock.now - startTime
        #expect(schoolMaterials.count == 100)
        #expect(elapsed < .seconds(1), "Query materials by school took \(elapsed)")
    }

    // MARK: - Academic Unit Batch Performance Tests

    @Test("100 academic unit saves complete under 5 seconds")
    func testBatchAcademicUnitSaves100() async throws {
        let repos = try await setupRepositories()
        let schoolID = UUID()
        let units = try TestDataFactory.makeAcademicUnits(count: 100, schoolID: schoolID)

        let startTime = ContinuousClock.now

        for unit in units {
            try await repos.unitRepo.save(unit)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "100 academic unit saves took \(elapsed)")
    }

    @Test("Query academic units by school across 200 units under 1 second")
    func testQueryAcademicUnitsBySchool() async throws {
        let repos = try await setupRepositories()
        let targetSchoolID = UUID()

        // Create units: 75 for target school, 125 for other schools
        for i in 0..<200 {
            let unit = try TestDataFactory.makeAcademicUnit(
                displayName: "Performance Unit \(i)",
                type: AcademicUnitType.allCases[i % AcademicUnitType.allCases.count],
                schoolID: i < 75 ? targetSchoolID : UUID()
            )
            try await repos.unitRepo.save(unit)
        }

        let startTime = ContinuousClock.now

        let schoolUnits = try await repos.unitRepo.listBySchool(schoolID: targetSchoolID)

        let elapsed = ContinuousClock.now - startTime
        #expect(schoolUnits.count == 75)
        #expect(elapsed < .seconds(1), "Query academic units by school took \(elapsed)")
    }

    // MARK: - Mixed Entity Batch Performance Tests

    @Test("Complete graph of 100+ entities saves under 10 seconds")
    func testCompleteGraphPerformance() async throws {
        let repos = try await setupRepositories()

        let startTime = ContinuousClock.now

        // Create school
        let school = try TestDataFactory.makeSchool(name: "Performance Graph School")
        try await repos.schoolRepo.save(school)

        // Create 20 academic units
        let units = try TestDataFactory.makeAcademicUnits(count: 20, schoolID: school.id)
        for unit in units {
            try await repos.unitRepo.save(unit)
        }

        // Create 50 users
        let users = try TestDataFactory.makeUsers(count: 50)
        for user in users {
            try await repos.userRepo.save(user)
        }

        // Create 100 memberships
        for i in 0..<100 {
            let membership = TestDataFactory.makeMembership(
                userID: users[i % users.count].id,
                unitID: units[i % units.count].id,
                role: MembershipRole.allCases[i % MembershipRole.allCases.count]
            )
            try await repos.membershipRepo.save(membership)
        }

        // Create 30 materials
        let materials = try TestDataFactory.makeMaterials(count: 30, schoolID: school.id)
        for material in materials {
            try await repos.materialRepo.save(material)
        }

        let elapsed = ContinuousClock.now - startTime

        // Total: 1 school + 20 units + 50 users + 100 memberships + 30 materials = 201 entities
        #expect(elapsed < .seconds(10), "Complete graph of 201 entities took \(elapsed)")
    }

    // MARK: - Update Batch Performance Tests

    @Test("100 user updates complete under 5 seconds")
    func testBatchUserUpdates100() async throws {
        let repos = try await setupRepositories()
        var users = try TestDataFactory.makeUsers(count: 100)

        // Initial save
        for user in users {
            try await repos.userRepo.save(user)
        }

        let startTime = ContinuousClock.now

        // Update all users
        for i in 0..<users.count {
            let updated = try users[i].with(firstName: "Updated\(i)")
            try await repos.userRepo.save(updated)
            users[i] = updated
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "100 user updates took \(elapsed)")

        // Verify updates
        for user in users {
            let fetched = try await repos.userRepo.get(id: user.id)
            #expect(fetched?.firstName.hasPrefix("Updated") == true)
        }
    }

    // MARK: - Delete Batch Performance Tests

    @Test("100 user deletes complete under 5 seconds")
    func testBatchUserDeletes100() async throws {
        let repos = try await setupRepositories()
        let users = try TestDataFactory.makeUsers(count: 100)

        // Initial save
        for user in users {
            try await repos.userRepo.save(user)
        }

        let startTime = ContinuousClock.now

        // Delete all users
        for user in users {
            try await repos.userRepo.delete(id: user.id)
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(5), "100 user deletes took \(elapsed)")

        // Verify deletes
        let remaining = try await repos.userRepo.list()
        #expect(remaining.isEmpty)
    }

    // MARK: - Throughput Tests

    @Test("Measure user save throughput (ops/sec)")
    func testUserSaveThroughput() async throws {
        let repos = try await setupRepositories()
        let users = try TestDataFactory.makeUsers(count: 100)

        let startTime = ContinuousClock.now

        for user in users {
            try await repos.userRepo.save(user)
        }

        let elapsed = ContinuousClock.now - startTime
        let elapsedSeconds = Double(elapsed.components.seconds) +
            Double(elapsed.components.attoseconds) / 1_000_000_000_000_000_000

        let throughput = Double(users.count) / max(elapsedSeconds, 0.001)

        // Should achieve at least 20 ops/sec
        #expect(throughput >= 20, "Throughput was \(throughput) ops/sec, expected at least 20")
    }

    @Test("Measure user read throughput (ops/sec)")
    func testUserReadThroughput() async throws {
        let repos = try await setupRepositories()
        let users = try TestDataFactory.makeUsers(count: 100)

        for user in users {
            try await repos.userRepo.save(user)
        }

        let startTime = ContinuousClock.now

        for user in users {
            _ = try await repos.userRepo.get(id: user.id)
        }

        let elapsed = ContinuousClock.now - startTime
        let elapsedSeconds = Double(elapsed.components.seconds) +
            Double(elapsed.components.attoseconds) / 1_000_000_000_000_000_000

        let throughput = Double(users.count) / max(elapsedSeconds, 0.001)

        // Should achieve at least 50 ops/sec for reads
        #expect(throughput >= 50, "Read throughput was \(throughput) ops/sec, expected at least 50")
    }

    // MARK: - Scaling Tests

    @Test("Performance scales linearly from 50 to 200 entities")
    func testLinearScaling() async throws {
        let repos = try await setupRepositories()

        // Measure time for 50 entities
        let users50 = try TestDataFactory.makeUsers(count: 50)
        let start50 = ContinuousClock.now
        for user in users50 {
            try await repos.userRepo.save(user)
        }
        let elapsed50 = ContinuousClock.now - start50

        // Clear and measure time for 200 entities (4x)
        let provider2 = PersistenceContainerProvider()
        try await provider2.configure(with: .testing, schema: LocalPersistenceSchema.current)
        let userRepo2 = LocalUserRepository(containerProvider: provider2)

        let users200 = try TestDataFactory.makeUsers(count: 200)
        let start200 = ContinuousClock.now
        for user in users200 {
            try await userRepo2.save(user)
        }
        let elapsed200 = ContinuousClock.now - start200

        // 200 entities should take no more than 6x the time of 50 entities
        // (allowing some overhead for larger datasets)
        let ratio = Double(elapsed200.components.attoseconds) /
            Double(max(elapsed50.components.attoseconds, 1))

        #expect(ratio < 6.0, "Scaling ratio was \(ratio), expected < 6.0 for 4x entities")
    }

    // MARK: - Concurrent Batch Performance Tests

    @Test("Concurrent batch saves of 50 users each (4 batches) complete under 8 seconds")
    func testConcurrentBatchSaves() async throws {
        let provider = PersistenceContainerProvider()
        try await provider.configure(with: .testing, schema: LocalPersistenceSchema.current)

        let startTime = ContinuousClock.now

        await withTaskGroup(of: Void.self) { group in
            for batchIndex in 0..<4 {
                group.addTask {
                    let repo = LocalUserRepository(containerProvider: provider)
                    for i in 0..<50 {
                        let user = try? User(
                            firstName: "Batch\(batchIndex)",
                            lastName: "User\(i)",
                            email: "batch\(batchIndex)_user\(i)@perf.test"
                        )
                        if let user = user {
                            try? await repo.save(user)
                        }
                    }
                }
            }
        }

        let elapsed = ContinuousClock.now - startTime
        #expect(elapsed < .seconds(8), "4 concurrent batches of 50 users took \(elapsed)")

        let userRepo = LocalUserRepository(containerProvider: provider)
        let allUsers = try await userRepo.list()
        #expect(allUsers.count >= 200)
    }
}
