import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("LocalMembershipRepository Tests", .serialized)
struct LocalMembershipRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalMembershipRepository {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalMembershipRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get membership")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let membership = TestDataFactory.makeMembership(role: .teacher)

        try await repository.save(membership)
        let fetched = try await repository.get(id: membership.id)

        #expect(fetched != nil)
        #expect(fetched?.id == membership.id)
        #expect(fetched?.role == .teacher)
    }

    @Test("Get returns nil for non-existent membership")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved memberships")
    func testListReturnsSavedMemberships() async throws {
        let repository = try await setupRepository()
        let membership1 = TestDataFactory.makeMembership(role: .teacher)
        let membership2 = TestDataFactory.makeMembership(role: .student)

        try await repository.save(membership1)
        try await repository.save(membership2)

        let listed = try await repository.list()

        #expect(listed.contains { $0.id == membership1.id })
        #expect(listed.contains { $0.id == membership2.id })
    }

    @Test("Delete removes membership")
    func testDeleteRemovesMembership() async throws {
        let repository = try await setupRepository()
        let membership = TestDataFactory.makeMembership()

        try await repository.save(membership)
        try await repository.delete(id: membership.id)

        let fetched = try await repository.get(id: membership.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent membership")
    func testDeleteThrowsForNonExistent() async throws {
        let repository = try await setupRepository()

        do {
            try await repository.delete(id: UUID())
            Issue.record("Expected deleteFailed error")
        } catch let error as RepositoryError {
            if case .deleteFailed = error {
                // Expected
            } else {
                Issue.record("Expected deleteFailed, got \(error)")
            }
        }
    }

    // MARK: - Upsert Tests

    @Test("Save same membership twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let membership = TestDataFactory.makeMembership(role: .student)

        try await repository.save(membership)

        let updatedMembership = Membership(
            id: membership.id,
            userID: membership.userID,
            unitID: membership.unitID,
            role: .teacher,
            isActive: membership.isActive,
            enrolledAt: membership.enrolledAt,
            withdrawnAt: membership.withdrawnAt,
            createdAt: membership.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedMembership)

        let fetched = try await repository.get(id: membership.id)
        #expect(fetched?.role == .teacher)
    }

    // MARK: - Query Tests

    @Test("List by user returns only memberships for that user")
    func testListByUser() async throws {
        let repository = try await setupRepository()
        let userID = UUID()
        let otherUserID = UUID()

        let membership1 = TestDataFactory.makeMembership(userID: userID, role: .teacher)
        let membership2 = TestDataFactory.makeMembership(userID: otherUserID, role: .student)

        try await repository.save(membership1)
        try await repository.save(membership2)

        let userMemberships = try await repository.listByUser(userID: userID)

        #expect(userMemberships.count == 1)
        #expect(userMemberships.first?.id == membership1.id)
    }

    @Test("List by unit returns only memberships for that unit")
    func testListByUnit() async throws {
        let repository = try await setupRepository()
        let unitID = UUID()
        let otherUnitID = UUID()

        let membership1 = TestDataFactory.makeMembership(unitID: unitID, role: .teacher)
        let membership2 = TestDataFactory.makeMembership(unitID: otherUnitID, role: .student)

        try await repository.save(membership1)
        try await repository.save(membership2)

        let unitMemberships = try await repository.listByUnit(unitID: unitID)

        #expect(unitMemberships.count == 1)
        #expect(unitMemberships.first?.id == membership1.id)
    }

    @Test("Get by user and unit returns correct membership")
    func testGetByUserAndUnit() async throws {
        let repository = try await setupRepository()
        let userID = UUID()
        let unitID = UUID()

        let membership = TestDataFactory.makeMembership(userID: userID, unitID: unitID, role: .teacher)
        try await repository.save(membership)

        let fetched = try await repository.get(userID: userID, unitID: unitID)

        #expect(fetched != nil)
        #expect(fetched?.id == membership.id)
    }

    @Test("Get by user and unit returns nil for non-existent combination")
    func testGetByUserAndUnitReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(userID: UUID(), unitID: UUID())

        #expect(fetched == nil)
    }

    // MARK: - Extended Repository Tests

    @Test("Save and retrieve memberships with all roles")
    func testSaveAndRetrieveAllRoles() async throws {
        let repository = try await setupRepository()
        let unitID = UUID()
        let memberships = TestDataFactory.makeMembershipsWithAllRoles(unitID: unitID)

        for membership in memberships {
            try await repository.save(membership)
        }

        let unitMemberships = try await repository.listByUnit(unitID: unitID)

        #expect(unitMemberships.count == memberships.count)
        for membership in memberships {
            #expect(unitMemberships.contains { $0.role == membership.role })
        }
    }

    @Test("Batch save and verify memberships")
    func testBatchSaveAndVerify() async throws {
        let repository = try await setupRepository()
        let memberships = TestDataFactory.makeMemberships(count: 100)

        for membership in memberships {
            try await repository.save(membership)
        }

        for membership in memberships {
            let fetched = try await repository.get(id: membership.id)
            #expect(fetched != nil)
            #expect(fetched?.id == membership.id)
            #expect(fetched?.role == membership.role)
        }
    }

    @Test("User with multiple memberships across units")
    func testUserWithMultipleMemberships() async throws {
        let repository = try await setupRepository()
        let userID = UUID()

        let unit1ID = UUID()
        let unit2ID = UUID()
        let unit3ID = UUID()

        let membership1 = TestDataFactory.makeMembership(userID: userID, unitID: unit1ID, role: .student)
        let membership2 = TestDataFactory.makeMembership(userID: userID, unitID: unit2ID, role: .teacher)
        let membership3 = TestDataFactory.makeMembership(userID: userID, unitID: unit3ID, role: .assistant)

        try await repository.save(membership1)
        try await repository.save(membership2)
        try await repository.save(membership3)

        let userMemberships = try await repository.listByUser(userID: userID)

        #expect(userMemberships.count == 3)
        #expect(userMemberships.contains { $0.role == .student })
        #expect(userMemberships.contains { $0.role == .teacher })
        #expect(userMemberships.contains { $0.role == .assistant })
    }

    @Test("Update membership role")
    func testUpdateMembershipRole() async throws {
        let repository = try await setupRepository()
        let membership = TestDataFactory.makeMembership(role: .student)

        try await repository.save(membership)

        let updatedMembership = Membership(
            id: membership.id,
            userID: membership.userID,
            unitID: membership.unitID,
            role: .teacher,
            isActive: membership.isActive,
            enrolledAt: membership.enrolledAt,
            withdrawnAt: membership.withdrawnAt,
            createdAt: membership.createdAt,
            updatedAt: Date()
        )

        try await repository.save(updatedMembership)

        let fetched = try await repository.get(id: membership.id)
        #expect(fetched?.role == .teacher)
    }

    @Test("Save and retrieve withdrawn membership")
    func testSaveAndRetrieveWithdrawnMembership() async throws {
        let repository = try await setupRepository()
        let membership = TestDataFactory.makeWithdrawnMembership()

        try await repository.save(membership)
        let fetched = try await repository.get(id: membership.id)

        #expect(fetched != nil)
        #expect(fetched?.isActive == false)
        #expect(fetched?.withdrawnAt != nil)
    }

    @Test("List by unit with multiple users")
    func testListByUnitWithMultipleUsers() async throws {
        let repository = try await setupRepository()
        let unitID = UUID()

        let memberships = (0..<20).map { i in
            TestDataFactory.makeMembership(
                userID: UUID(),
                unitID: unitID,
                role: i % 2 == 0 ? .student : .teacher
            )
        }

        for membership in memberships {
            try await repository.save(membership)
        }

        let unitMemberships = try await repository.listByUnit(unitID: unitID)

        #expect(unitMemberships.count == 20)
    }

    @Test("Delete membership from unit list")
    func testDeleteMembershipFromUnitList() async throws {
        let repository = try await setupRepository()
        let unitID = UUID()

        let membership1 = TestDataFactory.makeMembership(unitID: unitID, role: .student)
        let membership2 = TestDataFactory.makeMembership(unitID: unitID, role: .teacher)

        try await repository.save(membership1)
        try await repository.save(membership2)

        try await repository.delete(id: membership1.id)

        let unitMemberships = try await repository.listByUnit(unitID: unitID)

        #expect(unitMemberships.count == 1)
        #expect(unitMemberships.first?.id == membership2.id)
    }

    @Test("List returns empty array when no memberships exist")
    func testListReturnsEmptyArrayWhenNoMemberships() async throws {
        let repository = try await setupRepository()

        let listed = try await repository.list()

        #expect(listed.isEmpty)
    }
}
