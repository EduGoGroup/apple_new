import Foundation

// MARK: - Document Type

/// Represents the type of document in the system.
public enum DocumentType: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    /// Lesson content document
    case lesson

    /// Assignment or homework
    case assignment

    /// Quiz or test
    case quiz

    /// Syllabus document
    case syllabus

    /// Resource/reference material
    case resource

    /// Announcement or notice
    case announcement
}

extension DocumentType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .lesson:
            return "Lesson"
        case .assignment:
            return "Assignment"
        case .quiz:
            return "Quiz"
        case .syllabus:
            return "Syllabus"
        case .resource:
            return "Resource"
        case .announcement:
            return "Announcement"
        }
    }
}

// MARK: - Document State

/// Represents the lifecycle state of a document.
///
/// Documents transition through states: draft → published → archived.
/// State transitions are validated to ensure logical flow.
public enum DocumentState: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    /// Initial state, document is being created/edited
    case draft

    /// Document is published and visible
    case published

    /// Document has been archived and is no longer active
    case archived
}

extension DocumentState: CustomStringConvertible {
    public var description: String {
        switch self {
        case .draft:
            return "Draft"
        case .published:
            return "Published"
        case .archived:
            return "Archived"
        }
    }

    /// Returns the valid next states from the current state.
    public var validTransitions: Set<DocumentState> {
        switch self {
        case .draft:
            return [.published]
        case .published:
            return [.archived, .draft]
        case .archived:
            return [.draft]
        }
    }

    /// Checks if transitioning to the given state is valid.
    ///
    /// - Parameter newState: The target state.
    /// - Returns: `true` if the transition is valid.
    public func canTransition(to newState: DocumentState) -> Bool {
        validTransitions.contains(newState)
    }
}

// MARK: - Document Metadata

/// Contains auxiliary metadata for a document.
///
/// Immutable struct storing creation and modification timestamps,
/// along with version information.
public struct DocumentMetadata: Sendable, Equatable, Hashable, Codable {
    /// When the document was created
    public let createdAt: Date

    /// When the document was last modified
    public let modifiedAt: Date

    /// Version number of the document
    public let version: Int

    /// Optional tags for categorization
    public let tags: Set<String>

    /// Creates new document metadata.
    ///
    /// - Parameters:
    ///   - createdAt: Creation timestamp. Defaults to now.
    ///   - modifiedAt: Modification timestamp. Defaults to now.
    ///   - version: Version number. Defaults to 1.
    ///   - tags: Set of tags. Defaults to empty.
    public init(
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        version: Int = 1,
        tags: Set<String> = []
    ) {
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.version = version
        self.tags = tags
    }

    /// Creates a copy with updated modification timestamp and incremented version.
    ///
    /// - Parameter modifiedAt: New modification timestamp. Defaults to now.
    /// - Returns: A new `DocumentMetadata` with updated values.
    public func incrementVersion(modifiedAt: Date = Date()) -> DocumentMetadata {
        DocumentMetadata(
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            version: version + 1,
            tags: tags
        )
    }

    /// Creates a copy with additional tags.
    ///
    /// - Parameter newTags: Tags to add.
    /// - Returns: A new `DocumentMetadata` with merged tags.
    public func addTags(_ newTags: Set<String>) -> DocumentMetadata {
        DocumentMetadata(
            createdAt: createdAt,
            modifiedAt: Date(),
            version: version,
            tags: tags.union(newTags)
        )
    }
}

// MARK: - Document Entity

