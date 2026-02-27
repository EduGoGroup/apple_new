import Foundation
import EduFoundation

/// Data Transfer Object for Material entity.
///
/// This DTO maps to the backend API response structure with snake_case field names.
/// Use this for JSON encoding/decoding when communicating with the backend.
public struct MaterialDTO: Codable, Sendable, Equatable {

    // MARK: - Properties

    public let id: UUID
    public let title: String
    public let description: String?
    public let status: String
    public let fileURL: String?
    public let fileType: String?
    public let fileSizeBytes: Int?
    public let schoolID: UUID
    public let academicUnitID: UUID?
    public let uploadedByTeacherID: UUID?
    public let subject: String?
    public let grade: String?
    public let isPublic: Bool
    public let processingStartedAt: Date?
    public let processingCompletedAt: Date?
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case status
        case fileURL = "file_url"
        case fileType = "file_type"
        case fileSizeBytes = "file_size_bytes"
        case schoolID = "school_id"
        case academicUnitID = "academic_unit_id"
        case uploadedByTeacherID = "uploaded_by_teacher_id"
        case subject
        case grade
        case isPublic = "is_public"
        case processingStartedAt = "processing_started_at"
        case processingCompletedAt = "processing_completed_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    // MARK: - Initialization

    public init(
        id: UUID,
        title: String,
        description: String?,
        status: String,
        fileURL: String?,
        fileType: String?,
        fileSizeBytes: Int?,
        schoolID: UUID,
        academicUnitID: UUID?,
        uploadedByTeacherID: UUID?,
        subject: String?,
        grade: String?,
        isPublic: Bool,
        processingStartedAt: Date?,
        processingCompletedAt: Date?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) {
        self.id = id
        self.title = title
        self.description = description
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

// MARK: - Domain Conversion Extensions

extension MaterialDTO {
    /// Converts the DTO to a domain Material entity.
    ///
    /// - Returns: A `Material` domain entity.
    /// - Throws: `DomainError.validationFailed` if status or URL are invalid.
    public func toDomain() throws -> Material {
        guard let materialStatus = MaterialStatus(rawValue: status) else {
            throw DomainError.validationFailed(
                field: "status",
                reason: "Estado desconocido: '\(status)'"
            )
        }

        var url: URL?
        if let fileURLString = fileURL {
            guard let parsedURL = URL(string: fileURLString),
                  parsedURL.scheme != nil,
                  parsedURL.host != nil || parsedURL.isFileURL else {
                throw DomainError.validationFailed(
                    field: "fileURL",
                    reason: "URL inválida: '\(fileURLString)'"
                )
            }
            url = parsedURL
        }

        return try Material(
            id: id,
            title: title,
            description: description,
            status: materialStatus,
            fileURL: url,
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
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

extension Material {
    /// Converts the domain entity to a DTO.
    ///
    /// - Returns: A `MaterialDTO` for API communication.
    public func toDTO() -> MaterialDTO {
        MaterialDTO(
            id: id,
            title: title,
            description: description,
            status: status.rawValue,
            fileURL: fileURL?.absoluteString,
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
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}
