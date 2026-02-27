import Foundation

// MARK: - Auth User Info DTO

/// Datos basicos del usuario autenticado.
public struct AuthUserInfoDTO: Codable, Sendable, Equatable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let fullName: String
    public let schoolId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case schoolId = "school_id"
    }

    public init(
        id: String,
        email: String,
        firstName: String,
        lastName: String,
        fullName: String,
        schoolId: String? = nil
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.fullName = fullName
        self.schoolId = schoolId
    }
}