/// Represents a document in the EduGo system.
///
/// `Document` is an immutable, thread-safe entity conforming to `Sendable`.
/// Supports lifecycle state management with validated transitions.
/// Owner and collaborators are referenced by ID (value semantics).
///
/// ## Example
/// ```swift
/// let doc = try Document(
///     id: UUID(),
///     title: "Introduction to Swift",
///     content: "Swift is a powerful language...",
///     type: .lesson,
///     ownerID: teacherID
/// )
///
/// // Publish the document
/// let publishedDoc = try doc.publish()
/// ```
public struct Document: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the document
    public let id: UUID

    /// Document title
    public let title: String

    /// Document content/body
    public let content: String

    /// Type of document
    public let type: DocumentType

    /// Current lifecycle state
    public let state: DocumentState

    /// Document metadata (timestamps, version, tags)
    public let metadata: DocumentMetadata

    /// ID of the user who owns this document
    public let ownerID: UUID

    /// Set of user IDs who can collaborate on this document
    public let collaboratorIDs: Set<UUID>

    // MARK: - Initialization

    /// Creates a new Document instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - title: Document title. Must not be empty.
    ///   - content: Document content. Can be empty for drafts.
    ///   - type: Type of document.
    ///   - state: Lifecycle state. Defaults to `.draft`.
    ///   - metadata: Document metadata. Defaults to new metadata.
    ///   - ownerID: ID of the owner user.
    ///   - collaboratorIDs: Set of collaborator user IDs. Defaults to empty.
    /// - Throws: `DomainError.validationFailed` if validation fails.
    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        type: DocumentType,
        state: DocumentState = .draft,
        metadata: DocumentMetadata = DocumentMetadata(),
        ownerID: UUID,
        collaboratorIDs: Set<UUID> = []
    ) throws {
        try DocumentValidator.validateTitle(title)

        self.id = id
        self.title = title.trimmingCharacters(in: .whitespaces)
        self.content = content
        self.type = type
        self.state = state
        self.metadata = metadata
        self.ownerID = ownerID
        self.collaboratorIDs = collaboratorIDs
    }

    // MARK: - Copy Methods

    /// Creates a copy with updated title.
    ///
    /// - Parameter title: The new title.
    /// - Returns: A new `Document` with updated title and metadata.
    /// - Throws: `DomainError.validationFailed` if title is empty.
    public func with(title: String) throws -> Document {
        try Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            metadata: metadata.incrementVersion(),
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs
        )
    }

    /// Creates a copy with updated content.
    ///
    /// - Parameter content: The new content.
    /// - Returns: A new `Document` with updated content and metadata.
    public func with(content: String) -> Document {
        // swiftlint:disable:next force_try
        try! Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            metadata: metadata.incrementVersion(),
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs
        )
    }

    /// Creates a copy with updated type.
    ///
    /// - Parameter type: The new document type.
    /// - Returns: A new `Document` with updated type.
    public func with(type: DocumentType) -> Document {
        // swiftlint:disable:next force_try
        try! Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            metadata: metadata.incrementVersion(),
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs
        )
    }

    // MARK: - State Transitions

    /// Publishes the document (transitions from draft to published).
    ///
    /// - Returns: A new `Document` in published state.
    /// - Throws: `DomainError.validationFailed` if transition is invalid or content is empty.
    public func publish() throws -> Document {
        try DocumentValidator.validateTransition(from: state, to: .published)
        try DocumentValidator.validateContentForPublish(content)

        return try Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: .published,
            metadata: metadata.incrementVersion(),
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs
        )
    }

    /// Archives the document (transitions from published to archived).
    ///
    /// - Returns: A new `Document` in archived state.
    /// - Throws: `DomainError.validationFailed` if transition is invalid.
    public func archive() throws -> Document {
        try DocumentValidator.validateTransition(from: state, to: .archived)

        return try Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: .archived,
            metadata: metadata.incrementVersion(),
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs
        )
    }

    /// Reverts the document to draft state.
    ///
    /// - Returns: A new `Document` in draft state.
    /// - Throws: `DomainError.validationFailed` if transition is invalid.
    public func revertToDraft() throws -> Document {
        try DocumentValidator.validateTransition(from: state, to: .draft)

        return try Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: .draft,
            metadata: metadata.incrementVersion(),
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs
        )
    }

    // MARK: - Collaborator Management

    /// Creates a copy with an additional collaborator.
    ///
    /// - Parameter userID: The user ID to add as collaborator.
    /// - Returns: A new `Document` with the collaborator added.
    public func addCollaborator(_ userID: UUID) -> Document {
        var newCollaborators = collaboratorIDs
        newCollaborators.insert(userID)
        // swiftlint:disable:next force_try
        return try! Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            metadata: metadata,
            ownerID: ownerID,
            collaboratorIDs: newCollaborators
        )
    }

    /// Creates a copy with a collaborator removed.
    ///
    /// - Parameter userID: The user ID to remove.
    /// - Returns: A new `Document` without the specified collaborator.
    public func removeCollaborator(_ userID: UUID) -> Document {
        var newCollaborators = collaboratorIDs
        newCollaborators.remove(userID)
        // swiftlint:disable:next force_try
        return try! Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            metadata: metadata,
            ownerID: ownerID,
            collaboratorIDs: newCollaborators
        )
    }

    /// Checks if a user is a collaborator on this document.
    ///
    /// - Parameter userID: The user ID to check.
    /// - Returns: `true` if the user is a collaborator.
    public func isCollaborator(_ userID: UUID) -> Bool {
        collaboratorIDs.contains(userID)
    }

    /// Checks if a user can edit this document (owner or collaborator).
    ///
    /// - Parameter userID: The user ID to check.
    /// - Returns: `true` if the user can edit.
    public func canEdit(_ userID: UUID) -> Bool {
        ownerID == userID || collaboratorIDs.contains(userID)
    }
}
