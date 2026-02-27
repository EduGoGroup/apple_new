import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("LocalDocumentRepository Tests", .serialized)
struct LocalDocumentRepositoryTests {
    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalDocumentRepository {
        let provider = PersistenceContainerProvider()
        // Always configure a fresh provider to avoid cross-suite interference
        try await provider.configure(
            with: .testing,
            schema: LocalPersistenceSchema.current
        )
        return LocalDocumentRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get document")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let document = try TestDataFactory.makeDocument(title: "Test Lesson")

        try await repository.save(document)
        let fetched = try await repository.get(id: document.id)

        #expect(fetched != nil)
        #expect(fetched?.id == document.id)
        #expect(fetched?.title == "Test Lesson")
    }

    @Test("Get returns nil for non-existent document")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("Delete removes document")
    func testDeleteRemovesDocument() async throws {
        let repository = try await setupRepository()
        let document = try TestDataFactory.makeDocument()

        try await repository.save(document)
        try await repository.delete(id: document.id)

        let fetched = try await repository.get(id: document.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent document")
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

    // MARK: - Search Tests

    @Test("Search finds document by title")
    func testSearchByTitle() async throws {
        let repository = try await setupRepository()
        let document = try TestDataFactory.makeDocument(
            title: "Swift Programming Guide",
            content: "Basic content"
        )

        try await repository.save(document)

        let results = try await repository.search(query: "Swift")

        #expect(results.contains { $0.id == document.id })
    }

    @Test("Search finds document by content")
    func testSearchByContent() async throws {
        let repository = try await setupRepository()
        let document = try TestDataFactory.makeDocument(
            title: "Generic Title",
            content: "This document covers concurrency patterns in detail"
        )

        try await repository.save(document)

        let results = try await repository.search(query: "concurrency")

        #expect(results.contains { $0.id == document.id })
    }

    @Test("Search is case-insensitive")
    func testSearchCaseInsensitive() async throws {
        let repository = try await setupRepository()
        let document = try TestDataFactory.makeDocument(
            title: "SwiftData Tutorial",
            content: "Learn SwiftData"
        )

        try await repository.save(document)

        let resultsLower = try await repository.search(query: "swiftdata")
        let resultsUpper = try await repository.search(query: "SWIFTDATA")

        #expect(resultsLower.contains { $0.id == document.id })
        #expect(resultsUpper.contains { $0.id == document.id })
    }

    @Test("Search returns empty array for no matches")
    func testSearchReturnsEmptyForNoMatch() async throws {
        let repository = try await setupRepository()
        let document = try TestDataFactory.makeDocument(
            title: "Test Document",
            content: "Test content"
        )

        try await repository.save(document)

        let results = try await repository.search(query: "nonexistent_xyz_query_12345")

        #expect(results.isEmpty)
    }

    @Test("Search returns empty for empty query")
    func testSearchEmptyQuery() async throws {
        let repository = try await setupRepository()

        let results = try await repository.search(query: "")

        #expect(results.isEmpty)
    }

    @Test("Search returns empty for whitespace-only query")
    func testSearchWhitespaceQuery() async throws {
        let repository = try await setupRepository()

        let results = try await repository.search(query: "   ")

        #expect(results.isEmpty)
    }

    // MARK: - Version Auto-Increment Tests

    @Test("Save increments version for existing document")
    func testSaveIncrementsVersion() async throws {
        let repository = try await setupRepository()
        let document = try TestDataFactory.makeDocument(version: 1)

        try await repository.save(document)

        // Save again (update) - need to re-fetch and save the same document
        let fetched = try await repository.get(id: document.id)
        guard let fetchedDoc = fetched else {
            Issue.record("Document should exist")
            return
        }

        try await repository.save(fetchedDoc)

        let finalFetch = try await repository.get(id: document.id)

        #expect(finalFetch?.metadata.version == 2)
    }

    @Test("New document keeps original version")
    func testNewDocumentKeepsOriginalVersion() async throws {
        let repository = try await setupRepository()
        let document = try TestDataFactory.makeDocument(version: 1)

        try await repository.save(document)

        let fetched = try await repository.get(id: document.id)

        #expect(fetched?.metadata.version == 1)
    }

    // MARK: - Type and State Tests

    @Test("Save preserves document type")
    func testSavePreservesType() async throws {
        let repository = try await setupRepository()

        for type in DocumentType.allCases {
            let document = try TestDataFactory.makeDocument(type: type)
            try await repository.save(document)

            let fetched = try await repository.get(id: document.id)
            #expect(fetched?.type == type)
        }
    }

    @Test("Save preserves document state")
    func testSavePreservesState() async throws {
        let repository = try await setupRepository()

        for state in DocumentState.allCases {
            let document = try TestDataFactory.makeDocument(state: state)
            try await repository.save(document)

            let fetched = try await repository.get(id: document.id)
            #expect(fetched?.state == state)
        }
    }
}
