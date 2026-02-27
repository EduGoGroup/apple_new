import Foundation
import SwiftData

/// SwiftData model for persisting Material entities
///
/// This model stores material data in SwiftData and can be converted to/from
/// the domain `Material` type using `MaterialPersistenceMapper`.
///
/// ## Notes
/// - The `id` property has a unique constraint to ensure data integrity
/// - File URL is stored as String for SwiftData compatibility
/// - Status is stored as String to match backend API
@Model
public final class MaterialModel {
    /// Unique identifier for the material
    @Attribute(.unique)
    public var id: UUID

    /// Title of the material
    public var title: String

    /// Description of the material
    public var materialDescription: String?

    /// Processing status of the material (uploaded, processing, ready, failed)
    public var status: String

    /// URL where the material file is stored (as String)
    public var fileURL: String?

    /// MIME type of the file (e.g., "application/pdf")
    public var fileType: String?

    /// Size of the file in bytes
    public var fileSizeBytes: Int?

    /// ID of the school this material belongs to
    public var schoolID: UUID

    /// ID of the academic unit this material is associated with (optional)
    public var academicUnitID: UUID?

    /// ID of the teacher who uploaded this material
    public var uploadedByTeacherID: UUID?

    /// Subject of the material (e.g., "Mathematics")
    public var subject: String?

    /// Grade level (e.g., "12th Grade")
    public var grade: String?

    /// Whether the material is publicly accessible
    public var isPublic: Bool

    /// Timestamp when processing started
    public var processingStartedAt: Date?

    /// Timestamp when processing completed
    public var processingCompletedAt: Date?

    /// Timestamp when the material was created
    public var createdAt: Date

    /// Timestamp when the material was last updated
    public var updatedAt: Date

    /// Timestamp when the material was deleted (soft delete)
    public var deletedAt: Date?

    /// Creates a new MaterialModel instance
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - title: Title of the material
    ///   - materialDescription: Description of the material
    ///   - status: Processing status (defaults to "uploaded")
    ///   - fileURL: URL where the file is stored
    ///   - fileType: MIME type of the file
    ///   - fileSizeBytes: Size of the file in bytes
    ///   - schoolID: ID of the school
    ///   - academicUnitID: ID of the academic unit
    ///   - uploadedByTeacherID: ID of the uploading teacher
    ///   - subject: Subject of the material
    ///   - grade: Grade level
    ///   - isPublic: Whether publicly accessible (defaults to false)
    ///   - processingStartedAt: When processing started
    ///   - processingCompletedAt: When processing completed
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - updatedAt: Last update timestamp (defaults to now)
    ///   - deletedAt: Deletion timestamp
    public init(
        id: UUID = UUID(),
        title: String,
        materialDescription: String? = nil,
        status: String = "uploaded",
        fileURL: String? = nil,
        fileType: String? = nil,
        fileSizeBytes: Int? = nil,
        schoolID: UUID,
        academicUnitID: UUID? = nil,
        uploadedByTeacherID: UUID? = nil,
        subject: String? = nil,
        grade: String? = nil,
        isPublic: Bool = false,
        processingStartedAt: Date? = nil,
        processingCompletedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.materialDescription = materialDescription
        self.status = status
        self.fileURL = fileURL
        self.fileType = fileType
        self.fileSizeBytes = fileSizeBytes
        self.schoolID = schoolID
        self.academicUnitID = academicUnitID
        self.uploadedByTeacherID = uploadedByTeacherID
        self.subject = subject
        self.grade = grade
        self.isPublic = isPublic
        self.processingStartedAt = processingStartedAt
        self.processingCompletedAt = processingCompletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}
