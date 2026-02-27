import Foundation

/// Data Transfer Object for School entity.
///
/// This DTO maps to the backend API response structure with snake_case field names.
/// Use this for JSON encoding/decoding when communicating with the backend.
public struct SchoolDTO: Codable, Sendable, Equatable {

    // MARK: - Properties

    public let id: UUID
    public let name: String
    public let code: String
    public let isActive: Bool
    public let address: String?
    public let city: String?
    public let country: String?
    public let contactEmail: String?
    public let contactPhone: String?
    public let maxStudents: Int?
    public let maxTeachers: Int?
    public let subscriptionTier: String?
    public let metadata: [String: JSONValue]?
    public let createdAt: Date
    public let updatedAt: Date

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case code
        case isActive = "is_active"
        case address
        case city
        case country
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case maxStudents = "max_students"
        case maxTeachers = "max_teachers"
        case subscriptionTier = "subscription_tier"
        case metadata
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initialization

    public init(
        id: UUID,
        name: String,
        code: String,
        isActive: Bool,
        address: String?,
        city: String?,
        country: String?,
        contactEmail: String?,
        contactPhone: String?,
        maxStudents: Int?,
        maxTeachers: Int?,
        subscriptionTier: String?,
        metadata: [String: JSONValue]?,
        createdAt: Date,
        updatedAt: Date
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
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Domain Conversion Extensions

extension SchoolDTO {
    /// Converts the DTO to a domain School entity.
    ///
    /// - Returns: A `School` domain entity.
    /// - Throws: `DomainError.validationFailed` if conversion fails.
    public func toDomain() throws -> School {
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
            updatedAt: updatedAt
        )
    }
}

extension School {
    /// Converts the domain entity to a DTO.
    ///
    /// - Returns: A `SchoolDTO` for API communication.
    public func toDTO() -> SchoolDTO {
        SchoolDTO(
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
            updatedAt: updatedAt
        )
    }
}
