import Foundation
import SwiftData

/// SwiftData model for persisting School entities
///
/// This model stores school data in SwiftData and can be converted to/from
/// the domain `School` type using `SchoolPersistenceMapper`.
///
/// ## Notes
/// - The `id` property has a unique constraint to ensure data integrity
/// - Metadata is stored as optional JSON-encoded dictionary
@Model
public final class SchoolModel {
    /// Unique identifier for the school
    @Attribute(.unique)
    public var id: UUID

    /// Name of the school
    public var name: String

    /// Unique code identifier for the school
    public var code: String

    /// Whether the school is currently active
    public var isActive: Bool

    /// Physical address of the school
    public var address: String?

    /// City where the school is located
    public var city: String?

    /// Country where the school is located
    public var country: String?

    /// Contact email for the school
    public var contactEmail: String?

    /// Contact phone number for the school
    public var contactPhone: String?

    /// Maximum number of students allowed
    public var maxStudents: Int?

    /// Maximum number of teachers allowed
    public var maxTeachers: Int?

    /// Subscription tier (e.g., "free", "basic", "premium")
    public var subscriptionTier: String?

    /// Metadata stored as JSON data
    public var metadataData: Data?

    /// Timestamp when the school was created
    public var createdAt: Date

    /// Timestamp when the school was last updated
    public var updatedAt: Date

    /// Academic units belonging to this school
    @Relationship(deleteRule: .cascade, inverse: \AcademicUnitModel.school)
    public var academicUnits: [AcademicUnitModel]?

    /// Creates a new SchoolModel instance
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: Name of the school
    ///   - code: Unique code identifier
    ///   - isActive: Whether the school is active (defaults to true)
    ///   - address: Physical address
    ///   - city: City location
    ///   - country: Country location
    ///   - contactEmail: Contact email
    ///   - contactPhone: Contact phone
    ///   - maxStudents: Maximum students allowed
    ///   - maxTeachers: Maximum teachers allowed
    ///   - subscriptionTier: Subscription tier
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - updatedAt: Last update timestamp (defaults to now)
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
        metadataData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.code = code
        self.isActive = isActive
        self.address = address
        self.city = city
        self.country = country
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.maxStudents = maxStudents
        self.maxTeachers = maxTeachers
        self.subscriptionTier = subscriptionTier
        self.metadataData = metadataData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
