import Testing
import Foundation
import SwiftData
import EduCore
import EduFoundation
@testable import EduPersistence

@Suite("DocumentPersistenceMapper Tests")
struct DocumentPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical document")
    func testRoundtrip() throws {
        let original = try TestDataFactory.makeDocument(
            title: "Test Lesson",
            content: "Lesson content here",
            type: .lesson,
            state: .draft,
            tags: ["swift", "testing"]
        )

        // Domain -> Model
        let model = DocumentPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try DocumentPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.title == original.title)
        #expect(restored.content == original.content)
        #expect(restored.type == original.type)
        #expect(restored.state == original.state)
        #expect(restored.ownerID == original.ownerID)
        #expect(restored.collaboratorIDs == original.collaboratorIDs)
        #expect(restored.metadata.version == original.metadata.version)
        #expect(restored.metadata.tags == original.metadata.tags)
    }

    @Test("Roundtrip preserves all document types")
    func testRoundtripAllTypes() throws {
        for type in DocumentType.allCases {
            let original = try TestDataFactory.makeDocument(type: type)
            let model = DocumentPersistenceMapper.toModel(original, existing: nil)
            let restored = try DocumentPersistenceMapper.toDomain(model)

            #expect(restored.type == type)
        }
    }

    @Test("Roundtrip preserves all document states")
    func testRoundtripAllStates() throws {
        for state in DocumentState.allCases {
            let original = try TestDataFactory.makeDocument(state: state)
            let model = DocumentPersistenceMapper.toModel(original, existing: nil)
            let restored = try DocumentPersistenceMapper.toDomain(model)

            #expect(restored.state == state)
        }
    }

    // MARK: - toModel Tests

    @Test("toModel stores type as rawValue string")
    func testTypeStoredAsRawValue() throws {
        let document = try TestDataFactory.makeDocument(type: .quiz)
        let model = DocumentPersistenceMapper.toModel(document, existing: nil)

        #expect(model.type == "quiz")
    }

    @Test("toModel stores state as rawValue string")
    func testStateStoredAsRawValue() throws {
        let document = try TestDataFactory.makeDocument(state: .published)
        let model = DocumentPersistenceMapper.toModel(document, existing: nil)

        #expect(model.state == "published")
    }

    @Test("toModel flattens metadata to model fields")
    func testMetadataFlattened() throws {
        let createdAt = Date()
        let modifiedAt = Date().addingTimeInterval(3600)
        let metadata = DocumentMetadata(
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            version: 5,
            tags: ["tag1", "tag2"]
        )
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            state: .draft,
            metadata: metadata,
            ownerID: UUID()
        )

        let model = DocumentPersistenceMapper.toModel(document, existing: nil)

        #expect(model.createdAt == createdAt)
        #expect(model.modifiedAt == modifiedAt)
        #expect(model.version == 5)
        #expect(model.tags.count == 2)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() throws {
        let doc1 = try TestDataFactory.makeDocument(title: "Original")
        let existingModel = DocumentPersistenceMapper.toModel(doc1, existing: nil)

        let doc2 = try Document(
            id: doc1.id,
            title: "Updated",
            content: "New content",
            type: .quiz,
            state: .published,
            metadata: doc1.metadata,
            ownerID: doc1.ownerID
        )

        let updatedModel = DocumentPersistenceMapper.toModel(doc2, existing: existingModel)

        #expect(updatedModel === existingModel)
        #expect(updatedModel.title == "Updated")
        #expect(updatedModel.type == "quiz")
        #expect(updatedModel.state == "published")
    }

    // MARK: - toDomain Tests

    @Test("toDomain reconstructs metadata from flat fields")
    func testMetadataReconstructed() throws {
        let model = DocumentModel(
            title: "Test",
            content: "Content",
            type: "lesson",
            ownerID: UUID(),
            createdAt: Date(),
            modifiedAt: Date(),
            version: 3,
            tags: ["a", "b", "c"]
        )

        let document = try DocumentPersistenceMapper.toDomain(model)

        #expect(document.metadata.version == 3)
        #expect(document.metadata.tags.count == 3)
    }

    @Test("toDomain throws for unknown document type")
    func testThrowsForUnknownType() {
        let model = DocumentModel(
            title: "Test",
            content: "Content",
            type: "unknown_type",
            ownerID: UUID()
        )

        #expect(throws: DomainError.self) {
            _ = try DocumentPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for unknown document state")
    func testThrowsForUnknownState() {
        let model = DocumentModel(
            title: "Test",
            content: "Content",
            type: "lesson",
            state: "invalid_state",
            ownerID: UUID()
        )

        #expect(throws: DomainError.self) {
            _ = try DocumentPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for empty title")
    func testThrowsForEmptyTitle() {
        let model = DocumentModel(
            title: "",
            content: "Content",
            type: "lesson",
            ownerID: UUID()
        )

        #expect(throws: DomainError.self) {
            _ = try DocumentPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain converts collaboratorIDs Array to Set")
    func testCollaboratorArrayToSet() throws {
        let collaboratorID = UUID()
        let model = DocumentModel(
            title: "Test",
            content: "Content",
            type: "lesson",
            ownerID: UUID(),
            collaboratorIDs: [collaboratorID, collaboratorID] // duplicates
        )

        let document = try DocumentPersistenceMapper.toDomain(model)

        #expect(document.collaboratorIDs.count == 1)
        #expect(document.collaboratorIDs.contains(collaboratorID))
    }

    @Test("toDomain converts tags Array to Set")
    func testTagsArrayToSet() throws {
        let model = DocumentModel(
            title: "Test",
            content: "Content",
            type: "lesson",
            ownerID: UUID(),
            tags: ["tag", "tag", "tag"] // duplicates
        )

        let document = try DocumentPersistenceMapper.toDomain(model)

        #expect(document.metadata.tags.count == 1)
    }
}
