// RoleMapper.swift
// Models
//
// Bidirectional mapper between RoleDTO and Role domain entity.

import Foundation
import EduFoundation

/// Mapper for bidirectional conversion between `RoleDTO` and `Role` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model, including validation of role levels.
///
/// ## Overview
/// `RoleMapper` provides type-safe conversion that:
/// - Validates role level before constructing the domain entity
/// - Converts `Array` to `Set` for permission IDs
/// - Converts `Int` to `RoleLevel` enum
/// - Delegates name validation to `Role.init`
///
/// ## Example
/// ```swift
/// // DTO from backend
/// let dto = RoleDTO(
///     id: UUID(),
///     name: "Teacher",
///     level: 2,
///     permissionIDs: [permID1, permID2]
/// )
///
/// // Convert to domain
/// let role = try RoleMapper.toDomain(dto)
/// print(role.level) // .teacher
///
/// // Convert back to DTO
/// let backToDTO = RoleMapper.toDTO(role)
/// print(backToDTO.level) // 2
/// ```
///
/// ## Error Handling
/// The `toDomain` method can throw:
/// - `DomainError.validationFailed(field: "level", ...)` if level is not 1, 2, or 3
/// - `RoleValidationError.emptyName` if name is empty (from `Role.init`)
public struct RoleMapper: MapperProtocol {
    public typealias DTO = RoleDTO
    public typealias Domain = Role

    /// Converts a `RoleDTO` from the backend to a `Role` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: A validated `Role` domain entity.
    /// - Throws: `DomainError.validationFailed` if level is invalid (not 1, 2, or 3).
    /// - Throws: `RoleValidationError.emptyName` if name is empty.
    public static func toDomain(_ dto: RoleDTO) throws -> Role {
        // Validate level before constructing Role
        // RoleLevel only accepts: 1 (student), 2 (teacher), 3 (admin)
        guard let level = RoleLevel(rawValue: dto.level) else {
            throw DomainError.validationFailed(
                field: "level",
                reason: "Nivel de rol inválido: \(dto.level). Valores válidos: 1 (student), 2 (teacher), 3 (admin)"
            )
        }

        // Role.init validates that name is not empty
        // Throws RoleValidationError.emptyName if validation fails
        return try Role(
            id: dto.id,
            name: dto.name,
            level: level,
            permissionIDs: Set(dto.permissionIDs)
        )
    }

    /// Converts a `Role` domain entity to a `RoleDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: A `RoleDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: Role) -> RoleDTO {
        RoleDTO(
            id: domain.id,
            name: domain.name,
            level: domain.level.rawValue,
            permissionIDs: Array(domain.permissionIDs)
        )
    }
}
