import Foundation
import EduFoundation

// MARK: - MaterialStatus

/// Represents the processing status of an educational material.
///
/// Materials go through a lifecycle from upload to being ready for consumption.
public enum MaterialStatus: String, Sendable, Equatable, Hashable, Codable, CaseIterable {
    /// Material has been uploaded but not yet processed
    case uploaded = "uploaded"

    /// Material is currently being processed
    case processing = "processing"

    /// Material is ready for use
    case ready = "ready"

    /// Processing failed
    case failed = "failed"
}

extension MaterialStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .uploaded:
            return "Uploaded"
        case .processing:
            return "Processing"
        case .ready:
            return "Ready"
        case .failed:
            return "Failed"
        }
    }
}

// MARK: - Material Entity

/// Represents an educational material in the system.
///
/// `Material` is a domain entity representing educational content such as
/// PDFs, documents, or other files that teachers can share with students.
///
/// ## Backend Alignment
/// This model aligns with edu-mobile API `/v1/materials`:
/// - Uses `fileURL` (maps to `file_url` in JSON)
/// - Uses `schoolID` (maps to `school_id` in JSON)
/// - Uses `academicUnitID` (maps to `academic_unit_id` in JSON)
/// - Uses `uploadedByTeacherID` (maps to `uploaded_by_teacher_id` in JSON)
///
/// ## Example
/// ```swift
/// let material = try Material(
///     title: "Introduction to Calculus",
///     description: "A comprehensive guide",
///     fileURL: URL(string: "https://example.com/file.pdf")!,
///     schoolID: schoolID
/// )
/// ```
public struct Material: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the material
    public let id: UUID

    /// Title of the material
    public let title: String

    /// Description of the material
    public let description: String?

    /// Processing status of the material
    public let status: MaterialStatus

    /// URL where the material file is stored
    public let fileURL: URL?

    /// MIME type of the file (e.g., "application/pdf")
    public let fileType: String?

    /// Size of the file in bytes
    public let fileSizeBytes: Int?

    /// ID of the school this material belongs to
    public let schoolID: UUID

    /// ID of the academic unit this material is associated with (optional)
    public let academicUnitID: UUID?

    /// ID of the teacher who uploaded this material
    public let uploadedByTeacherID: UUID?

    /// Subject of the material (e.g., "Mathematics")
    public let subject: String?

    /// Grade level (e.g., "12th Grade")
    public let grade: String?

    /// Whether the material is publicly accessible
    public let isPublic: Bool

    /// Timestamp when processing started
    public let processingStartedAt: Date?

    /// Timestamp when processing completed
    public let processingCompletedAt: Date?

    /// Timestamp when the material was created
    public let createdAt: Date

    /// Timestamp when the material was last updated
    public let updatedAt: Date

    /// Timestamp when the material was deleted (soft delete)
    public let deletedAt: Date?

    // MARK: - Computed Properties

    /// Whether the material is ready for use
    public var isReady: Bool {
        status == .ready
    }

    /// Whether the material is currently being processed
    public var isProcessing: Bool {
        status == .processing || status == .uploaded
    }

    /// Whether the material has been deleted
    public var isDeleted: Bool {
        deletedAt != nil
    }

    // MARK: - Initialization

    /// Creates a new Material instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - title: Title of the material. Must not be empty.
    ///   - description: Description of the material.
    ///   - status: Processing status. Defaults to `.uploaded`.
    ///   - fileURL: URL where the file is stored.
    ///   - fileType: MIME type of the file.
    ///   - fileSizeBytes: Size of the file in bytes.
    ///   - schoolID: ID of the school.
    ///   - academicUnitID: ID of the academic unit.
    ///   - uploadedByTeacherID: ID of the uploading teacher.
    ///   - subject: Subject of the material.
    ///   - grade: Grade level.
    ///   - isPublic: Whether publicly accessible. Defaults to false.
    ///   - processingStartedAt: When processing started.
    ///   - processingCompletedAt: When processing completed.
    ///   - createdAt: Creation timestamp. Defaults to now.
    ///   - updatedAt: Last update timestamp. Defaults to now.
    ///   - deletedAt: Deletion timestamp.
    /// - Throws: `DomainError.validationFailed` if title is empty.
    public init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        status: MaterialStatus = .uploaded,
        fileURL: URL? = nil,
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
    ) throws {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            throw DomainError.validationFailed(field: "title", reason: "Title cannot be empty")
        }

        self.id = id
        self.title = trimmedTitle
        self.description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.status = status
        self.fileURL = fileURL
        self.fileType = fileType
        self.fileSizeBytes = fileSizeBytes
        self.schoolID = schoolID
        self.academicUnitID = academicUnitID
        self.uploadedByTeacherID = uploadedByTeacherID
        self.subject = subject?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.grade = grade?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.isPublic = isPublic
        self.processingStartedAt = processingStartedAt
        self.processingCompletedAt = processingCompletedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    // MARK: - Copy Methods

    /// Creates a copy with updated title.
    ///
    /// - Parameter title: The new title.
    /// - Returns: A new `Material` instance with the updated title.
    /// - Throws: `DomainError.validationFailed` if title is empty.
    public func with(title: String) throws -> Material {
        try Material(
            id: id,
            title: title,
            description: description,
            status: status,
            fileURL: fileURL,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: uploadedByTeacherID,
            subject: subject,
            grade: grade,
            isPublic: isPublic,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: deletedAt
        )
    }

    /// Creates a copy with updated status.
    ///
    /// - Parameter status: The new status.
    /// - Returns: A new `Material` instance with the updated status.
    public func with(status: MaterialStatus) -> Material {
        // swiftlint:disable:next force_try
        try! Material(
            id: id,
            title: title,
            description: description,
            status: status,
            fileURL: fileURL,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: uploadedByTeacherID,
            subject: subject,
            grade: grade,
            isPublic: isPublic,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: deletedAt
        )
    }

    /// Creates a copy with updated description.
    ///
    /// - Parameter description: The new description.
    /// - Returns: A new `Material` instance with the updated description.
    public func with(description: String?) -> Material {
        // swiftlint:disable:next force_try
        try! Material(
            id: id,
            title: title,
            description: description,
            status: status,
            fileURL: fileURL,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: uploadedByTeacherID,
            subject: subject,
            grade: grade,
            isPublic: isPublic,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: deletedAt
        )
    }

    /// Creates a copy with updated public status.
    ///
    /// - Parameter isPublic: The new public status.
    /// - Returns: A new `Material` instance with the updated public status.
    public func with(isPublic: Bool) -> Material {
        // swiftlint:disable:next force_try
        try! Material(
            id: id,
            title: title,
            description: description,
            status: status,
            fileURL: fileURL,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: uploadedByTeacherID,
            subject: subject,
            grade: grade,
            isPublic: isPublic,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: deletedAt
        )
    }

    /// Creates a copy marking the material as deleted.
    ///
    /// - Parameter date: The deletion date. Defaults to now.
    /// - Returns: A new `Material` instance marked as deleted.
    public func delete(at date: Date = Date()) -> Material {
        // swiftlint:disable:next force_try
        try! Material(
            id: id,
            title: title,
            description: description,
            status: status,
            fileURL: fileURL,
            fileType: fileType,
            fileSizeBytes: fileSizeBytes,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: uploadedByTeacherID,
            subject: subject,
            grade: grade,
            isPublic: isPublic,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt,
            createdAt: createdAt,
            updatedAt: Date(),
            deletedAt: date
        )
    }
}
