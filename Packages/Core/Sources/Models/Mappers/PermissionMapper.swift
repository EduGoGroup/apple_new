// PermissionMapper.swift
// Models
//
// Bidirectional mapper between PermissionDTO and Permission domain entity.

import Foundation
import EduFoundation

/// Mapper for bidirectional conversion between `PermissionDTO` and `Permission` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model, including validation of resource and action values.
///
/// ## Overview
/// `PermissionMapper` provides type-safe conversion that:
/// - Validates resource string against known `Resource` enum values
/// - Validates action string against known `Action` enum values
/// - Uses `Permission.create()` factory which auto-generates the code
/// - Preserves all permission properties during roundtrip conversion
///
/// ## Example
/// ```swift
/// // DTO from backend
/// let dto = PermissionDTO(
///     id: UUID(),
///     code: "documents.create",
///     resource: "documents",
///     action: "create"
/// )
///
/// // Convert to domain
/// let permission = try PermissionMapper.toDomain(dto)
/// print(permission.resource) // .documents
/// print(permission.action) // .create
/// print(permission.code) // "documents.create"
///
/// // Convert back to DTO
/// let backToDTO = PermissionMapper.toDTO(permission)
/// ```
///
/// ## Error Handling
/// The `toDomain` method can throw:
/// - `DomainError.validationFailed(field: "resource", ...)` if resource is unknown
/// - `DomainError.validationFailed(field: "action", ...)` if action is unknown
///
/// ## Note on Code Generation
/// The `code` property in the DTO is ignored during `toDomain` conversion.
/// `Permission.create()` auto-generates the code as `"resource.action"`.
public struct PermissionMapper: MapperProtocol {
    public typealias DTO = PermissionDTO
    public typealias Domain = Permission

    /// Converts a `PermissionDTO` from the backend to a `Permission` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: A validated `Permission` domain entity.
    /// - Throws: `DomainError.validationFailed` if resource or action are unknown values.
    /// - Note: Uses `Permission.create()` which auto-generates the code as "resource.action".
    public static func toDomain(_ dto: PermissionDTO) throws -> Permission {
        // Validate resource before constructing Permission
        guard let resource = Resource(rawValue: dto.resource) else {
            throw DomainError.validationFailed(
                field: "resource",
                reason: "Recurso desconocido: '\(dto.resource)'. Valores válidos: \(Resource.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }

        // Validate action before constructing Permission
        guard let action = Action(rawValue: dto.action) else {
            throw DomainError.validationFailed(
                field: "action",
                reason: "Acción desconocida: '\(dto.action)'. Valores válidos: \(Action.allCases.map(\.rawValue).joined(separator: ", "))"
            )
        }

        // Use factory method that auto-generates code as "resource.action"
        return Permission.create(id: dto.id, resource: resource, action: action)
    }

    /// Converts a `Permission` domain entity to a `PermissionDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: A `PermissionDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: Permission) -> PermissionDTO {
        PermissionDTO(
            id: domain.id,
            code: domain.code,
            resource: domain.resource.rawValue,
            action: domain.action.rawValue
        )
    }
}
