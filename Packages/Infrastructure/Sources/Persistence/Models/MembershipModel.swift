import Foundation
import SwiftData

/// SwiftData model for persisting Membership entities
///
/// This model stores membership data in SwiftData and can be converted to/from
/// the domain `Membership` type using `MembershipPersistenceMapper`.
///
/// ## Notes
/// - The `id` property has a unique constraint to ensure data integrity
/// - Links users to academic units with contextual roles
/// - Role is stored as String to match backend API
@Model
public final class MembershipModel {
    /// Unique identifier for the membership
    @Attribute(.unique)
    public var id: UUID

    /// ID of the user who holds this membership
    public var userID: UUID

    /// ID of the academic unit this membership belongs to
    public var unitID: UUID

    /// Role of the user within this unit (owner, teacher, assistant, student, guardian)
    public var role: String

    /// Whether this membership is currently active
    public var isActive: Bool

    /// Date when the user was enrolled in this unit
    public var enrolledAt: Date

    /// Date when the user was withdrawn (nil if still active)
    public var withdrawnAt: Date?

    /// Timestamp when the membership was created
    public var createdAt: Date

    /// Timestamp when the membership was last updated
    public var updatedAt: Date

    /// User associated with this membership
    public var user: UserModel?

    /// Academic unit associated with this membership
    public var unit: AcademicUnitModel?

    /// Creates a new MembershipModel instance
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - userID: ID of the user
    ///   - unitID: ID of the academic unit
    ///   - role: Role within the unit
    ///   - isActive: Whether the membership is active (defaults to true)
    ///   - enrolledAt: Enrollment date (defaults to now)
    ///   - withdrawnAt: Withdrawal date
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - updatedAt: Last update timestamp (defaults to now)
    public init(
        id: UUID = UUID(),
        userID: UUID,
        unitID: UUID,
        role: String,
        isActive: Bool = true,
        enrolledAt: Date = Date(),
        withdrawnAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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
