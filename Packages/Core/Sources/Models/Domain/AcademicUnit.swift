import Foundation
import EduFoundation

// MARK: - AcademicUnitType

/// Represents the type of an academic unit.
///
/// Academic units can be organized hierarchically (e.g., grade -> section).
public enum AcademicUnitType: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    /// A grade level (e.g., "1st Grade", "12th Grade")
    case grade = "grade"

    /// A section within a grade (e.g., "Section A", "Section B")
    case section = "section"

    /// A club or extracurricular group
    case club = "club"

    /// An administrative department
    case department = "department"

    /// A course or subject class
    case course = "course"
}

extension AcademicUnitType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .grade:
            return "Grade"
        case .section:
            return "Section"
        case .club:
            return "Club"
        case .department:
            return "Department"
        case .course:
            return "Course"
        }
    }
}

// MARK: - AcademicUnit Entity

/// Represents an academic unit within a school.
///
/// `AcademicUnit` is a hierarchical organizational entity that can represent
/// grades, sections, clubs, departments, or courses. Units can have parent-child
/// relationships to form a tree structure.
///
/// ## Backend Alignment
/// This model aligns with edu-admin API `/v1/schools/{schoolId}/units`:
/// - Uses `displayName` (maps to `display_name` in JSON)
/// - Uses `parentUnitID` (maps to `parent_unit_id` in JSON)
/// - Uses `schoolID` (maps to `school_id` in JSON)
///
/// ## Hierarchical Structure
/// Units can be nested:
/// - School -> Grade -> Section
/// - School -> Department -> Course
/// - School -> Club
///
/// ## Example
/// ```swift
/// let grade = try AcademicUnit(
///     displayName: "10th Grade",
///     type: .grade,
///     schoolID: schoolID
/// )
///
/// let section = try AcademicUnit(
///     displayName: "Section A",
///     type: .section,
///     schoolID: schoolID,
///     parentUnitID: grade.id
/// )
/// ```
public struct AcademicUnit: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the academic unit
    public let id: UUID

    /// Display name of the unit
    public let displayName: String

    /// Optional code identifier for the unit
    public let code: String?

    /// Description of the unit
    public let description: String?

    /// Type of academic unit
    public let type: AcademicUnitType

    /// ID of the parent unit (nil if top-level)
    public let parentUnitID: UUID?

    /// ID of the school this unit belongs to
    public let schoolID: UUID

    /// Additional metadata as key-value pairs
    public let metadata: [String: JSONValue]?

    /// Timestamp when the unit was created
    public let createdAt: Date

    /// Timestamp when the unit was last updated
    public let updatedAt: Date

    /// Timestamp when the unit was deleted (soft delete)
    public let deletedAt: Date?

    // MARK: - Computed Properties

    /// Whether this is a top-level unit (no parent)
    public var isTopLevel: Bool {
        parentUnitID == nil
    }

    /// Whether the unit has been deleted
    public var isDeleted: Bool {
        deletedAt != nil
    }

    // MARK: - Initialization

    /// Creates a new AcademicUnit instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - displayName: Display name of the unit. Must not be empty.
    ///   - code: Optional code identifier.
    ///   - description: Description of the unit.
    ///   - type: Type of academic unit.
    ///   - parentUnitID: ID of the parent unit (nil if top-level).
    ///   - schoolID: ID of the school.
    ///   - metadata: Additional metadata.
    ///   - createdAt: Creation timestamp. Defaults to now.
    ///   - updatedAt: Last update timestamp. Defaults to now.
    ///   - deletedAt: Deletion timestamp (soft delete).
    /// - Throws: `DomainError.validationFailed` if displayName is empty.
    public init(
        id: UUID = UUID(),
        displayName: String,
        code: String? = nil,
        description: String? = nil,
        type: AcademicUnitType,
        parentUnitID: UUID? = nil,
        schoolID: UUID,
        metadata: [String: JSONValue]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) throws {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw DomainError.validationFailed(field: "displayName", reason: "Display name cannot be empty")
        }

        self.id = id
        self.displayName = trimmedName
        self.code = code?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.type = type
        self.parentUnitID = parentUnitID
        self.schoolID = schoolID
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    // MARK: - Copy Methods

    /// Creates a copy with updated display name.
    ///
    /// - Parameter displayName: The new display name.
    /// - Returns: A new `AcademicUnit` instance with the updated name.
    /// - Throws: `DomainError.validationFailed` if name is empty.
    public func with(displayName: String) throws -> AcademicUnit {
        try AcademicUnit(
            id: id,
            displayName: displayName,
            code: code,
            description: description,
            type: type,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: deletedAt
        )
    }

    /// Creates a copy with updated type.
    ///
    /// - Parameter type: The new type.
    /// - Returns: A new `AcademicUnit` instance with the updated type.
    public func with(type: AcademicUnitType) -> AcademicUnit {
        // swiftlint:disable:next force_try
        try! AcademicUnit(
            id: id,
            displayName: displayName,
            code: code,
            description: description,
            type: type,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: deletedAt
        )
    }

    /// Creates a copy with updated parent unit.
    ///
    /// - Parameter parentUnitID: The new parent unit ID (nil to make top-level).
    /// - Returns: A new `AcademicUnit` instance with the updated parent.
    public func with(parentUnitID: UUID?) -> AcademicUnit {
        // swiftlint:disable:next force_try
        try! AcademicUnit(
            id: id,
            displayName: displayName,
            code: code,
            description: description,
            type: type,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: deletedAt
        )
    }

    /// Creates a copy with updated description.
    ///
    /// - Parameter description: The new description.
    /// - Returns: A new `AcademicUnit` instance with the updated description.
    public func with(description: String?) -> AcademicUnit {
        // swiftlint:disable:next force_try
        try! AcademicUnit(
            id: id,
            displayName: displayName,
            code: code,
            description: description,
            type: type,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: deletedAt
        )
    }

    /// Creates a copy marking the unit as deleted.
    ///
    /// - Parameter date: The deletion date. Defaults to now.
    /// - Returns: A new `AcademicUnit` instance marked as deleted.
    public func delete(at date: Date = Date()) -> AcademicUnit {
        // swiftlint:disable:next force_try
        try! AcademicUnit(
            id: id,
            displayName: displayName,
            code: code,
            description: description,
            type: type,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: date
        )
    }
}
