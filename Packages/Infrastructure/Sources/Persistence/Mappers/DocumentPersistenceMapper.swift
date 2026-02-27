import Foundation
import EduCore
import EduFoundation

/// Mapper for converting between DocumentModel (SwiftData) and Document (domain)
///
/// This struct provides static methods for bidirectional conversion between
/// the persistence model and the domain entity.
///
/// ## Usage
///
/// ```swift
/// // Convert from persistence to domain
/// let document = try DocumentPersistenceMapper.toDomain(documentModel)
///
/// // Convert from domain to persistence (new model)
/// let model = DocumentPersistenceMapper.toModel(document, existing: nil)
///
/// // Update existing model from domain
/// let updatedModel = DocumentPersistenceMapper.toModel(document, existing: existingModel)
/// ```
///
/// ## Notes
/// - Does NOT conform to `MapperProtocol` because `@Model` types are not `Codable`
/// - Validates `type` and `state` strings against known enum cases
/// - Handles `Array` ↔ `Set` conversion for collaboratorIDs and tags
/// - Throws `DomainError.validationFailed` if data is corrupted
public struct DocumentPersistenceMapper: Sendable {
    private init() {}

    /// Converts a DocumentModel to a domain Document
    ///
    /// - Parameter model: The SwiftData model to convert
    /// - Returns: A domain Document entity
    /// - Throws: `DomainError.validationFailed` if the model contains invalid data
    public static func toDomain(_ model: DocumentModel) throws -> Document {
        // Validate and convert type
        guard let documentType = DocumentType(rawValue: model.type) else {
            throw DomainError.validationFailed(
                field: "type",
                reason: "Unknown document type: '\(model.type)'. Valid types: \(DocumentType.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }

        // Validate and convert state
        guard let documentState = DocumentState(rawValue: model.state) else {
            throw DomainError.validationFailed(
                field: "state",
                reason: "Unknown document state: '\(model.state)'. Valid states: \(DocumentState.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }

        // Build metadata from flat fields
        let metadata = DocumentMetadata(
            createdAt: model.createdAt,
            modifiedAt: model.modifiedAt,
            version: model.version,
            tags: Set(model.tags)
        )

        // Convert Arrays to Sets
        let collaboratorIDsSet = Set(model.collaboratorIDs)

        // Document.init validates title
        return try Document(
            id: model.id,
            title: model.title,
            content: model.content,
            type: documentType,
            state: documentState,
            metadata: metadata,
            ownerID: model.ownerID,
            collaboratorIDs: collaboratorIDsSet
        )
    }

    /// Converts a domain Document to a DocumentModel
    ///
    /// If an existing model is provided, updates its properties instead of
    /// creating a new instance. This is useful for SwiftData's change tracking.
    ///
    /// - Parameters:
    ///   - domain: The domain Document to convert
    ///   - existing: An optional existing DocumentModel to update
    /// - Returns: A DocumentModel with the domain entity's data
    public static func toModel(_ domain: Document, existing: DocumentModel?) -> DocumentModel {
        // Convert Sets to Arrays
        let collaboratorIDsArray = Array(domain.collaboratorIDs)
        let tagsArray = Array(domain.metadata.tags)

        if let existing = existing {
            // Update existing model in place for SwiftData change tracking
            existing.title = domain.title
            existing.content = domain.content
            existing.type = domain.type.rawValue
            existing.state = domain.state.rawValue
            existing.ownerID = domain.ownerID
            existing.collaboratorIDs = collaboratorIDsArray
            existing.createdAt = domain.metadata.createdAt
            existing.modifiedAt = domain.metadata.modifiedAt
            existing.version = domain.metadata.version
            existing.tags = tagsArray
            return existing
        } else {
            // Create new model
            return DocumentModel(
                id: domain.id,
                title: domain.title,
                content: domain.content,
                type: domain.type.rawValue,
                state: domain.state.rawValue,
                ownerID: domain.ownerID,
                collaboratorIDs: collaboratorIDsArray,
                createdAt: domain.metadata.createdAt,
                modifiedAt: domain.metadata.modifiedAt,
                version: domain.metadata.version,
                tags: tagsArray
            )
        }
    }
}
