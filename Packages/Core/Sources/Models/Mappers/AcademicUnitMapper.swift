// AcademicUnitMapper.swift
// Models
//
// Bidirectional mapper between AcademicUnitDTO and AcademicUnit domain entity.

import Foundation

/// Mapper for bidirectional conversion between `AcademicUnitDTO` and `AcademicUnit` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model.
///
/// ## Overview
/// `AcademicUnitMapper` provides type-safe conversion that:
/// - Maps `display_name` (snake_case) to `displayName` (camelCase)
/// - Maps `parent_unit_id` to `parentUnitID`
/// - Maps `school_id` to `schoolID`
/// - Converts string `type` to `AcademicUnitType` enum
/// - Handles nullable fields like `deleted_at`, `parent_unit_id`
/// - Preserves hierarchical relationships during roundtrip conversion
///
/// ## Example
/// ```swift
/// // DTO from backend
/// let dto = AcademicUnitDTO(
///     id: UUID(),
///     displayName: "10th Grade",
///     code: "G10",
///     description: "Tenth grade students",
///     type: "grade",
///     parentUnitID: nil,
///     schoolID: schoolID,
///     metadata: nil,
///     createdAt: Date(),
///     updatedAt: Date(),
///     deletedAt: nil
/// )
///
/// // Convert to domain
/// let unit = try AcademicUnitMapper.toDomain(dto)
///
/// // Convert back to DTO
/// let backToDTO = AcademicUnitMapper.toDTO(unit)
/// ```
///
/// ## Notes
/// - The extension methods on `AcademicUnitDTO` and `AcademicUnit` (`toDomain()`, `toDTO()`) are preferred
///   for direct conversion. This mapper exists for `MapperProtocol` conformance.
public struct AcademicUnitMapper: MapperProtocol {
    public typealias DTO = AcademicUnitDTO
    public typealias Domain = AcademicUnit

    /// Converts an `AcademicUnitDTO` from the backend to an `AcademicUnit` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: An `AcademicUnit` domain entity.
    /// - Throws: `DomainError.validationFailed` if displayName is empty or type is unknown.
    public static func toDomain(_ dto: AcademicUnitDTO) throws -> AcademicUnit {
        try dto.toDomain()
    }

    /// Converts an `AcademicUnit` domain entity to an `AcademicUnitDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: An `AcademicUnitDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: AcademicUnit) -> AcademicUnitDTO {
        domain.toDTO()
    }
}
