import Foundation

// MARK: - Switch Context Request DTO

/// Request para cambiar de contexto (escuela/rol).
///
/// Usado en `POST /v1/auth/switch-context`.
public struct SwitchContextRequestDTO: Codable, Sendable, Equatable {
    public let schoolId: String
    public let roleId: String?

    enum CodingKeys: String, CodingKey {
        case schoolId = "school_id"
        case roleId = "role_id"
    }

    public init(schoolId: String, roleId: String? = nil) {
        self.schoolId = schoolId
        self.roleId = roleId
    }
}
