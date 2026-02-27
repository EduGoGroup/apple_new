import Foundation
import EduFoundation

// MARK: - User Entity

/// Represents a user in the EduGo system.
///
/// `User` is an immutable, thread-safe entity conforming to `Sendable`.
/// User roles are managed through `Membership` entities (contextual per academic unit),
/// not stored directly in User.
///
/// ## Backend Alignment
/// This model aligns with edu-admin and edu-mobile APIs:
/// - Uses `firstName`/`lastName` (maps to `first_name`/`last_name` in JSON)
/// - Includes `createdAt`/`updatedAt` timestamps
/// - Roles are NOT stored here - use `Membership` for role assignments
///
/// ## Example
/// ```swift
/// let user = try User(
///     id: UUID(),
///     firstName: "John",
///     lastName: "Doe",
///     email: "john@edugo.com",
///     isActive: true
/// )
///
/// print(user.fullName) // "John Doe"
/// ```
public struct User: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the user
    public let id: UUID

    /// User's first name
    public let firstName: String

    /// User's last name
    public let lastName: String

    /// User's email address (validated format)
    public let email: String

    /// Whether the user account is active
    public let isActive: Bool

    /// Timestamp when the user was created
    public let createdAt: Date

    /// Timestamp when the user was last updated
    public let updatedAt: Date

    // MARK: - Computed Properties

    /// Full name combining firstName and lastName
    public var fullName: String {
        "\(firstName) \(lastName)"
    }

    // MARK: - Initialization

    /// Creates a new User instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - firstName: User's first name. Must not be empty.
    ///   - lastName: User's last name. Must not be empty.
    ///   - email: User's email address. Must be valid format.
    ///   - isActive: Whether the account is active. Defaults to true.
    ///   - createdAt: Creation timestamp. Defaults to now.
    ///   - updatedAt: Last update timestamp. Defaults to now.
    /// - Throws: `DomainError.validationFailed` if validation fails.
    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws {
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        guard !trimmedFirstName.isEmpty else {
            throw DomainError.validationFailed(
                field: "firstName",
                reason: "El nombre no puede estar vacío"
            )
        }

        let trimmedLastName = lastName.trimmingCharacters(in: .whitespaces)
        guard !trimmedLastName.isEmpty else {
            throw DomainError.validationFailed(
                field: "lastName",
                reason: "El apellido no puede estar vacío"
            )
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespaces)
        try EmailValidator.validate(normalizedEmail)

        self.id = id
        self.firstName = trimmedFirstName
        self.lastName = trimmedLastName
        self.email = normalizedEmail.lowercased()
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Copy Methods

    /// Creates a copy with updated first name.
    ///
    /// - Parameter firstName: The new first name.
    /// - Returns: A new `User` instance with the updated first name.
    /// - Throws: `DomainError.validationFailed` if first name is empty.
    public func with(firstName: String) throws -> User {
        try User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy with updated last name.
    ///
    /// - Parameter lastName: The new last name.
    /// - Returns: A new `User` instance with the updated last name.
    /// - Throws: `DomainError.validationFailed` if last name is empty.
    public func with(lastName: String) throws -> User {
        try User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy with updated email.
    ///
    /// - Parameter email: The new email address.
    /// - Returns: A new `User` instance with the updated email.
    /// - Throws: `DomainError.validationFailed` if format is invalid.
    public func with(email: String) throws -> User {
        try User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy with updated active status.
    ///
    /// - Parameter isActive: The new active status.
    /// - Returns: A new `User` instance with the updated status.
    public func with(isActive: Bool) -> User {
        // Safe to force-try since we're reusing validated values
        // swiftlint:disable:next force_try
        try! User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
