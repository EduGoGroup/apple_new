import Foundation
import EduCore
import EduFoundation

/// Mapper for converting between AcademicUnitModel (SwiftData) and AcademicUnit (domain)
///
/// This struct provides static methods for bidirectional conversion between
/// the persistence model and the domain entity.
///
/// ## Usage
///
/// ```swift
/// // Convert from persistence to domain
/// let unit = try AcademicUnitPersistenceMapper.toDomain(unitModel)
///
/// // Convert from domain to persistence (new model)
/// let model = AcademicUnitPersistenceMapper.toModel(unit, existing: nil)
///
/// // Update existing model from domain
/// let updatedModel = AcademicUnitPersistenceMapper.toModel(unit, existing: existingModel)
/// ```
///
/// ## Notes
/// - Does NOT conform to `MapperProtocol` because `@Model` types are not `Codable`
/// - Handles parent-child relationships separately from mapping
/// - Throws `DomainError.validationFailed` for unknown type strings
/// - Throws `DomainError.validationFailed` if data is corrupted
public struct AcademicUnitPersistenceMapper: Sendable {
    private init() {}

    private static func decodeMetadata(_ data: Data?) throws -> [String: JSONValue]? {
        guard let data = data else {
            return nil
        }

        do {
            return try JSONDecoder().decode([String: JSONValue].self, from: data)
        } catch {
            throw DomainError.validationFailed(
                field: "metadata",
                reason: "Metadata JSON inválido"
            )
        }
    }

    private static func encodeMetadata(_ metadata: [String: JSONValue]?) -> Data? {
        guard let metadata = metadata else {
            return nil
        }

        return try? JSONEncoder().encode(metadata)
    }

    /// Converts an AcademicUnitModel to a domain AcademicUnit
    ///
    /// - Parameter model: The SwiftData model to convert
    /// - Returns: A domain AcademicUnit entity
    /// - Throws: `DomainError.validationFailed` if the model contains invalid data
    /// - Note: Parent-child relationships must be handled separately
    public static func toDomain(_ model: AcademicUnitModel) throws -> AcademicUnit {
        guard let unitType = AcademicUnitType(rawValue: model.type) else {
            throw DomainError.validationFailed(
                field: "type",
                reason: "Tipo desconocido: '\(model.type)'"
            )
        }

        let metadata = try decodeMetadata(model.metadataData)

        return try AcademicUnit(
            id: model.id,
            displayName: model.displayName,
            code: model.code,
            description: model.unitDescription,
            type: unitType,
            parentUnitID: model.parentUnit?.id,
            schoolID: model.schoolID,
            metadata: metadata,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            deletedAt: model.deletedAt
        )
    }

    /// Converts a domain AcademicUnit to an AcademicUnitModel
    ///
    /// If an existing model is provided, updates its properties instead of
    /// creating a new instance. This is useful for SwiftData's change tracking.
    ///
    /// - Parameters:
    ///   - domain: The domain AcademicUnit to convert
    ///   - existing: An optional existing AcademicUnitModel to update
    /// - Returns: An AcademicUnitModel with the domain entity's data
    /// - Note: Parent-child relationships must be set separately
    public static func toModel(_ domain: AcademicUnit, existing: AcademicUnitModel?) -> AcademicUnitModel {
        if let existing = existing {
            // Update existing model in place for SwiftData change tracking
            existing.displayName = domain.displayName
            existing.code = domain.code
            existing.unitDescription = domain.description
            existing.type = domain.type.rawValue
            existing.schoolID = domain.schoolID
            existing.metadataData = encodeMetadata(domain.metadata)
            existing.updatedAt = domain.updatedAt
            existing.deletedAt = domain.deletedAt
            // Note: parentUnit relationship must be updated separately
            return existing
        } else {
            // Create new model
            return AcademicUnitModel(
                id: domain.id,
                displayName: domain.displayName,
                code: domain.code,
                unitDescription: domain.description,
                type: domain.type.rawValue,
                schoolID: domain.schoolID,
                metadataData: encodeMetadata(domain.metadata),
                createdAt: domain.createdAt,
                updatedAt: domain.updatedAt,
                deletedAt: domain.deletedAt
                // Note: parentUnit relationship must be set separately
            )
        }
    }
}
