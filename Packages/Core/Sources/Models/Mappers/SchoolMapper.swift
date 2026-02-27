// SchoolMapper.swift
// Models
//
// Bidirectional mapper between SchoolDTO and School domain entity.

import Foundation

/// Mapper for bidirectional conversion between `SchoolDTO` and `School` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model.
///
/// ## Overview
/// `SchoolMapper` provides type-safe conversion that:
/// - Maps `contact_email`/`contact_phone` (snake_case) to `contactEmail`/`contactPhone` (camelCase)
/// - Maps `subscription_tier` to `subscriptionTier`
/// - Maps `max_students`/`max_teachers` to `maxStudents`/`maxTeachers`
/// - Handles nullable fields like `address`, `city`, `country`
/// - Preserves all school properties during roundtrip conversion
///
/// ## Example
/// ```swift
/// // DTO from backend
/// let dto = SchoolDTO(
///     id: UUID(),
///     name: "Springfield Elementary",
///     code: "SPR-ELEM-001",
///     isActive: true,
///     address: "123 Main St",
///     city: "Springfield",
///     country: "USA",
///     contactEmail: "contact@school.edu",
///     contactPhone: "+1-555-1234",
///     maxStudents: 500,
///     maxTeachers: 50,
///     subscriptionTier: "premium",
///     metadata: nil,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
///
/// // Convert to domain
/// let school = try SchoolMapper.toDomain(dto)
///
/// // Convert back to DTO
/// let backToDTO = SchoolMapper.toDTO(school)
/// ```
///
/// ## Notes
/// - The extension methods on `SchoolDTO` and `School` (`toDomain()`, `toDTO()`) are preferred
///   for direct conversion. This mapper exists for `MapperProtocol` conformance.
public struct SchoolMapper: MapperProtocol {
    public typealias DTO = SchoolDTO
    public typealias Domain = School

    /// Converts a `SchoolDTO` from the backend to a `School` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: A `School` domain entity.
    /// - Throws: `DomainError.validationFailed` if name or code is empty.
    public static func toDomain(_ dto: SchoolDTO) throws -> School {
        try dto.toDomain()
    }

    /// Converts a `School` domain entity to a `SchoolDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: A `SchoolDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: School) -> SchoolDTO {
        domain.toDTO()
    }
}
