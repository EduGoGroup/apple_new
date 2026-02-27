import Foundation

// MARK: - Resource

/// Represents a system resource that can be accessed.
///
/// Resources are the targets of permissions (what can be accessed).
public enum Resource: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    /// User management resource
    case users

    /// Role management resource
    case roles

    /// Document management resource
    case documents

    /// Course management resource
    case courses

    /// Grade management resource
    case grades

    /// Settings/configuration resource
    case settings

    /// Report generation resource
    case reports
}

extension Resource: CustomStringConvertible {
    public var description: String {
        switch self {
        case .users:
            return "Users"
        case .roles:
            return "Roles"
        case .documents:
            return "Documents"
        case .courses:
            return "Courses"
        case .grades:
            return "Grades"
        case .settings:
            return "Settings"
        case .reports:
            return "Reports"
        }
    }
}

// MARK: - Action

/// Represents an action that can be performed on a resource.
///
/// Actions define what operations are allowed (CRUD operations plus extras).
public enum Action: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    /// Create new instances
    case create

    /// Read/view instances
    case read

    /// Update existing instances
    case update

    /// Delete instances
    case delete

    /// List/enumerate instances
    case list

    /// Export data
    case export

    /// Import data
    case importData = "import"

    /// Approve/publish instances
    case approve
}

extension Action: CustomStringConvertible {
    public var description: String {
        switch self {
        case .create:
            return "Create"
        case .read:
            return "Read"
        case .update:
            return "Update"
        case .delete:
            return "Delete"
        case .list:
            return "List"
        case .export:
            return "Export"
        case .importData:
            return "Import"
        case .approve:
            return "Approve"
        }
    }
}

// MARK: - Permission Entity

/// Represents a granular permission combining a resource and action.
///
/// `Permission` is an immutable, thread-safe entity conforming to `Sendable`.
/// Each permission defines what action can be performed on which resource.
///
/// ## Example
/// ```swift
/// let permission = try Permission(
///     id: UUID(),
///     code: "users.read",
///     resource: .users,
///     action: .read
/// )
/// ```
public struct Permission: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the permission
    public let id: UUID

    /// Permission code (e.g., "users.read", "documents.create")
    public let code: String

    /// The resource this permission applies to
    public let resource: Resource

    /// The action this permission allows
    public let action: Action

    // MARK: - Initialization

    /// Creates a new Permission instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - code: Permission code. Must match "resource.action" format.
    ///   - resource: The target resource.
    ///   - action: The allowed action.
    /// - Throws: `PermissionValidationError` if validation fails.
    public init(
        id: UUID = UUID(),
        code: String,
        resource: Resource,
        action: Action
    ) throws {
        guard !code.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw PermissionValidationError.emptyCode
        }

        guard Self.isValidCode(code) else {
            throw PermissionValidationError.invalidCodeFormat(code)
        }

        self.id = id
        self.code = code.lowercased()
        self.resource = resource
        self.action = action
    }

    /// Creates a Permission with auto-generated code from resource and action.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - resource: The target resource.
    ///   - action: The allowed action.
    /// - Returns: A new `Permission` instance.
    public static func create(
        id: UUID = UUID(),
        resource: Resource,
        action: Action
    ) -> Permission {
        let code = "\(resource.rawValue).\(action.rawValue)"
        // swiftlint:disable:next force_try
        return try! Permission(
            id: id,
            code: code,
            resource: resource,
            action: action
        )
    }

    // MARK: - Code Validation

    private static func isValidCode(_ code: String) -> Bool {
        let codeRegex = #"^[a-zA-Z_]+\.[a-zA-Z_]+$"#
        return code.range(of: codeRegex, options: .regularExpression) != nil
    }
}

// MARK: - Permission Validation Error

/// Errors that can occur during Permission validation.
public enum PermissionValidationError: Error, Equatable, Sendable {
    /// The code provided was empty.
    case emptyCode

    /// The code format is invalid (must be "resource.action").
    case invalidCodeFormat(String)
}

extension PermissionValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .emptyCode:
            return "Permission code cannot be empty"
        case .invalidCodeFormat(let code):
            return "Invalid permission code format: \(code). Expected format: resource.action"
        }
    }
}
