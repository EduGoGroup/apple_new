import Foundation
import EduCore
import EduFoundation

/// Mapper for converting between MembershipModel (SwiftData) and Membership (domain)
///
/// This struct provides static methods for bidirectional conversion between
/// the persistence model and the domain entity.
///
/// ## Usage
///
/// ```swift
/// // Convert from persistence to domain
/// let membership = try MembershipPersistenceMapper.toDomain(membershipModel)
///
/// // Convert from domain to persistence (new model)
/// let model = MembershipPersistenceMapper.toModel(membership, existing: nil)
///
/// // Update existing model from domain
/// let updatedModel = MembershipPersistenceMapper.toModel(membership, existing: existingModel)
/// ```
///
/// ## Notes
/// - Does NOT conform to `MapperProtocol` because `@Model` types are not `Codable`
/// - Throws `DomainError.validationFailed` for unknown role strings
public struct MembershipPersistenceMapper: Sendable {
    private init() {}

    /// Converts a MembershipModel to a domain Membership
    ///
    /// - Parameter model: The SwiftData model to convert
    /// - Returns: A domain Membership entity
    /// - Throws: `DomainError.validationFailed` if role is unknown
    public static func toDomain(_ model: MembershipModel) throws -> Membership {
        guard let role = MembershipRole(rawValue: model.role) else {
            throw DomainError.validationFailed(
                field: "role",
                reason: "Rol desconocido: '\(model.role)'"
            )
        }

        return Membership(
            id: model.id,
            userID: model.userID,
            unitID: model.unitID,
            role: role,
            isActive: model.isActive,
            enrolledAt: model.enrolledAt,
            withdrawnAt: model.withdrawnAt,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }

    /// Converts a domain Membership to a MembershipModel
    ///
    /// If an existing model is provided, updates its properties instead of
    /// creating a new instance. This is useful for SwiftData's change tracking.
    ///
    /// - Parameters:
    ///   - domain: The domain Membership to convert
    ///   - existing: An optional existing MembershipModel to update
    /// - Returns: A MembershipModel with the domain entity's data
    public static func toModel(_ domain: Membership, existing: MembershipModel?) -> MembershipModel {
        if let existing = existing {
            // Update existing model in place for SwiftData change tracking
            existing.userID = domain.userID
            existing.unitID = domain.unitID
            existing.role = domain.role.rawValue
            existing.isActive = domain.isActive
            existing.enrolledAt = domain.enrolledAt
            existing.withdrawnAt = domain.withdrawnAt
            existing.updatedAt = domain.updatedAt
            return existing
        } else {
            // Create new model
            return MembershipModel(
                id: domain.id,
                userID: domain.userID,
                unitID: domain.unitID,
                role: domain.role.rawValue,
                isActive: domain.isActive,
                enrolledAt: domain.enrolledAt,
                withdrawnAt: domain.withdrawnAt,
                createdAt: domain.createdAt,
                updatedAt: domain.updatedAt
            )
        }
    }
}
