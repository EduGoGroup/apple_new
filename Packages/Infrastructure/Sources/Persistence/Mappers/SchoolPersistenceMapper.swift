import Foundation
import EduCore
import EduFoundation

/// Mapper for converting between SchoolModel (SwiftData) and School (domain)
///
/// This struct provides static methods for bidirectional conversion between
/// the persistence model and the domain entity.
///
/// ## Usage
///
/// ```swift
/// // Convert from persistence to domain
/// let school = try SchoolPersistenceMapper.toDomain(schoolModel)
///
/// // Convert from domain to persistence (new model)
/// let model = SchoolPersistenceMapper.toModel(school, existing: nil)
///
/// // Update existing model from domain
/// let updatedModel = SchoolPersistenceMapper.toModel(school, existing: existingModel)
/// ```
///
/// ## Notes
/// - Does NOT conform to `MapperProtocol` because `@Model` types are not `Codable`
/// - Throws `DomainError.validationFailed` if data is corrupted
public struct SchoolPersistenceMapper: Sendable {
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

    /// Converts a SchoolModel to a domain School
    ///
    /// - Parameter model: The SwiftData model to convert
    /// - Returns: A domain School entity
    /// - Throws: `DomainError.validationFailed` if the model contains invalid data
    public static func toDomain(_ model: SchoolModel) throws -> School {
        let metadata = try decodeMetadata(model.metadataData)

        return try School(
            id: model.id,
            name: model.name,
            code: model.code,
            isActive: model.isActive,
            address: model.address,
            city: model.city,
            country: model.country,
            contactEmail: model.contactEmail,
            contactPhone: model.contactPhone,
            maxStudents: model.maxStudents,
            maxTeachers: model.maxTeachers,
            subscriptionTier: model.subscriptionTier,
            metadata: metadata,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt
        )
    }

    /// Converts a domain School to a SchoolModel
    ///
    /// If an existing model is provided, updates its properties instead of
    /// creating a new instance. This is useful for SwiftData's change tracking.
    ///
    /// - Parameters:
    ///   - domain: The domain School to convert
    ///   - existing: An optional existing SchoolModel to update
    /// - Returns: A SchoolModel with the domain entity's data
    public static func toModel(_ domain: School, existing: SchoolModel?) -> SchoolModel {
        if let existing = existing {
            // Update existing model in place for SwiftData change tracking
            existing.name = domain.name
            existing.code = domain.code
            existing.isActive = domain.isActive
            existing.address = domain.address
            existing.city = domain.city
            existing.country = domain.country
            existing.contactEmail = domain.contactEmail
            existing.contactPhone = domain.contactPhone
            existing.maxStudents = domain.maxStudents
            existing.maxTeachers = domain.maxTeachers
            existing.subscriptionTier = domain.subscriptionTier
            existing.metadataData = encodeMetadata(domain.metadata)
            existing.updatedAt = domain.updatedAt
            return existing
        } else {
            // Create new model
            return SchoolModel(
                id: domain.id,
                name: domain.name,
                code: domain.code,
                isActive: domain.isActive,
                address: domain.address,
                city: domain.city,
                country: domain.country,
                contactEmail: domain.contactEmail,
                contactPhone: domain.contactPhone,
                maxStudents: domain.maxStudents,
                maxTeachers: domain.maxTeachers,
                subscriptionTier: domain.subscriptionTier,
                metadataData: encodeMetadata(domain.metadata),
                createdAt: domain.createdAt,
                updatedAt: domain.updatedAt
            )
        }
    }
}
