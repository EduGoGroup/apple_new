import Foundation
import EduFoundation

// MARK: - School Entity

/// Represents an educational institution (school) in the system.
///
/// `School` is the top-level organizational entity that contains academic units,
/// users, and materials. Each school has its own configuration, subscription tier,
/// and capacity limits.
///
/// ## Backend Alignment
/// This model aligns with edu-admin API `/v1/schools`:
/// - Uses `contactEmail` (maps to `contact_email` in JSON)
/// - Uses `subscriptionTier` (maps to `subscription_tier` in JSON)
/// - Uses `maxStudents`/`maxTeachers` for capacity limits
///
/// ## Example
/// ```swift
/// let school = try School(
///     name: "Springfield Elementary",
///     code: "SPR-ELEM-001"
/// )
/// ```
public struct School: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the school
    public let id: UUID

    /// Name of the school
    public let name: String

    /// Unique code identifier for the school
    public let code: String

    /// Whether the school is currently active
    public let isActive: Bool

    /// Physical address of the school
    public let address: String?

    /// City where the school is located
    public let city: String?

    /// Country where the school is located
    public let country: String?

    /// Contact email for the school
    public let contactEmail: String?

    /// Contact phone number for the school
    public let contactPhone: String?

    /// Maximum number of students allowed
    public let maxStudents: Int?

    /// Maximum number of teachers allowed
    public let maxTeachers: Int?

    /// Subscription tier (e.g., "free", "basic", "premium")
    public let subscriptionTier: String?

    /// Additional metadata as key-value pairs
    public let metadata: [String: JSONValue]?

    /// Timestamp when the school was created
    public let createdAt: Date

    /// Timestamp when the school was last updated
    public let updatedAt: Date

    // MARK: - Initialization

    /// Creates a new School instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - name: Name of the school. Must not be empty.
    ///   - code: Unique code identifier. Must not be empty.
    ///   - isActive: Whether the school is active. Defaults to true.
    ///   - address: Physical address.
    ///   - city: City location.
    ///   - country: Country location.
    ///   - contactEmail: Contact email.
    ///   - contactPhone: Contact phone.
    ///   - maxStudents: Maximum students allowed.
    ///   - maxTeachers: Maximum teachers allowed.
    ///   - subscriptionTier: Subscription tier.
    ///   - metadata: Additional metadata.
    ///   - createdAt: Creation timestamp. Defaults to now.
    ///   - updatedAt: Last update timestamp. Defaults to now.
    /// - Throws: `DomainError.validationFailed` if name or code is empty.
    public init(
        id: UUID = UUID(),
        name: String,
        code: String,
        isActive: Bool = true,
        address: String? = nil,
        city: String? = nil,
        country: String? = nil,
        contactEmail: String? = nil,
        contactPhone: String? = nil,
        maxStudents: Int? = nil,
        maxTeachers: Int? = nil,
        subscriptionTier: String? = nil,
        metadata: [String: JSONValue]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw DomainError.validationFailed(field: "name", reason: "Name cannot be empty")
        }

        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty else {
            throw DomainError.validationFailed(field: "code", reason: "Code cannot be empty")
        }

        self.id = id
        self.name = trimmedName
        self.code = trimmedCode
        self.isActive = isActive
        self.address = address?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.city = city?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.country = country?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.contactEmail = contactEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.contactPhone = contactPhone?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.maxStudents = maxStudents
        self.maxTeachers = maxTeachers
        self.subscriptionTier = subscriptionTier
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Copy Methods

    /// Creates a copy with updated name.
    ///
    /// - Parameter name: The new name.
    /// - Returns: A new `School` instance with the updated name.
    /// - Throws: `DomainError.validationFailed` if name is empty.
    public func with(name: String) throws -> School {
        try School(
            id: id,
            name: name,
            code: code,
            isActive: isActive,
            address: address,
            city: city,
            country: country,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            maxStudents: maxStudents,
            maxTeachers: maxTeachers,
            subscriptionTier: subscriptionTier,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy with updated active status.
    ///
    /// - Parameter isActive: The new active status.
    /// - Returns: A new `School` instance with the updated status.
    public func with(isActive: Bool) -> School {
        // swiftlint:disable:next force_try
        try! School(
            id: id,
            name: name,
            code: code,
            isActive: isActive,
            address: address,
            city: city,
            country: country,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            maxStudents: maxStudents,
            maxTeachers: maxTeachers,
            subscriptionTier: subscriptionTier,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy with updated contact information.
    ///
    /// - Parameters:
    ///   - email: The new contact email.
    ///   - phone: The new contact phone.
    /// - Returns: A new `School` instance with the updated contact info.
    public func with(contactEmail email: String?, contactPhone phone: String?) -> School {
        // swiftlint:disable:next force_try
        try! School(
            id: id,
            name: name,
            code: code,
            isActive: isActive,
            address: address,
            city: city,
            country: country,
            contactEmail: email,
            contactPhone: phone,
            maxStudents: maxStudents,
            maxTeachers: maxTeachers,
            subscriptionTier: subscriptionTier,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }

    /// Creates a copy with updated subscription tier.
    ///
    /// - Parameter tier: The new subscription tier.
    /// - Returns: A new `School` instance with the updated tier.
    public func with(subscriptionTier tier: String?) -> School {
        // swiftlint:disable:next force_try
        try! School(
            id: id,
            name: name,
            code: code,
            isActive: isActive,
            address: address,
            city: city,
            country: country,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            maxStudents: maxStudents,
            maxTeachers: maxTeachers,
            subscriptionTier: tier,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date()
        )
    }
}
