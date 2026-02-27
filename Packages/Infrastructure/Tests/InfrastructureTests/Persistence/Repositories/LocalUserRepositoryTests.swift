import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("LocalUserRepository Tests", .serialized)
struct LocalUserRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalUserRepository {
        let provider = PersistenceContainerProvider()
        // Always configure a fresh provider to avoid cross-suite interference
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalUserRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get user")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser(firstName: "John", lastName: "Doe")

        try await repository.save(user)
        let fetched = try await repository.get(id: user.id)

        #expect(fetched != nil)
        #expect(fetched?.id == user.id)
        #expect(fetched?.firstName == "John")
        #expect(fetched?.lastName == "Doe")
    }

    @Test("Get returns nil for non-existent user")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved users")
    func testListReturnsSavedUsers() async throws {
        let repository = try await setupRepository()
        let user1 = try TestDataFactory.makeUser(firstName: "User", lastName: "One", email: "user1@test.com")
        let user2 = try TestDataFactory.makeUser(firstName: "User", lastName: "Two", email: "user2@test.com")

        try await repository.save(user1)
        try await repository.save(user2)

        let listed = try await repository.list()

        // Check that at least our users are present
        #expect(listed.contains { $0.id == user1.id })
        #expect(listed.contains { $0.id == user2.id })
    }

    @Test("Delete removes user")
    func testDeleteRemovesUser() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser()

        try await repository.save(user)
        try await repository.delete(id: user.id)

        let fetched = try await repository.get(id: user.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent user")
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

    @Test("Save same user twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser(firstName: "Original", lastName: "Name")

        try await repository.save(user)

        let updatedUser = try User(
            id: user.id,
            firstName: "Updated",
            lastName: "Name",
            email: user.email,
            isActive: user.isActive,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedUser)

        let fetched = try await repository.get(id: user.id)
        #expect(fetched?.firstName == "Updated")
    }

    @Test("Upsert updates all fields")
    func testUpsertUpdatesAllFields() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser(
            firstName: "Test",
            lastName: "User",
            isActive: true
        )

        try await repository.save(user)

        let updatedUser = try User(
            id: user.id,
            firstName: "Updated",
            lastName: "Person",
            email: user.email,
            isActive: false,
            createdAt: user.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedUser)

        let fetched = try await repository.get(id: user.id)

        #expect(fetched?.firstName == "Updated")
        #expect(fetched?.lastName == "Person")
        #expect(fetched?.isActive == false)
    }

    // MARK: - Edge Cases

    @Test("Save user with inactive status")
    func testSaveUserWithInactiveStatus() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser(isActive: false)

        try await repository.save(user)
        let fetched = try await repository.get(id: user.id)

        #expect(fetched?.isActive == false)
    }

    @Test("Save and retrieve multiple users")
    func testSaveAndRetrieveMultipleUsers() async throws {
        let repository = try await setupRepository()
        let users = try TestDataFactory.makeUsers(count: 20)

        for user in users {
            try await repository.save(user)
        }

        let listed = try await repository.list()

        #expect(listed.count >= 20)
        for user in users {
            #expect(listed.contains { $0.id == user.id })
        }
    }

    // MARK: - Extended Repository Tests

    @Test("Batch save and verify all users")
    func testBatchSaveAndVerify() async throws {
        let repository = try await setupRepository()
        let users = try TestDataFactory.makeUsers(count: 100)

        for user in users {
            try await repository.save(user)
        }

        for user in users {
            let fetched = try await repository.get(id: user.id)
            #expect(fetched != nil)
            #expect(fetched?.id == user.id)
            #expect(fetched?.firstName == user.firstName)
            #expect(fetched?.email == user.email)
        }
    }

    @Test("Update preserves all fields correctly")
    func testUpdatePreservesAllFields() async throws {
        let repository = try await setupRepository()
        let originalCreatedAt = Date(timeIntervalSince1970: 1704067200)
        let user = try TestDataFactory.makeUser(
            firstName: "Original",
            lastName: "User",
            email: "original@test.com",
            isActive: true,
            createdAt: originalCreatedAt
        )

        try await repository.save(user)

        let newUpdatedAt = Date()
        let updatedUser = try User(
            id: user.id,
            firstName: "Updated",
            lastName: "Person",
            email: user.email,
            isActive: false,
            createdAt: originalCreatedAt,
            updatedAt: newUpdatedAt
        )
        try await repository.save(updatedUser)

        let fetched = try await repository.get(id: user.id)

        #expect(fetched?.firstName == "Updated")
        #expect(fetched?.lastName == "Person")
        #expect(fetched?.isActive == false)
        #expect(fetched?.createdAt == originalCreatedAt)
    }

    @Test("Delete multiple users in sequence")
    func testDeleteMultipleUsersInSequence() async throws {
        let repository = try await setupRepository()
        let users = try TestDataFactory.makeUsers(count: 10)

        for user in users {
            try await repository.save(user)
        }

        // Delete half of the users
        for user in users.prefix(5) {
            try await repository.delete(id: user.id)
        }

        let listed = try await repository.list()

        for user in users.prefix(5) {
            #expect(!listed.contains { $0.id == user.id })
        }
        for user in users.suffix(5) {
            #expect(listed.contains { $0.id == user.id })
        }
    }

    @Test("Save minimal user")
    func testSaveMinimalUser() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeMinimalUser()

        try await repository.save(user)
        let fetched = try await repository.get(id: user.id)

        #expect(fetched != nil)
        #expect(fetched?.firstName == "A")
        #expect(fetched?.lastName == "B")
    }

    @Test("List returns empty array when no users exist")
    func testListReturnsEmptyArrayWhenNoUsers() async throws {
        let repository = try await setupRepository()

        let listed = try await repository.list()

        #expect(listed.isEmpty)
    }

    @Test("Rapid save and delete cycles")
    func testRapidSaveDeleteCycles() async throws {
        let repository = try await setupRepository()

        for i in 0..<50 {
            let user = try TestDataFactory.makeUser(
                firstName: "Cycle",
                lastName: "\(i)",
                email: "cycle\(i)@test.com"
            )
            try await repository.save(user)
            try await repository.delete(id: user.id)

            let fetched = try await repository.get(id: user.id)
            #expect(fetched == nil)
        }
    }
}
