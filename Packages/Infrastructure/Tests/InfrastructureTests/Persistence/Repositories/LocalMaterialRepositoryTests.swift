import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("LocalMaterialRepository Tests", .serialized)
struct LocalMaterialRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalMaterialRepository {
        let provider = PersistenceContainerProvider()
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalMaterialRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get material")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let material = try TestDataFactory.makeMaterial(title: "Test PDF")

        try await repository.save(material)
        let fetched = try await repository.get(id: material.id)

        #expect(fetched != nil)
        #expect(fetched?.id == material.id)
        #expect(fetched?.title == "Test PDF")
    }

    @Test("Get returns nil for non-existent material")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved materials")
    func testListReturnsSavedMaterials() async throws {
        let repository = try await setupRepository()
        let material1 = try TestDataFactory.makeMaterial(title: "Material One")
        let material2 = try TestDataFactory.makeMaterial(title: "Material Two")

        try await repository.save(material1)
        try await repository.save(material2)

        let listed = try await repository.list()

        #expect(listed.contains { $0.id == material1.id })
        #expect(listed.contains { $0.id == material2.id })
    }

    @Test("Delete removes material")
    func testDeleteRemovesMaterial() async throws {
        let repository = try await setupRepository()
        let material = try TestDataFactory.makeMaterial()

        try await repository.save(material)
        try await repository.delete(id: material.id)

        let fetched = try await repository.get(id: material.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent material")
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

    @Test("Save same material twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let material = try TestDataFactory.makeMaterial(title: "Original")

        try await repository.save(material)

        let updatedMaterial = try Material(
            id: material.id,
            title: "Updated",
            status: material.status,
            schoolID: material.schoolID,
            isPublic: material.isPublic,
            createdAt: material.createdAt,
            updatedAt: Date()
        )
        try await repository.save(updatedMaterial)

        let fetched = try await repository.get(id: material.id)
        #expect(fetched?.title == "Updated")
    }

    // MARK: - Query Tests

    @Test("List by school returns only materials for that school")
    func testListBySchool() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let otherSchoolID = UUID()

        let material1 = try TestDataFactory.makeMaterial(title: "School Material", schoolID: schoolID)
        let material2 = try TestDataFactory.makeMaterial(title: "Other Material", schoolID: otherSchoolID)

        try await repository.save(material1)
        try await repository.save(material2)

        let schoolMaterials = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolMaterials.count == 1)
        #expect(schoolMaterials.first?.id == material1.id)
    }

    // MARK: - Extended Repository Tests

    @Test("Save and retrieve materials with all statuses")
    func testSaveAndRetrieveAllStatuses() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let materials = try TestDataFactory.makeMaterialsWithAllStatuses(schoolID: schoolID)

        for material in materials {
            try await repository.save(material)
        }

        let schoolMaterials = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolMaterials.count == materials.count)
        for material in materials {
            #expect(schoolMaterials.contains { $0.status == material.status })
        }
    }

    @Test("Batch save and verify materials")
    func testBatchSaveAndVerify() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let materials = try TestDataFactory.makeMaterials(count: 100, schoolID: schoolID)

        for material in materials {
            try await repository.save(material)
        }

        for material in materials {
            let fetched = try await repository.get(id: material.id)
            #expect(fetched != nil)
            #expect(fetched?.id == material.id)
            #expect(fetched?.title == material.title)
        }
    }

    @Test("Save and retrieve full material")
    func testSaveAndRetrieveFullMaterial() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        let material = try TestDataFactory.makeFullMaterial(schoolID: schoolID)

        try await repository.save(material)
        let fetched = try await repository.get(id: material.id)

        #expect(fetched != nil)
        #expect(fetched?.title == material.title)
        #expect(fetched?.description == material.description)
        #expect(fetched?.status == material.status)
        #expect(fetched?.fileURL == material.fileURL)
        #expect(fetched?.fileType == material.fileType)
        #expect(fetched?.fileSizeBytes == material.fileSizeBytes)
        #expect(fetched?.subject == material.subject)
        #expect(fetched?.grade == material.grade)
        #expect(fetched?.isPublic == material.isPublic)
    }

    @Test("Update material status through lifecycle")
    func testUpdateMaterialStatusLifecycle() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()
        var material = try TestDataFactory.makeMaterial(status: .uploaded, schoolID: schoolID)

        try await repository.save(material)

        // Simulate processing
        material = try Material(
            id: material.id,
            title: material.title,
            status: .processing,
            schoolID: material.schoolID,
            isPublic: material.isPublic,
            processingStartedAt: Date(),
            createdAt: material.createdAt,
            updatedAt: Date()
        )
        try await repository.save(material)

        var fetched = try await repository.get(id: material.id)
        #expect(fetched?.status == .processing)

        // Simulate completion
        material = try Material(
            id: material.id,
            title: material.title,
            status: .ready,
            schoolID: material.schoolID,
            isPublic: material.isPublic,
            processingStartedAt: material.processingStartedAt,
            processingCompletedAt: Date(),
            createdAt: material.createdAt,
            updatedAt: Date()
        )
        try await repository.save(material)

        fetched = try await repository.get(id: material.id)
        #expect(fetched?.status == .ready)
        #expect(fetched?.processingCompletedAt != nil)
    }

    @Test("List by school with multiple materials")
    func testListBySchoolWithMultipleMaterials() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let materials = try (0..<20).map { i in
            try TestDataFactory.makeMaterial(
                title: "Material \(i)",
                schoolID: schoolID
            )
        }

        for material in materials {
            try await repository.save(material)
        }

        let schoolMaterials = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolMaterials.count == 20)
    }

    @Test("Delete material from school list")
    func testDeleteMaterialFromSchoolList() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let material1 = try TestDataFactory.makeMaterial(title: "Material 1", schoolID: schoolID)
        let material2 = try TestDataFactory.makeMaterial(title: "Material 2", schoolID: schoolID)

        try await repository.save(material1)
        try await repository.save(material2)

        try await repository.delete(id: material1.id)

        let schoolMaterials = try await repository.listBySchool(schoolID: schoolID)

        #expect(schoolMaterials.count == 1)
        #expect(schoolMaterials.first?.id == material2.id)
    }

    @Test("List returns empty array when no materials exist")
    func testListReturnsEmptyArrayWhenNoMaterials() async throws {
        let repository = try await setupRepository()

        let listed = try await repository.list()

        #expect(listed.isEmpty)
    }

    @Test("Save public and private materials")
    func testSavePublicAndPrivateMaterials() async throws {
        let repository = try await setupRepository()
        let schoolID = UUID()

        let publicMaterial = try TestDataFactory.makeMaterial(title: "Public", schoolID: schoolID, isPublic: true)
        let privateMaterial = try TestDataFactory.makeMaterial(title: "Private", schoolID: schoolID, isPublic: false)

        try await repository.save(publicMaterial)
        try await repository.save(privateMaterial)

        let fetchedPublic = try await repository.get(id: publicMaterial.id)
        let fetchedPrivate = try await repository.get(id: privateMaterial.id)

        #expect(fetchedPublic?.isPublic == true)
        #expect(fetchedPrivate?.isPublic == false)
    }
}
