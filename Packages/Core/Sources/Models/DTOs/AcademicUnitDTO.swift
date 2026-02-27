import Foundation
import EduFoundation

/// Data Transfer Object for AcademicUnit entity.
///
/// This DTO maps to the backend API response structure with snake_case field names.
/// Use this for JSON encoding/decoding when communicating with the backend.
public struct AcademicUnitDTO: Codable, Sendable, Equatable {

    // MARK: - Properties

    public let id: UUID
    public let displayName: String
    public let code: String?
    public let description: String?
    public let type: String
    public let parentUnitID: UUID?
    public let schoolID: UUID
    public let metadata: [String: JSONValue]?
    public let createdAt: Date
    public let updatedAt: Date
    public let deletedAt: Date?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case code
        case description
        case type
        case parentUnitID = "parent_unit_id"
        case schoolID = "school_id"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }

    // MARK: - Initialization

    public init(
        id: UUID,
        displayName: String,
        code: String?,
        description: String?,
        type: String,
        parentUnitID: UUID?,
        schoolID: UUID,
        metadata: [String: JSONValue]?,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date?
    ) {
        self.id = id
        self.displayName = displayName
        self.code = code
        self.description = description
        self.type = type
        self.parentUnitID = parentUnitID
        self.schoolID = schoolID
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
}

// MARK: - Domain Conversion Extensions

extension AcademicUnitDTO {
    /// Converts the DTO to a domain AcademicUnit entity.
    ///
    /// - Returns: An `AcademicUnit` domain entity.
    /// - Throws: `DomainError.validationFailed` if type is unknown.
    public func toDomain() throws -> AcademicUnit {
        guard let unitType = AcademicUnitType(rawValue: type) else {
            throw DomainError.validationFailed(
                field: "type",
                reason: "Tipo desconocido: '\(type)'"
            )
        }

        return try AcademicUnit(
            id: id,
            displayName: displayName,
            code: code,
            description: description,
            type: unitType,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}

extension AcademicUnit {
    /// Converts the domain entity to a DTO.
    ///
    /// - Returns: An `AcademicUnitDTO` for API communication.
    public func toDTO() -> AcademicUnitDTO {
        AcademicUnitDTO(
            id: id,
            displayName: displayName,
            code: code,
            description: description,
            type: type.rawValue,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: metadata,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )
    }
}
