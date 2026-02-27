// MembershipMapper.swift
// Models
//
// Bidirectional mapper between MembershipDTO and Membership domain entity.

import Foundation

/// Mapper for bidirectional conversion between `MembershipDTO` and `Membership` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model.
///
/// ## Overview
/// `MembershipMapper` provides type-safe conversion that:
/// - Maps `user_id`/`unit_id` (snake_case) to `userID`/`unitID` (camelCase)
/// - Converts string `role` to `MembershipRole` enum
/// - Handles nullable `withdrawn_at` timestamps
/// - Preserves all membership properties during roundtrip conversion
///
/// ## Example
/// ```swift
/// // DTO from backend
/// let dto = MembershipDTO(
///     id: UUID(),
///     userID: userID,
///     unitID: classID,
///     role: "teacher",
///     isActive: true,
///     enrolledAt: Date(),
///     withdrawnAt: nil,
///     createdAt: Date(),
///     updatedAt: Date()
/// )
///
/// // Convert to domain
/// let membership = MembershipMapper.toDomain(dto)
///
/// // Convert back to DTO
/// let backToDTO = MembershipMapper.toDTO(membership)
/// ```
///
/// ## Notes
/// - The extension methods on `MembershipDTO` and `Membership` (`toDomain()`, `toDTO()`) are preferred
///   for direct conversion. This mapper exists for `MapperProtocol` conformance.
public struct MembershipMapper: MapperProtocol {
    public typealias DTO = MembershipDTO
    public typealias Domain = Membership

    /// Converts a `MembershipDTO` from the backend to a `Membership` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: A `Membership` domain entity.
    /// - Throws: `DomainError.validationFailed` if role is unknown.
    public static func toDomain(_ dto: MembershipDTO) throws -> Membership {
        try dto.toDomain()
    }

    /// Converts a `Membership` domain entity to a `MembershipDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: A `MembershipDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: Membership) -> MembershipDTO {
        domain.toDTO()
    }
}
