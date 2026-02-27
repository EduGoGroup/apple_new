import Testing
import Foundation
import EduFoundation
@testable import EduModels

@Suite("DocumentMapper Tests")
struct DocumentMapperTests {

    // MARK: - toDomain Tests (Valid Document)

    @Test("toDomain with valid DTO returns Document")
    func toDomainWithValidDTO() throws {
        let dto = TestFixtures.makeDocumentDTO()

        let document = try DocumentMapper.toDomain(dto)

        #expect(document.id == dto.id)
        #expect(document.title == dto.title)
        #expect(document.content == dto.content)
        #expect(document.type == .lesson)
        #expect(document.state == .draft)
        #expect(document.ownerID == dto.ownerID)
    }

    // MARK: - toDomain Tests (DocumentType)

    @Test("toDomain with all valid types succeeds")
    func toDomainWithAllValidTypes() throws {
        let types = ["lesson", "assignment", "quiz", "syllabus", "resource", "announcement"]

        for type in types {
            let dto = TestFixtures.makeDocumentDTO(type: type)

            let document = try DocumentMapper.toDomain(dto)

            #expect(document.type.rawValue == type)
        }
    }

    @Test("toDomain with unknown type throws DomainError")
    func toDomainWithUnknownType() {
        let dto = TestFixtures.makeDocumentDTO(type: "unknown_type")

        #expect(throws: DomainError.self) {
            _ = try DocumentMapper.toDomain(dto)
        }
    }

    // MARK: - toDomain Tests (DocumentState)

    @Test("toDomain with all valid states succeeds")
    func toDomainWithAllValidStates() throws {
        let states = ["draft", "published", "archived"]

        for state in states {
            let dto = TestFixtures.makeDocumentDTO(state: state)

            let document = try DocumentMapper.toDomain(dto)

            #expect(document.state.rawValue == state)
        }
    }

    @Test("toDomain with unknown state throws DomainError")
    func toDomainWithUnknownState() {
        let dto = TestFixtures.makeDocumentDTO(state: "unknown_state")

        #expect(throws: DomainError.self) {
            _ = try DocumentMapper.toDomain(dto)
        }
    }

    // MARK: - toDomain Tests (ISO8601 Dates)

    @Test("toDomain parses ISO8601 dates correctly")
    func toDomainParsesISO8601Dates() throws {
        let dto = TestFixtures.makeDocumentDTO(
            createdAt: "2024-01-15T10:30:00.000Z",
            modifiedAt: "2024-01-16T14:45:30.500Z"
        )

        let document = try DocumentMapper.toDomain(dto)

        #expect(document.metadata.createdAt != document.metadata.modifiedAt)
    }

    @Test("toDomain with invalid createdAt date throws DomainError")
    func toDomainWithInvalidCreatedAt() {
        let dto = TestFixtures.makeDocumentDTO(createdAt: "invalid-date")

        #expect(throws: DomainError.self) {
            _ = try DocumentMapper.toDomain(dto)
        }
    }

    @Test("toDomain with invalid modifiedAt date throws DomainError")
    func toDomainWithInvalidModifiedAt() {
        let dto = TestFixtures.makeDocumentDTO(modifiedAt: "not-a-date")

        #expect(throws: DomainError.self) {
            _ = try DocumentMapper.toDomain(dto)
        }
    }

    // MARK: - toDomain Tests (Metadata)

    @Test("toDomain converts metadata correctly including tags deduplication")
    func toDomainConvertsMetadata() throws {
        let dto = TestFixtures.makeDocumentDTO(
            version: 5,
            tags: ["math", "algebra", "math"]
        )

        let document = try DocumentMapper.toDomain(dto)

        #expect(document.metadata.version == 5)
        #expect(document.metadata.tags.count == 2)
        #expect(document.metadata.tags.contains("math"))
        #expect(document.metadata.tags.contains("algebra"))
    }

    // MARK: - toDomain Tests (Collections)

    @Test("toDomain converts collaboratorIDs array to set removing duplicates")
    func toDomainConvertsCollaboratorIDs() throws {
        let collabID1 = UUID()
        let collabID2 = UUID()
        let dto = TestFixtures.makeDocumentDTO(collaboratorIDs: [collabID1, collabID2, collabID1])

        let document = try DocumentMapper.toDomain(dto)

        #expect(document.collaboratorIDs.count == 2)
        #expect(document.collaboratorIDs.contains(collabID1))
        #expect(document.collaboratorIDs.contains(collabID2))
    }

    // MARK: - toDomain Tests (Title Validation)

    @Test("toDomain with empty title throws error")
    func toDomainWithEmptyTitle() {
        let dto = TestFixtures.makeDocumentDTO(title: "")

        #expect(throws: (any Error).self) {
            _ = try DocumentMapper.toDomain(dto)
        }
    }

    // MARK: - toDomain Tests (Edge Cases)

    @Test("toDomain with empty tags succeeds")
    func toDomainWithEmptyTags() throws {
        let dto = TestFixtures.makeDocumentDTO(tags: [])

        let document = try DocumentMapper.toDomain(dto)

        #expect(document.metadata.tags.isEmpty)
    }

    @Test("toDomain with empty collaborators succeeds")
    func toDomainWithEmptyCollaborators() throws {
        let dto = TestFixtures.makeDocumentDTO(collaboratorIDs: [])

        let document = try DocumentMapper.toDomain(dto)

        #expect(document.collaboratorIDs.isEmpty)
    }

    @Test("toDomain with all fields populated succeeds")
    func toDomainWithAllFields() throws {
        let ownerID = UUID()
        let collabID = UUID()
        let dto = TestFixtures.makeDocumentDTO(
            title: "Full Document",
            content: "Full content here",
            type: "assignment",
            state: "published",
            ownerID: ownerID,
            collaboratorIDs: [collabID],
            createdAt: "2024-06-01T08:00:00.000Z",
            modifiedAt: "2024-06-02T16:30:00.000Z",
            version: 3,
            tags: ["homework", "math"]
        )

        let document = try DocumentMapper.toDomain(dto)

        #expect(document.title == "Full Document")
        #expect(document.content == "Full content here")
        #expect(document.type == .assignment)
        #expect(document.state == .published)
        #expect(document.ownerID == ownerID)
        #expect(document.collaboratorIDs.contains(collabID))
        #expect(document.metadata.version == 3)
        #expect(document.metadata.tags.count == 2)
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts Document correctly")
    func toDTOConvertsCorrectly() throws {
        let document = try Document(
            id: UUID(),
            title: "Test",
            content: "Content",
            type: .quiz,
            state: .published,
            metadata: DocumentMetadata(version: 3, tags: ["tag1"]),
            ownerID: UUID(),
            collaboratorIDs: [UUID()]
        )

        let dto = DocumentMapper.toDTO(document)

        #expect(dto.type == "quiz")
        #expect(dto.state == "published")
        #expect(dto.metadata.version == 3)
        #expect(dto.metadata.tags.count == 1)
    }

    @Test("toDTO formats dates as ISO8601")
    func toDTOFormatsDateAsISO8601() throws {
        let document = try Document(
            id: UUID(),
            title: "Test",
            content: "",
            type: .lesson,
            ownerID: UUID()
        )

        let dto = DocumentMapper.toDTO(document)

        #expect(dto.metadata.createdAt.contains("T"))
        #expect(dto.metadata.createdAt.contains("."))
        #expect(dto.metadata.createdAt.hasSuffix("Z"))
    }

    @Test("toDTO preserves fractional seconds in ISO8601 output")
    func toDTOPreservesFractionalSeconds() throws {
        let dateWithFraction = Date(timeIntervalSince1970: 1_705_314_600.123)
        let metadata = DocumentMetadata(createdAt: dateWithFraction, modifiedAt: dateWithFraction, version: 1, tags: [])
        let document = try Document(
            id: UUID(),
            title: "Fractional",
            content: "",
            type: .lesson,
            metadata: metadata,
            ownerID: UUID()
        )

        let dto = DocumentMapper.toDTO(document)

        #expect(dto.metadata.createdAt.contains(".123"))
        #expect(dto.metadata.createdAt.hasSuffix("Z"))
    }

    @Test("toDTO converts collaboratorIDs set to array")
    func toDTOConvertsCollaboratorIDs() throws {
        let collabID1 = UUID()
        let collabID2 = UUID()
        let document = try Document(
            id: UUID(),
            title: "Test",
            content: "",
            type: .lesson,
            ownerID: UUID(),
            collaboratorIDs: [collabID1, collabID2]
        )

        let dto = DocumentMapper.toDTO(document)

        #expect(dto.collaboratorIDs.count == 2)
        #expect(dto.collaboratorIDs.contains(collabID1))
        #expect(dto.collaboratorIDs.contains(collabID2))
    }

    @Test("toDTO converts tags set to array")
    func toDTOConvertsTagsSetToArray() throws {
        let document = try Document(
            id: UUID(),
            title: "Test",
            content: "",
            type: .lesson,
            metadata: DocumentMetadata(tags: ["a", "b", "c"]),
            ownerID: UUID()
        )

        let dto = DocumentMapper.toDTO(document)

        #expect(dto.metadata.tags.count == 3)
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves core data")
    func roundtripPreservesCoreData() throws {
        let original = try Document(
            id: UUID(),
            title: "Complete Document",
            content: "Full content here",
            type: .assignment,
            state: .draft,
            metadata: DocumentMetadata(version: 1, tags: ["homework", "math"]),
            ownerID: UUID(),
            collaboratorIDs: [UUID(), UUID()]
        )

        let dto = DocumentMapper.toDTO(original)
        let converted = try DocumentMapper.toDomain(dto)

        #expect(original.id == converted.id)
        #expect(original.title == converted.title)
        #expect(original.content == converted.content)
        #expect(original.type == converted.type)
        #expect(original.state == converted.state)
        #expect(original.ownerID == converted.ownerID)
        #expect(original.collaboratorIDs == converted.collaboratorIDs)
        #expect(original.metadata.version == converted.metadata.version)
        #expect(original.metadata.tags == converted.metadata.tags)
    }

    @Test("roundtrip with all document types")
    func roundtripWithAllTypes() throws {
        let types: [DocumentType] = [.lesson, .assignment, .quiz, .syllabus, .resource, .announcement]

        for type in types {
            let original = try Document(
                id: UUID(),
                title: "Type Test",
                content: "",
                type: type,
                ownerID: UUID()
            )

            let dto = DocumentMapper.toDTO(original)
            let converted = try DocumentMapper.toDomain(dto)

            #expect(original.type == converted.type)
        }
    }

    @Test("roundtrip with all document states")
    func roundtripWithAllStates() throws {
        let states: [DocumentState] = [.draft, .published, .archived]

        for state in states {
            let original = try Document(
                id: UUID(),
                title: "State Test",
                content: "",
                type: .lesson,
                state: state,
                ownerID: UUID()
            )

            let dto = DocumentMapper.toDTO(original)
            let converted = try DocumentMapper.toDomain(dto)

            #expect(original.state == converted.state)
        }
    }
}
