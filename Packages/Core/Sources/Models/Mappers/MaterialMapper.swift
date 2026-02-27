// MaterialMapper.swift
// Models
//
// Bidirectional mapper between MaterialDTO and Material domain entity.

import Foundation

/// Mapper for bidirectional conversion between `MaterialDTO` and `Material` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model.
///
/// ## Overview
/// `MaterialMapper` provides type-safe conversion that:
/// - Maps `file_url` (snake_case) to `fileURL` (camelCase) with URL parsing
/// - Maps `school_id`/`academic_unit_id` to `schoolID`/`academicUnitID`
/// - Converts string `status` to `MaterialStatus` enum
/// - Handles nullable fields like `deleted_at`, `processing_*_at`
/// - Preserves all material properties during roundtrip conversion
///
/// ## Example
/// ```swift
/// // DTO from backend
/// let dto = MaterialDTO(
///     id: UUID(),
///     title: "Introduction to Calculus",
///     description: "A comprehensive guide",
///     status: "ready",
///     fileURL: "https://example.com/file.pdf",
///     fileType: "application/pdf",
///     fileSizeBytes: 1048576,
///     schoolID: schoolID,
///     academicUnitID: nil,
///     uploadedByTeacherID: teacherID,
///     subject: "Mathematics",
///     grade: "12th Grade",
///     isPublic: false,
///     processingStartedAt: Date(),
///     processingCompletedAt: Date(),
///     createdAt: Date(),
///     updatedAt: Date(),
///     deletedAt: nil
/// )
///
/// // Convert to domain
/// let material = try MaterialMapper.toDomain(dto)
///
/// // Convert back to DTO
/// let backToDTO = MaterialMapper.toDTO(material)
/// ```
///
/// ## Notes
/// - The extension methods on `MaterialDTO` and `Material` (`toDomain()`, `toDTO()`) are preferred
///   for direct conversion. This mapper exists for `MapperProtocol` conformance.
public struct MaterialMapper: MapperProtocol {
    public typealias DTO = MaterialDTO
    public typealias Domain = Material

    /// Converts a `MaterialDTO` from the backend to a `Material` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: A `Material` domain entity.
    /// - Throws: `DomainError.validationFailed` if title is empty or status is unknown.
    public static func toDomain(_ dto: MaterialDTO) throws -> Material {
        try dto.toDomain()
    }

    /// Converts a `Material` domain entity to a `MaterialDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: A `MaterialDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: Material) -> MaterialDTO {
        domain.toDTO()
    }
}
