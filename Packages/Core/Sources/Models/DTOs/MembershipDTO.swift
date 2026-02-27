// MembershipDTO.swift
// Models
//
// Data Transfer Object for Membership entity from backend API.

import Foundation
import EduFoundation

/// Data Transfer Object representing a Membership from the backend API.
///
/// This struct maps to the JSON structure returned by edu-admin API `/v1/memberships`,
/// using snake_case property names via `CodingKeys`.
///
/// ## JSON Structure (from backend)
/// ```json
/// {
///     "id": "550e8400-e29b-41d4-a716-446655440000",
///     "user_id": "660e8400-e29b-41d4-a716-446655440001",
///     "unit_id": "770e8400-e29b-41d4-a716-446655440002",
///     "role": "student",
///     "is_active": true,
///     "enrolled_at": "2024-01-15T10:30:00Z",
///     "withdrawn_at": null,
///     "created_at": "2024-01-15T10:30:00Z",
///     "updated_at": "2024-01-20T14:45:00Z"
/// }
/// ```
///
/// ## Usage
/// ```swift
/// let decoder = JSONDecoder()
/// decoder.dateDecodingStrategy = .iso8601
/// let membershipDTO = try decoder.decode(MembershipDTO.self, from: jsonData)
/// let membership = try membershipDTO.toDomain()
/// ```
public struct MembershipDTO: Codable, Sendable, Equatable {
    /// Unique identifier for the membership.
    public let id: UUID

    /// ID of the user holding this membership.
    public let userID: UUID

    /// ID of the academic unit.
    public let unitID: UUID

    /// Role of the user in this unit (owner, teacher, assistant, student, guardian).
    public let role: String

    /// Whether the membership is active.
    public let isActive: Bool

    /// Date when the user was enrolled.
    public let enrolledAt: Date

    /// Date when the user was withdrawn (null if still active).
    public let withdrawnAt: Date?

    /// Timestamp when the membership was created.
    public let createdAt: Date

    /// Timestamp when the membership was last updated.
    public let updatedAt: Date

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case unitID = "unit_id"
        case role
        case isActive = "is_active"
        case enrolledAt = "enrolled_at"
        case withdrawnAt = "withdrawn_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Creates a new MembershipDTO instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the membership.
    ///   - userID: ID of the user holding this membership.
    ///   - unitID: ID of the academic unit.
    ///   - role: Role of the user in this unit.
    ///   - isActive: Whether the membership is active.
    ///   - enrolledAt: Enrollment date.
    ///   - withdrawnAt: Withdrawal date (nil if still active).
    ///   - createdAt: Creation timestamp.
    ///   - updatedAt: Last update timestamp.
    public init(
        id: UUID,
        userID: UUID,
        unitID: UUID,
        role: String,
        isActive: Bool,
        enrolledAt: Date,
        withdrawnAt: Date?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userID = userID
        self.unitID = unitID
        self.role = role
        self.isActive = isActive
        self.enrolledAt = enrolledAt
        self.withdrawnAt = withdrawnAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Domain Conversion

extension MembershipDTO {
    /// Converts this DTO to a domain `Membership` entity.
    ///
    /// - Returns: A `Membership` domain entity.
    /// - Throws: `DomainError.validationFailed` if role is unknown.
    public func toDomain() throws -> Membership {
        guard let membershipRole = MembershipRole(rawValue: role) else {
            throw DomainError.validationFailed(
                field: "role",
                reason: "Rol desconocido: '\(role)'"
            )
        }

        return Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: membershipRole,
            isActive: isActive,
            enrolledAt: enrolledAt,
            withdrawnAt: withdrawnAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Membership Extension

extension Membership {
    /// Converts this domain entity to a `MembershipDTO` for API communication.
    ///
    /// - Returns: A `MembershipDTO` suitable for sending to the backend.
    public func toDTO() -> MembershipDTO {
        MembershipDTO(
            id: id,
            userID: userID,
            unitID: unitID,
            role: role.rawValue,
            isActive: isActive,
            enrolledAt: enrolledAt,
            withdrawnAt: withdrawnAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
