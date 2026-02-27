import Testing
import Foundation
import EduFoundation
@testable import EduModels

@Suite("Document Entity Tests")
struct DocumentTests {

    // MARK: - DocumentType Tests

    @Test("DocumentType has all expected cases")
    func testDocumentTypeCases() {
        let allCases = DocumentType.allCases
        #expect(allCases.count == 6)
        #expect(allCases.contains(.lesson))
        #expect(allCases.contains(.assignment))
        #expect(allCases.contains(.quiz))
        #expect(allCases.contains(.syllabus))
        #expect(allCases.contains(.resource))
        #expect(allCases.contains(.announcement))
    }

    @Test("DocumentType has meaningful descriptions")
    func testDocumentTypeDescriptions() {
        #expect(DocumentType.lesson.description == "Lesson")
        #expect(DocumentType.assignment.description == "Assignment")
        #expect(DocumentType.quiz.description == "Quiz")
        #expect(DocumentType.syllabus.description == "Syllabus")
        #expect(DocumentType.resource.description == "Resource")
        #expect(DocumentType.announcement.description == "Announcement")
    }

    // MARK: - DocumentState Tests

    @Test("DocumentState has all expected cases")
    func testDocumentStateCases() {
        let allCases = DocumentState.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.draft))
        #expect(allCases.contains(.published))
        #expect(allCases.contains(.archived))
    }

    @Test("DocumentState has meaningful descriptions")
    func testDocumentStateDescriptions() {
        #expect(DocumentState.draft.description == "Draft")
        #expect(DocumentState.published.description == "Published")
        #expect(DocumentState.archived.description == "Archived")
    }

    @Test("DocumentState valid transitions from draft")
    func testDraftTransitions() {
        let draft = DocumentState.draft
        #expect(draft.canTransition(to: .published))
        #expect(!draft.canTransition(to: .archived))
        #expect(!draft.canTransition(to: .draft))
    }

    @Test("DocumentState valid transitions from published")
    func testPublishedTransitions() {
        let published = DocumentState.published
        #expect(published.canTransition(to: .archived))
        #expect(published.canTransition(to: .draft))
        #expect(!published.canTransition(to: .published))
    }

    @Test("DocumentState valid transitions from archived")
    func testArchivedTransitions() {
        let archived = DocumentState.archived
        #expect(archived.canTransition(to: .draft))
        #expect(!archived.canTransition(to: .published))
        #expect(!archived.canTransition(to: .archived))
    }

    // MARK: - DocumentMetadata Tests

    @Test("DocumentMetadata creation with defaults")
    func testMetadataDefaults() {
        let metadata = DocumentMetadata()

        #expect(metadata.version == 1)
        #expect(metadata.tags.isEmpty)
    }

    @Test("DocumentMetadata incrementVersion updates version and modifiedAt")
    func testMetadataIncrementVersion() {
        let metadata = DocumentMetadata(version: 1)
        let updated = metadata.incrementVersion()

        #expect(updated.version == 2)
        #expect(updated.createdAt == metadata.createdAt)
        #expect(updated.modifiedAt >= metadata.modifiedAt)
    }

    @Test("DocumentMetadata addTags merges tags")
    func testMetadataAddTags() {
        let metadata = DocumentMetadata(tags: ["swift"])
        let updated = metadata.addTags(["ios", "macos"])

        #expect(updated.tags.count == 3)
        #expect(updated.tags.contains("swift"))
        #expect(updated.tags.contains("ios"))
        #expect(updated.tags.contains("macos"))
    }

    // MARK: - Document Initialization Tests

    @Test("Document creation with valid data")
    func testValidDocumentCreation() throws {
        let ownerID = UUID()
        let document = try Document(
            title: "Introduction to Swift",
            content: "Swift is a powerful language...",
            type: .lesson,
            ownerID: ownerID
        )

        #expect(document.title == "Introduction to Swift")
        #expect(document.content == "Swift is a powerful language...")
        #expect(document.type == .lesson)
        #expect(document.state == .draft)
        #expect(document.ownerID == ownerID)
        #expect(document.collaboratorIDs.isEmpty)
    }

    @Test("Document creation trims whitespace from title")
    func testTitleTrimming() throws {
        let document = try Document(
            title: "  Test Title  ",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )

        #expect(document.title == "Test Title")
    }

    @Test("Document creation with custom ID")
    func testCustomID() throws {
        let customID = UUID()
        let document = try Document(
            id: customID,
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )

        #expect(document.id == customID)
    }

    @Test("Document creation with initial collaborators")
    func testInitialCollaborators() throws {
        let collab1 = UUID()
        let collab2 = UUID()
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID(),
            collaboratorIDs: [collab1, collab2]
        )

        #expect(document.collaboratorIDs.count == 2)
        #expect(document.collaboratorIDs.contains(collab1))
        #expect(document.collaboratorIDs.contains(collab2))
    }

    // MARK: - Document Validation Tests

    @Test("Document creation fails with empty title")
    func testEmptyTitleFails() {
        #expect {
            _ = try Document(
                title: "",
                content: "Content",
                type: .lesson,
                ownerID: UUID()
            )
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "title" else {
                return false
            }
            return true
        }
    }

    @Test("Document creation fails with whitespace-only title")
    func testWhitespaceTitleFails() {
        #expect {
            _ = try Document(
                title: "   ",
                content: "Content",
                type: .lesson,
                ownerID: UUID()
            )
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "title" else {
                return false
            }
            return true
        }
    }

    @Test("Document creation allows empty content for drafts")
    func testEmptyContentAllowed() throws {
        let document = try Document(
            title: "Draft",
            content: "",
            type: .lesson,
            ownerID: UUID()
        )

        #expect(document.content.isEmpty)
    }

    // MARK: - Copy Method Tests

    @Test("with(title:) creates copy with new title")
    func testWithTitle() throws {
        let document = try Document(
            title: "Old Title",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )
        let updated = try document.with(title: "New Title")

        #expect(updated.title == "New Title")
        #expect(updated.id == document.id)
        #expect(updated.metadata.version > document.metadata.version)
    }

    @Test("with(content:) creates copy with new content")
    func testWithContent() throws {
        let document = try Document(
            title: "Title",
            content: "Old Content",
            type: .lesson,
            ownerID: UUID()
        )
        let updated = document.with(content: "New Content")

        #expect(updated.content == "New Content")
        #expect(updated.id == document.id)
    }

    @Test("with(type:) creates copy with new type")
    func testWithType() throws {
        let document = try Document(
            title: "Title",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )
        let updated = document.with(type: .assignment)

        #expect(updated.type == .assignment)
        #expect(updated.id == document.id)
    }

    // MARK: - State Transition Tests

    @Test("publish transitions draft to published")
    func testPublish() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )
        let published = try document.publish()

        #expect(published.state == .published)
        #expect(published.metadata.version > document.metadata.version)
    }

    @Test("publish fails with empty content")
    func testPublishEmptyContentFails() throws {
        let document = try Document(
            title: "Test",
            content: "",
            type: .lesson,
            ownerID: UUID()
        )

        #expect {
            _ = try document.publish()
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "content" else {
                return false
            }
            return true
        }
    }

    @Test("publish fails with whitespace-only content")
    func testPublishWhitespaceContentFails() throws {
        let document = try Document(
            title: "Test",
            content: "   \n   ",
            type: .lesson,
            ownerID: UUID()
        )

        #expect {
            _ = try document.publish()
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "content" else {
                return false
            }
            return true
        }
    }

    @Test("publish fails from archived state")
    func testPublishFromArchivedFails() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            state: .archived,
            ownerID: UUID()
        )

        #expect {
            _ = try document.publish()
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .invalidOperation(let operation) = domainError,
                  operation.contains("archived") && operation.contains("published") else {
                return false
            }
            return true
        }
    }

    @Test("archive transitions published to archived")
    func testArchive() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            state: .published,
            ownerID: UUID()
        )
        let archived = try document.archive()

        #expect(archived.state == .archived)
    }

    @Test("archive fails from draft state")
    func testArchiveFromDraftFails() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )

        #expect {
            _ = try document.archive()
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .invalidOperation(let operation) = domainError,
                  operation.contains("draft") && operation.contains("archived") else {
                return false
            }
            return true
        }
    }

    @Test("revertToDraft transitions published to draft")
    func testRevertToDraftFromPublished() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            state: .published,
            ownerID: UUID()
        )
        let draft = try document.revertToDraft()

        #expect(draft.state == .draft)
    }

    @Test("revertToDraft transitions archived to draft")
    func testRevertToDraftFromArchived() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            state: .archived,
            ownerID: UUID()
        )
        let draft = try document.revertToDraft()

        #expect(draft.state == .draft)
    }

    // MARK: - Collaborator Management Tests

    @Test("addCollaborator adds collaborator to document")
    func testAddCollaborator() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )
        let collabID = UUID()
        let updated = document.addCollaborator(collabID)

        #expect(updated.collaboratorIDs.contains(collabID))
        #expect(updated.collaboratorIDs.count == 1)
    }

    @Test("addCollaborator is idempotent")
    func testAddCollaboratorIdempotent() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )
        let collabID = UUID()
        let updated = document.addCollaborator(collabID).addCollaborator(collabID)

        #expect(updated.collaboratorIDs.count == 1)
    }

    @Test("removeCollaborator removes collaborator from document")
    func testRemoveCollaborator() throws {
        let collabID = UUID()
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID(),
            collaboratorIDs: [collabID]
        )
        let updated = document.removeCollaborator(collabID)

        #expect(!updated.collaboratorIDs.contains(collabID))
        #expect(updated.collaboratorIDs.isEmpty)
    }

    @Test("isCollaborator returns correct value")
    func testIsCollaborator() throws {
        let collabID = UUID()
        let otherID = UUID()
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID(),
            collaboratorIDs: [collabID]
        )

        #expect(document.isCollaborator(collabID))
        #expect(!document.isCollaborator(otherID))
    }

    @Test("canEdit returns true for owner")
    func testCanEditOwner() throws {
        let ownerID = UUID()
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: ownerID
        )

        #expect(document.canEdit(ownerID))
    }

    @Test("canEdit returns true for collaborator")
    func testCanEditCollaborator() throws {
        let collabID = UUID()
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID(),
            collaboratorIDs: [collabID]
        )

        #expect(document.canEdit(collabID))
    }

    @Test("canEdit returns false for non-collaborator")
    func testCanEditNonCollaborator() throws {
        let document = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )

        #expect(!document.canEdit(UUID()))
    }

    // MARK: - Protocol Conformance Tests

    @Test("Document conforms to Equatable")
    func testEquatable() throws {
        let id = UUID()
        let ownerID = UUID()
        let metadata = DocumentMetadata()
        let doc1 = try Document(
            id: id,
            title: "Test",
            content: "Content",
            type: .lesson,
            metadata: metadata,
            ownerID: ownerID
        )
        let doc2 = try Document(
            id: id,
            title: "Test",
            content: "Content",
            type: .lesson,
            metadata: metadata,
            ownerID: ownerID
        )
        let doc3 = try Document(
            title: "Test",
            content: "Content",
            type: .lesson,
            ownerID: ownerID
        )

        #expect(doc1 == doc2)
        #expect(doc1 != doc3)
    }

    @Test("Document conforms to Hashable")
    func testHashable() throws {
        let doc1 = try Document(
            title: "Test 1",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )
        let doc2 = try Document(
            title: "Test 2",
            content: "Content",
            type: .lesson,
            ownerID: UUID()
        )

        var docSet: Set<Document> = []
        docSet.insert(doc1)
        docSet.insert(doc2)

        #expect(docSet.count == 2)
    }

    // MARK: - Error Description Tests

    @Test("DomainError has meaningful descriptions for document operations")
    func testErrorDescriptions() {
        let emptyTitle = DomainError.validationFailed(field: "title", reason: "Title cannot be empty")
        let emptyContent = DomainError.validationFailed(field: "content", reason: "Content cannot be empty")
        let invalidTransition = DomainError.invalidOperation(operation: "Cannot transition from draft to archived")

        #expect(emptyTitle.errorDescription?.contains("title") == true)
        #expect(emptyTitle.errorDescription?.contains("empty") == true)
        #expect(emptyContent.errorDescription?.contains("content") == true)
        #expect(emptyContent.errorDescription?.contains("empty") == true)
        #expect(invalidTransition.errorDescription?.contains("draft") == true)
        #expect(invalidTransition.errorDescription?.contains("archived") == true)
    }
}
