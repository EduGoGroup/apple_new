import Foundation
import SwiftData

/// SwiftData model for persisting Document entities
///
/// This model stores document data in SwiftData and can be converted to/from
/// the domain `Document` type using `DocumentPersistenceMapper`.
///
/// ## Notes
/// - `type` and `state` are stored as String (rawValue of their respective enums)
/// - Metadata fields are stored flat (SwiftData doesn't support embedded structs)
/// - Uses `[UUID]` for collaboratorIDs and `[String]` for tags (SwiftData limitation)
@Model
public final class DocumentModel {
    /// Unique identifier for the document
    @Attribute(.unique)
    public var id: UUID

    /// Document title
    public var title: String

    /// Document content (body text)
    public var content: String

    /// Document type as rawValue string (e.g., "lesson", "quiz")
    public var type: String

    /// Document state as rawValue string (e.g., "draft", "published")
    public var state: String

    /// ID of the document owner
    public var ownerID: UUID

    /// Array of collaborator IDs
    /// Stored as Array because SwiftData doesn't support Set<UUID>
    public var collaboratorIDs: [UUID]

    // MARK: - Metadata (stored flat, not as embedded struct)

    /// Timestamp when the document was created
    public var createdAt: Date

    /// Timestamp when the document was last modified
    public var modifiedAt: Date

    /// Version number (incremented on each modification)
    public var version: Int

    /// Tags for categorization
    /// Stored as Array because SwiftData doesn't support Set<String>
    public var tags: [String]

    /// Creates a new DocumentModel instance
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Document title
    ///   - content: Document content
    ///   - type: Document type as rawValue string
    ///   - state: Document state as rawValue string (defaults to "draft")
    ///   - ownerID: ID of the document owner
    ///   - collaboratorIDs: Array of collaborator IDs (defaults to empty)
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - modifiedAt: Modification timestamp (defaults to now)
    ///   - version: Version number (defaults to 1)
    ///   - tags: Array of tags (defaults to empty)
    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        type: String,
        state: String = "draft",
        ownerID: UUID,
        collaboratorIDs: [UUID] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date(),
        version: Int = 1,
        tags: [String] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.type = type
        self.state = state
        self.ownerID = ownerID
        self.collaboratorIDs = collaboratorIDs
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.version = version
        self.tags = tags
    }
}
