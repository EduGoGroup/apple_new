import Foundation
import SwiftData

/// SwiftData model for persisting AcademicUnit entities
///
/// This model stores academic unit data in SwiftData and can be converted to/from
/// the domain `AcademicUnit` type using `AcademicUnitPersistenceMapper`.
///
/// ## Notes
/// - The `id` property has a unique constraint to ensure data integrity
/// - Supports hierarchical relationships via `parentUnit` and `childUnits`
/// - Type is stored as String to match backend API
@Model
public final class AcademicUnitModel {
    /// Unique identifier for the academic unit
    @Attribute(.unique)
    public var id: UUID

    /// Display name of the unit
    public var displayName: String

    /// Optional code identifier for the unit
    public var code: String?

    /// Description of the unit
    public var unitDescription: String?

    /// Type of academic unit (grade, section, club, department, course)
    public var type: String

    /// ID of the school this unit belongs to
    public var schoolID: UUID

    /// Metadata stored as JSON data
    public var metadataData: Data?

    /// Timestamp when the unit was created
    public var createdAt: Date

    /// Timestamp when the unit was last updated
    public var updatedAt: Date

    /// Timestamp when the unit was deleted (soft delete)
    public var deletedAt: Date?

    /// Parent unit in the hierarchy (nil if top-level)
    public var parentUnit: AcademicUnitModel?

    /// Child units in the hierarchy
    @Relationship(deleteRule: .cascade, inverse: \AcademicUnitModel.parentUnit)
    public var childUnits: [AcademicUnitModel]?

    /// School this unit belongs to
    public var school: SchoolModel?

    /// Memberships associated with this unit
    @Relationship(deleteRule: .cascade, inverse: \MembershipModel.unit)
    public var memberships: [MembershipModel]?

    /// Creates a new AcademicUnitModel instance
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - displayName: Display name of the unit
    ///   - code: Optional code identifier
    ///   - unitDescription: Description of the unit
    ///   - type: Type of academic unit
    ///   - schoolID: ID of the school
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - updatedAt: Last update timestamp (defaults to now)
    ///   - deletedAt: Deletion timestamp (soft delete)
    ///   - parentUnit: Parent unit in hierarchy
    public init(
        id: UUID = UUID(),
        displayName: String,
        code: String? = nil,
        unitDescription: String? = nil,
        type: String,
        schoolID: UUID,
        metadataData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil,
        parentUnit: AcademicUnitModel? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.code = code
        self.unitDescription = unitDescription
        self.type = type
        self.schoolID = schoolID
        self.metadataData = metadataData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
        self.parentUnit = parentUnit
    }
}
