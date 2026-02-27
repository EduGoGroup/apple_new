// RoleDTO.swift
// Models
//
// Data Transfer Object for Role entity from backend API.

import Foundation

/// Data Transfer Object representing a Role from the backend API.
///
/// This struct maps to the JSON structure returned by the backend,
/// using snake_case property names via `CodingKeys`.
///
/// ## JSON Structure
/// ```json
/// {
///     "id": "550e8400-e29b-41d4-a716-446655440000",
///     "name": "Teacher",
///     "level": 2,
///     "permission_ids": ["uuid1", "uuid2"]
/// }
/// ```
///
/// ## Level Values
/// - `1`: Student - Limited access
/// - `2`: Teacher - Classroom management
/// - `3`: Admin - Full system access
///
/// ## Usage
/// ```swift
/// let decoder = JSONDecoder()
/// let roleDTO = try decoder.decode(RoleDTO.self, from: jsonData)
/// let role = try RoleMapper.toDomain(roleDTO)
/// ```
public struct RoleDTO: Codable, Sendable, Equatable {
    /// Unique identifier for the role.
    public let id: UUID

    /// Role name (e.g., "Admin", "Teacher", "Student").
    public let name: String

    /// Privilege level (1=student, 2=teacher, 3=admin).
    public let level: Int

    /// Array of permission IDs assigned to this role.
    public let permissionIDs: [UUID]

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case level
        case permissionIDs = "permission_ids"
    }

    /// Creates a new RoleDTO instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the role.
    ///   - name: Role name.
    ///   - level: Privilege level (1-3).
    ///   - permissionIDs: Array of permission IDs assigned to this role.
    public init(
        id: UUID,
        name: String,
        level: Int,
        permissionIDs: [UUID]
    ) {
        self.id = id
        self.name = name
        self.level = level
        self.permissionIDs = permissionIDs
    }
}
