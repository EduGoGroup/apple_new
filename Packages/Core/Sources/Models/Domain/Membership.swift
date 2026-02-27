import Foundation
import EduFoundation

// MARK: - MembershipRole

/// Represents the role a user has within an academic unit.
///
/// Roles are contextual to each unit - a user can have different roles
/// in different academic units (e.g., teacher in one class, guardian in another).
public enum MembershipRole: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    /// Owner of the unit (e.g., school administrator)
    case owner = "owner"

    /// Teacher with instructional responsibilities
    case teacher = "teacher"

    /// Teaching assistant
    case assistant = "assistant"

    /// Student enrolled in the unit
    case student = "student"

    /// Guardian/parent of a student
    case guardian = "guardian"
}

extension MembershipRole: CustomStringConvertible {
    public var description: String {
        switch self {
        case .owner:
            return "Owner"
        case .teacher:
            return "Teacher"
        case .assistant:
            return "Assistant"
        case .student:
            return "Student"
        case .guardian:
            return "Guardian"
        }
    }
}

// MARK: - Membership Entity

/// Represents a user's membership in an academic unit with a specific role.
///
/// `Membership` is the core entity that connects users to academic units (classes,
/// grades, sections, etc.) with contextual roles. This replaces the global `roleIDs`
/// approach, allowing users to have different roles in different contexts.
///
/// ## Backend Alignment
/// This model aligns with edu-admin API `/v1/memberships`:
/// - Uses `unitID` (maps to `unit_id` in JSON)
/// - Uses `enrolledAt`/`withdrawnAt` for enrollment tracking
/// - Roles are contextual per academic unit
///
/// ## Example
/// ```swift
/// let membership = try Membership(
///     userID: studentUserID,
///     unitID: mathClassID,
///     role: .student
/// )
///
/// // Check if membership is currently active
/// if membership.isCurrentlyActive {
///     print("Student is enrolled")
/// }
/// ```
public struct Membership: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the membership
    public let id: UUID

    /// ID of the user who holds this membership
    public let userID: UUID

    /// ID of the academic unit this membership belongs to
    public let unitID: UUID

    /// Role of the user within this unit
    public let role: MembershipRole

    /// Whether this membership is currently active
    public let isActive: Bool

    /// Date when the user was enrolled in this unit
    public let enrolledAt: Date

    /// Date when the user was withdrawn (nil if still active)
    public let withdrawnAt: Date?

    /// Timestamp when the membership was created
    public let createdAt: Date

    /// Timestamp when the membership was last updated
    public let updatedAt: Date

    // MARK: - Computed Properties

    /// Whether the membership is currently active based on isActive flag and withdrawnAt
    public var isCurrentlyActive: Bool {
        isActive && withdrawnAt == nil
    }

    // MARK: - Initialization

    /// Creates a new Membership instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - userID: ID of the user holding this membership.
    ///   - unitID: ID of the academic unit.
    ///   - role: Role of the user in this unit.
    ///   - isActive: Whether the membership is active. Defaults to true.
    ///   - enrolledAt: Enrollment date. Defaults to now.
    ///   - withdrawnAt: Withdrawal date. Defaults to nil.
    ///   - createdAt: Creation timestamp. Defaults to now.
    ///   - updatedAt: Last update timestamp. Defaults to now.
    public init(
        id: UUID = UUID(),
        userID: UUID,
        unitID: UUID,
        role: MembershipRole,
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

    // MARK: - Copy Methods

    /// Creates a copy with updated role.
    ///
    /// - Parameter role: The new role.
    /// - Returns: A new `Membership` instance with the updated role.
    public func with(role: MembershipRole) -> Membership {
        Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: role,
            isActive: isActive,
            enrolledAt: enrolledAt,
            withdrawnAt: withdrawnAt,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy with updated active status.
    ///
    /// - Parameter isActive: The new active status.
    /// - Returns: A new `Membership` instance with the updated status.
    public func with(isActive: Bool) -> Membership {
        Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: role,
            isActive: isActive,
            enrolledAt: enrolledAt,
            withdrawnAt: withdrawnAt,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy marking the membership as withdrawn.
    ///
    /// - Parameter date: The withdrawal date. Defaults to now.
    /// - Returns: A new `Membership` instance marked as withdrawn.
    public func withdraw(at date: Date = Date()) -> Membership {
        Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: role,
            isActive: false,
            enrolledAt: enrolledAt,
            withdrawnAt: date,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy reactivating the membership.
    ///
    /// - Returns: A new `Membership` instance that is active again.
    public func reactivate() -> Membership {
        Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: role,
            isActive: true,
            enrolledAt: enrolledAt,
            withdrawnAt: nil,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
