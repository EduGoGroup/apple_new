// DocumentMapper.swift
// Models
//
// Bidirectional mapper between DocumentDTO and Document domain entity.

import Foundation
import EduFoundation

/// Mapper for bidirectional conversion between `DocumentDTO` and `Document` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model, including complex handling of:
/// - ISO8601 date parsing and formatting
/// - Document type and state enum validation
/// - Nested metadata conversion
///
/// ## Overview
/// `DocumentMapper` provides type-safe conversion that:
/// - Parses ISO8601 date strings to `Date` objects
/// - Validates document type and state strings against known enum values
/// - Converts nested `DocumentMetadataDTO` to `DocumentMetadata`
/// - Converts `Array` to `Set` for collaborator IDs and tags
/// - Delegates title validation to `Document.init`
///
/// ## Example
/// ```swift
/// // JSON from backend
/// let json = """
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
/// """
///
/// // Decode and convert to domain
/// let dto = try JSONDecoder().decode(DocumentDTO.self, from: json.data(using: .utf8)!)
/// let document = try DocumentMapper.toDomain(dto)
///
/// // Convert back to DTO
/// let backToDTO = DocumentMapper.toDTO(document)
/// ```
///
/// ## Error Handling
/// The `toDomain` method can throw:
/// - `DomainError.validationFailed(field: "type", ...)` if document type is unknown
/// - `DomainError.validationFailed(field: "state", ...)` if document state is unknown
/// - `DomainError.validationFailed(field: "metadata.created_at", ...)` if date format is invalid
/// - `DomainError.validationFailed(field: "metadata.modified_at", ...)` if date format is invalid
/// - `DomainError.validationFailed(field: "title", ...)` if title is empty (from `Document.init`)
public struct DocumentMapper: MapperProtocol {
    public typealias DTO = DocumentDTO
    public typealias Domain = Document

    /// ISO8601 formatting helpers with fractional seconds support for backend compatibility.
    /// Note: formatters are created per-call to avoid shared mutable state under strict concurrency.

    /// Converts a `DocumentDTO` from the backend to a `Document` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: A validated `Document` domain entity.
    /// - Throws: `DomainError.validationFailed` if type, state, dates, or title are invalid.
    /// - Note: `Document.init` validates title via `DocumentValidator.validateTitle()` and applies trim.
    public static func toDomain(_ dto: DocumentDTO) throws -> Document {
        // 1. Parse and validate document type
        guard let type = DocumentType(rawValue: dto.type) else {
            throw DomainError.validationFailed(
                field: "type",
                reason: "Tipo de documento desconocido: '\(dto.type)'. Valores válidos: \(DocumentType.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }

        // 2. Parse and validate document state
        guard let state = DocumentState(rawValue: dto.state) else {
            throw DomainError.validationFailed(
                field: "state",
                reason: "Estado de documento desconocido: '\(dto.state)'. Valores válidos: \(DocumentState.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }

        // 3. Parse metadata with ISO8601 dates
        let metadata = try mapMetadataToDomain(dto.metadata)

        // 4. Construct document
        // Document.init validates title via DocumentValidator.validateTitle() and applies trim
        return try Document(
            id: dto.id,
            title: dto.title,
            content: dto.content,
            type: type,
            state: state,
            metadata: metadata,
            ownerID: dto.ownerID,
            collaboratorIDs: Set(dto.collaboratorIDs)
        )
    }

    /// Converts a `Document` domain entity to a `DocumentDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: A `DocumentDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: Document) -> DocumentDTO {
        DocumentDTO(
            id: domain.id,
            title: domain.title,
            content: domain.content,
            type: domain.type.rawValue,
            state: domain.state.rawValue,
            ownerID: domain.ownerID,
            collaboratorIDs: Array(domain.collaboratorIDs),
            metadata: mapMetadataToDTO(domain.metadata)
        )
    }

    // MARK: - Private Helpers

    /// Converts `DocumentMetadataDTO` to `DocumentMetadata`.
    ///
    /// - Parameter dto: The metadata DTO with ISO8601 date strings.
    /// - Returns: A `DocumentMetadata` with parsed `Date` objects.
    /// - Throws: `DomainError.validationFailed` if date strings have invalid format.
    private static func mapMetadataToDomain(_ dto: DocumentMetadataDTO) throws -> DocumentMetadata {
        guard let createdAt = parseISO8601(dto.createdAt) else {
            throw DomainError.validationFailed(
                field: "metadata.created_at",
                reason: "Formato de fecha inválido: '\(dto.createdAt)'. Esperado: ISO8601 (ej: 2024-01-15T10:30:00.000Z)"
            )
        }

        guard let modifiedAt = parseISO8601(dto.modifiedAt) else {
            throw DomainError.validationFailed(
                field: "metadata.modified_at",
                reason: "Formato de fecha inválido: '\(dto.modifiedAt)'. Esperado: ISO8601 (ej: 2024-01-15T10:30:00.000Z)"
            )
        }

        return DocumentMetadata(
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            version: dto.version,
            tags: Set(dto.tags)
        )
    }

    /// Converts `DocumentMetadata` to `DocumentMetadataDTO`.
    ///
    /// - Parameter metadata: The domain metadata with `Date` objects.
    /// - Returns: A `DocumentMetadataDTO` with ISO8601 formatted date strings.
    private static func mapMetadataToDTO(_ metadata: DocumentMetadata) -> DocumentMetadataDTO {
        DocumentMetadataDTO(
            createdAt: formatISO8601(metadata.createdAt),
            modifiedAt: formatISO8601(metadata.modifiedAt),
            version: metadata.version,
            tags: Array(metadata.tags)
        )
    }

    /// Parses an ISO8601 string with fractional seconds, falling back to non-fractional format.
    private static func parseISO8601(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }

        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        return fallbackFormatter.date(from: value)
    }

    /// Formats a date to ISO8601 with fractional seconds.
    private static func formatISO8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
