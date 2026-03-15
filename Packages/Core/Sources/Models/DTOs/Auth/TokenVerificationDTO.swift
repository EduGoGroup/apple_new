import Foundation

// MARK: - Token Verification Request DTO

/// Request para verificar la validez de un token contra el servidor.
///
/// Usado en `POST /api/v1/auth/verify`.
public struct TokenVerificationRequestDTO: Codable, Sendable, Equatable {
    public let token: String

    public init(token: String) {
        self.token = token
    }
}

// MARK: - Token Verification Response DTO

/// Respuesta del servidor al verificar un token.
public struct TokenVerificationResponseDTO: Codable, Sendable, Equatable {
    public let valid: Bool
    public let userId: String?
    public let email: String?
    public let role: String?
    public let schoolId: String?

    enum CodingKeys: String, CodingKey {
        case valid
        case userId = "user_id"
        case email
        case role
        case schoolId = "school_id"
    }

    public init(valid: Bool, userId: String? = nil, email: String? = nil, role: String? = nil, schoolId: String? = nil) {
        self.valid = valid
        self.userId = userId
        self.email = email
        self.role = role
        self.schoolId = schoolId
    }
}
