// DocumentDTO.swift
// Models
//
// Data Transfer Object for Document entity from backend API.

import Foundation

/// Data Transfer Object representing document metadata from the backend API.
///
/// ## JSON Structure
/// ```json
/// {
///     "created_at": "2024-01-15T10:30:00.000Z",
///     "modified_at": "2024-01-16T14:45:30.500Z",
///     "version": 3,
///     "tags": ["math", "algebra"]
/// }
/// ```
public struct DocumentMetadataDTO: Codable, Sendable, Equatable {
    /// ISO8601 timestamp when the document was created.
    public let createdAt: String

    /// ISO8601 timestamp when the document was last modified.
    public let modifiedAt: String

    /// Version number of the document.
    public let version: Int

    /// Array of tags for categorization.
    public let tags: [String]

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case version
        case tags
    }

    /// Creates a new DocumentMetadataDTO instance.
    ///
    /// - Parameters:
    ///   - createdAt: ISO8601 timestamp when the document was created.
    ///   - modifiedAt: ISO8601 timestamp when the document was last modified.
    ///   - version: Version number of the document.
    ///   - tags: Array of tags for categorization.
    public init(
        createdAt: String,
        modifiedAt: String,
        version: Int,
        tags: [String]
    ) {
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.version = version
        self.tags = tags
    }
}

/// Data Transfer Object representing a Document from the backend API.
///
/// This struct maps to the JSON structure returned by the backend,
/// using snake_case property names via `CodingKeys`.
///
/// ## JSON Structure
/// ```json
/// {
///     "id": "550e8400-e29b-41d4-a716-446655440000",
///     "title": "Introduction to Algebra",
///     "content": "This lesson covers...",
///     "type": "lesson",
///     "state": "published",
///     "owner_id": "user-uuid",
///     "collaborator_ids": ["uuid1", "uuid2"],
///     "metadata": {
///         "created_at": "2024-01-15T10:30:00.000Z",
///         "modified_at": "2024-01-16T14:45:30.500Z",
///         "version": 3,
///         "tags": ["math", "algebra"]
///     }
/// }
/// ```
///
/// ## Valid Types
/// lesson, assignment, quiz, syllabus, resource, announcement
///
/// ## Valid States
/// draft, published, archived
///
/// ## Usage
/// ```swift
/// let decoder = JSONDecoder()
/// let documentDTO = try decoder.decode(DocumentDTO.self, from: jsonData)
/// let document = try DocumentMapper.toDomain(documentDTO)
/// ```
public struct DocumentDTO: Codable, Sendable, Equatable {
    /// Unique identifier for the document.
    public let id: UUID

    /// Document title.
    public let title: String

    /// Document content/body.
    public let content: String

    /// Document type (e.g., "lesson", "assignment", "quiz").
    public let type: String

    /// Document state (e.g., "draft", "published", "archived").
    public let state: String

    /// ID of the user who owns this document.
    public let ownerID: UUID

    /// Array of user IDs who can collaborate on this document.
    public let collaboratorIDs: [UUID]

    /// Document metadata including timestamps, version, and tags.
    public let metadata: DocumentMetadataDTO

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case type
        case state
        case ownerID = "owner_id"
        case collaboratorIDs = "collaborator_ids"
        case metadata
    }

    /// Creates a new DocumentDTO instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the document.
    ///   - title: Document title.
    ///   - content: Document content/body.
    ///   - type: Document type.
    ///   - state: Document state.
    ///   - ownerID: ID of the user who owns this document.
    ///   - collaboratorIDs: Array of user IDs who can collaborate.
    ///   - metadata: Document metadata.
    public init(
        id: UUID,
        title: String,
        content: String,
        type: String,
        state: String,
        ownerID: UUID,
        collaboratorIDs: [UUID],
        metadata: DocumentMetadataDTO
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.state = state
        self.ownerID = ownerID
        self.collaboratorIDs = collaboratorIDs
        self.metadata = metadata
    }
}
