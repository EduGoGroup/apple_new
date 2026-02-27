// PermissionDTO.swift
// Models
//
// Data Transfer Object for Permission entity from backend API.

import Foundation

/// Data Transfer Object representing a Permission from the backend API.
///
/// This struct maps to the JSON structure returned by the backend.
/// Note that `resource` and `action` are strings from the backend,
/// not enums - validation happens during mapping to domain.
///
/// ## JSON Structure
/// ```json
/// {
///     "id": "550e8400-e29b-41d4-a716-446655440000",
///     "code": "documents.create",
///     "resource": "documents",
///     "action": "create"
/// }
/// ```
///
/// ## Valid Resources
/// users, roles, documents, courses, grades, settings, reports
///
/// ## Valid Actions
/// create, read, update, delete, list, export, import, approve
///
/// ## Usage
/// ```swift
/// let decoder = JSONDecoder()
/// let permissionDTO = try decoder.decode(PermissionDTO.self, from: jsonData)
/// let permission = try PermissionMapper.toDomain(permissionDTO)
/// ```
public struct PermissionDTO: Codable, Sendable, Equatable {
    /// Unique identifier for the permission.
    public let id: UUID

    /// Permission code in format "resource.action" (e.g., "documents.create").
    public let code: String

    /// Resource this permission applies to (e.g., "documents", "users").
    public let resource: String

    /// Action allowed on the resource (e.g., "create", "read", "delete").
    public let action: String

    /// Maps JSON keys to Swift properties.
    enum CodingKeys: String, CodingKey {
        case id
        case code
        case resource
        case action
    }

    /// Creates a new PermissionDTO instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the permission.
    ///   - code: Permission code in format "resource.action".
    ///   - resource: Resource this permission applies to.
    ///   - action: Action allowed on the resource.
    public init(
        id: UUID,
        code: String,
        resource: String,
        action: String
    ) {
        self.id = id
        self.code = code
        self.resource = resource
        self.action = action
    }
}
