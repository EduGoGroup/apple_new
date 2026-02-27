import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("LocalSchoolRepository Tests", .serialized)
struct LocalSchoolRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalSchoolRepository {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalSchoolRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get school")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeSchool(name: "Test Academy")

        try await repository.save(school)
        let fetched = try await repository.get(id: school.id)

        #expect(fetched != nil)
        #expect(fetched?.id == school.id)
        #expect(fetched?.name == "Test Academy")
    }

    @Test("Get returns nil for non-existent school")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved schools")
    func testListReturnsSavedSchools() async throws {
        let repository = try await setupRepository()
        let school1 = try TestDataFactory.makeSchool(name: "School One", code: "SCH001")
        let school2 = try TestDataFactory.makeSchool(name: "School Two", code: "SCH002")

        try await repository.save(school1)
        try await repository.save(school2)

        let listed = try await repository.list()

        #expect(listed.contains { $0.id == school1.id })
        #expect(listed.contains { $0.id == school2.id })
    }

    @Test("Delete removes school")
    func testDeleteRemovesSchool() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeSchool()

        try await repository.save(school)
        try await repository.delete(id: school.id)

        let fetched = try await repository.get(id: school.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent school")
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

    @Test("Save same school twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeSchool(name: "Original Name")

        try await repository.save(school)

        let updatedSchool = try School(
            id: school.id,
            name: "Updated Name",
            code: school.code,
            isActive: school.isActive,
            createdAt: school.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedSchool)

        let fetched = try await repository.get(id: school.id)
        #expect(fetched?.name == "Updated Name")
    }

    // MARK: - Query Tests

    @Test("Get by code returns correct school")
    func testGetByCode() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeSchool(name: "Code School", code: "UNIQUE-CODE")

        try await repository.save(school)

        let fetched = try await repository.getByCode(code: "UNIQUE-CODE")

        #expect(fetched != nil)
        #expect(fetched?.id == school.id)
    }

    @Test("Get by code returns nil for non-existent code")
    func testGetByCodeReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.getByCode(code: "NON-EXISTENT")

        #expect(fetched == nil)
    }

    // MARK: - Extended Repository Tests

    @Test("Batch save and verify schools")
    func testBatchSaveAndVerify() async throws {
        let repository = try await setupRepository()
        let schools = try TestDataFactory.makeSchools(count: 50)

        for school in schools {
            try await repository.save(school)
        }

        for school in schools {
            let fetched = try await repository.get(id: school.id)
            #expect(fetched != nil)
            #expect(fetched?.id == school.id)
            #expect(fetched?.name == school.name)
            #expect(fetched?.code == school.code)
        }
    }

    @Test("Save and retrieve full school")
    func testSaveAndRetrieveFullSchool() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeFullSchool()

        try await repository.save(school)
        let fetched = try await repository.get(id: school.id)

        #expect(fetched != nil)
        #expect(fetched?.name == school.name)
        #expect(fetched?.code == school.code)
        #expect(fetched?.address == school.address)
        #expect(fetched?.city == school.city)
        #expect(fetched?.country == school.country)
        #expect(fetched?.contactEmail == school.contactEmail)
        #expect(fetched?.maxStudents == school.maxStudents)
        #expect(fetched?.subscriptionTier == school.subscriptionTier)
        #expect(fetched?.metadata == school.metadata)
    }

    @Test("Save and retrieve minimal school")
    func testSaveAndRetrieveMinimalSchool() async throws {
        let repository = try await setupRepository()
        let school = try TestDataFactory.makeMinimalSchool()

        try await repository.save(school)
        let fetched = try await repository.get(id: school.id)

        #expect(fetched != nil)
        #expect(fetched?.name == "S")
        #expect(fetched?.code == "S1")
    }

    @Test("Update school preserves all fields")
    func testUpdateSchoolPreservesAllFields() async throws {
        let repository = try await setupRepository()
        let originalCreatedAt = Date(timeIntervalSince1970: 1704067200)
        let school = try TestDataFactory.makeSchool(
            name: "Original School",
            code: "ORIG-001",
            createdAt: originalCreatedAt
        )

        try await repository.save(school)

        let updatedSchool = try School(
            id: school.id,
            name: "Updated School",
            code: school.code,
            isActive: false,
            address: "123 New Address",
            city: "New City",
            createdAt: originalCreatedAt,
            updatedAt: Date()
        )
        try await repository.save(updatedSchool)

        let fetched = try await repository.get(id: school.id)

        #expect(fetched?.name == "Updated School")
        #expect(fetched?.address == "123 New Address")
        #expect(fetched?.city == "New City")
        #expect(fetched?.isActive == false)
        #expect(fetched?.createdAt == originalCreatedAt)
    }

    @Test("Get by code with multiple schools")
    func testGetByCodeWithMultipleSchools() async throws {
        let repository = try await setupRepository()

        let school1 = try TestDataFactory.makeSchool(name: "School One", code: "CODE-001")
        let school2 = try TestDataFactory.makeSchool(name: "School Two", code: "CODE-002")
        let school3 = try TestDataFactory.makeSchool(name: "School Three", code: "CODE-003")

        try await repository.save(school1)
        try await repository.save(school2)
        try await repository.save(school3)

        let fetched = try await repository.getByCode(code: "CODE-002")

        #expect(fetched != nil)
        #expect(fetched?.id == school2.id)
        #expect(fetched?.name == "School Two")
    }

    @Test("Delete multiple schools in sequence")
    func testDeleteMultipleSchoolsInSequence() async throws {
        let repository = try await setupRepository()
        let schools = try TestDataFactory.makeSchools(count: 10)

        for school in schools {
            try await repository.save(school)
        }

        for school in schools.prefix(5) {
            try await repository.delete(id: school.id)
        }

        let listed = try await repository.list()

        for school in schools.prefix(5) {
            #expect(!listed.contains { $0.id == school.id })
        }
        for school in schools.suffix(5) {
            #expect(listed.contains { $0.id == school.id })
        }
    }

    @Test("List returns empty array when no schools exist")
    func testListReturnsEmptyArrayWhenNoSchools() async throws {
        let repository = try await setupRepository()

        let listed = try await repository.list()

        #expect(listed.isEmpty)
    }

    @Test("Save school with metadata")
    func testSaveSchoolWithMetadata() async throws {
        let repository = try await setupRepository()
        let metadata: [String: JSONValue] = [
            "founded": .integer(1990),
            "accredited": .bool(true),
            "motto": .string("Excellence in Education")
        ]

        let school = try School(
            name: "Metadata School",
            code: "META-001",
            metadata: metadata
        )

        try await repository.save(school)
        let fetched = try await repository.get(id: school.id)

        #expect(fetched?.metadata == metadata)
    }
}
