import Foundation
import SwiftData

/// SwiftData model for persisting User entities
///
/// This model stores user data in SwiftData and can be converted to/from
/// the domain `User` type using `UserPersistenceMapper`.
///
/// ## Notes
/// - User roles are managed via `MembershipModel`, not stored in User
/// - The `id` property has a unique constraint to ensure data integrity
/// - Aligns with backend API using `firstName`/`lastName` fields
@Model
public final class UserModel {
    /// Unique identifier for the user
    @Attribute(.unique)
    public var id: UUID

    /// User's first name
    public var firstName: String

    /// User's last name
    public var lastName: String

    /// User's email address (normalized to lowercase)
    public var email: String

    /// Whether the user account is active
    public var isActive: Bool

    /// Timestamp when the user was created
    public var createdAt: Date

    /// Timestamp when the user was last updated
    public var updatedAt: Date

    /// Creates a new UserModel instance
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - firstName: User's first name
    ///   - lastName: User's last name
    ///   - email: User's email address
    ///   - isActive: Whether the account is active (defaults to true)
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - updatedAt: Last update timestamp (defaults to now)
    public init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
