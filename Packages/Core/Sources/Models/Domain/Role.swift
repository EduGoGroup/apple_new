import Foundation

// MARK: - Role Level

/// Represents the hierarchy level of a role in the system.
///
/// Levels are ordered from highest privilege (admin) to lowest (student).
/// Conforms to `Comparable` for privilege comparison.
public enum RoleLevel: Int, Sendable, Equatable, Hashable, Codable, CaseIterable {
    /// Administrator with full system access
    case admin = 3

    /// Teacher with classroom management capabilities
    case teacher = 2

    /// Student with limited access
    case student = 1
}

extension RoleLevel: Comparable {
    public static func < (lhs: RoleLevel, rhs: RoleLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

extension RoleLevel: CustomStringConvertible {
    public var description: String {
        switch self {
        case .admin:
            return "Administrator"
        case .teacher:
            return "Teacher"
        case .student:
            return "Student"
        }
    }
}

// MARK: - Role Entity

/// Represents a role that can be assigned to users.
///
/// `Role` is an immutable, thread-safe entity conforming to `Sendable`.
/// Permissions are referenced by ID (value semantics).
///
/// ## Example
/// ```swift
/// let adminRole = Role(
///     id: UUID(),
///     name: "System Admin",
///     level: .admin
/// )
///
/// // Add a permission
/// let updatedRole = adminRole.addPermission(readPermissionID)
/// ```
public struct Role: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the role
    public let id: UUID

    /// Display name of the role
    public let name: String

    /// Privilege level of the role
    public let level: RoleLevel

    /// Set of permission IDs assigned to this role
    public let permissionIDs: Set<UUID>

    // MARK: - Initialization

    /// Creates a new Role instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - name: Role display name. Must not be empty.
    ///   - level: Privilege level for the role.
    ///   - permissionIDs: Set of assigned permission IDs. Defaults to empty.
    /// - Throws: `RoleValidationError` if validation fails.
    public init(
        id: UUID = UUID(),
        name: String,
        level: RoleLevel,
        permissionIDs: Set<UUID> = []
    ) throws {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw RoleValidationError.emptyName
        }

        self.id = id
        self.name = name.trimmingCharacters(in: .whitespaces)
        self.level = level
        self.permissionIDs = permissionIDs
    }

    // MARK: - Copy Methods

    /// Creates a copy with updated name.
    ///
    /// - Parameter name: The new name.
    /// - Returns: A new `Role` instance with the updated name.
    /// - Throws: `RoleValidationError.emptyName` if name is empty.
    public func with(name: String) throws -> Role {
        try Role(
            id: id,
            name: name,
            level: level,
            permissionIDs: permissionIDs
        )
    }

    /// Creates a copy with updated level.
    ///
    /// - Parameter level: The new level.
    /// - Returns: A new `Role` instance with the updated level.
    public func with(level: RoleLevel) -> Role {
        // swiftlint:disable:next force_try
        try! Role(
            id: id,
            name: name,
            level: level,
            permissionIDs: permissionIDs
        )
    }

    // MARK: - Permission Management

    /// Creates a copy with an additional permission.
    ///
    /// - Parameter permissionID: The permission ID to add.
    /// - Returns: A new `Role` with the permission added.
    public func addPermission(_ permissionID: UUID) -> Role {
        var newPermissions = permissionIDs
        newPermissions.insert(permissionID)
        // swiftlint:disable:next force_try
        return try! Role(
            id: id,
            name: name,
            level: level,
            permissionIDs: newPermissions
        )
    }

    /// Creates a copy with a permission removed.
    ///
    /// - Parameter permissionID: The permission ID to remove.
    /// - Returns: A new `Role` without the specified permission.
    public func removePermission(_ permissionID: UUID) -> Role {
        var newPermissions = permissionIDs
        newPermissions.remove(permissionID)
        // swiftlint:disable:next force_try
        return try! Role(
            id: id,
            name: name,
            level: level,
            permissionIDs: newPermissions
        )
    }

    /// Checks if the role has a specific permission.
    ///
    /// - Parameter permissionID: The permission ID to check.
    /// - Returns: `true` if the role has the permission, `false` otherwise.
    public func hasPermission(_ permissionID: UUID) -> Bool {
        permissionIDs.contains(permissionID)
    }
}

// MARK: - Role Comparable

extension Role: Comparable {
    /// Compares roles by their level.
    public static func < (lhs: Role, rhs: Role) -> Bool {
        lhs.level < rhs.level
    }
}

// MARK: - Role Validation Error

/// Errors that can occur during Role validation.
public enum RoleValidationError: Error, Equatable, Sendable {
    /// The name provided was empty or whitespace only.
    case emptyName
}

extension RoleValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyName:
            return "Role name cannot be empty"
        }
    }
}
