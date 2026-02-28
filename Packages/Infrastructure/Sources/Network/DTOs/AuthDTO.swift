import Foundation

// MARK: - Login Request DTO

/// Request para autenticación de usuario.
///
/// Usado en `POST /v1/auth/login`.
public struct LoginRequestDTO: Encodable, Sendable, Equatable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }

    enum CodingKeys: String, CodingKey {
        case email
        case password
    }
}

// MARK: - Login Response DTO

/// Respuesta del endpoint de login.
///
/// Respuesta de `POST /v1/auth/login`.
public struct LoginResponseDTO: Decodable, Sendable, Equatable {
    public let accessToken: String
    public let expiresIn: Int
    public let refreshToken: String
    public let tokenType: String
    public let user: AuthUserInfoDTO
    public let activeContext: ActiveContextDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case user
        case activeContext = "active_context"
    }
}

// MARK: - Auth User Info DTO

/// Datos básicos del usuario autenticado.
public struct AuthUserInfoDTO: Decodable, Sendable, Equatable {
    public let id: String
    public let email: String
    public let firstName: String
    public let lastName: String
    public let fullName: String
    public let schoolId: String?

    enum CodingKeys: String, CodingKey {
        case id, email
        case firstName = "first_name"
        case lastName = "last_name"
        case fullName = "full_name"
        case schoolId = "school_id"
    }
}

// MARK: - Active Context DTO

/// Datos del contexto activo del usuario autenticado.
public struct ActiveContextDTO: Decodable, Sendable, Equatable {
    public let roleName: String
    public let schoolId: String?
    public let permissions: [String]?

    enum CodingKeys: String, CodingKey {
        case roleName = "role_name"
        case schoolId = "school_id"
        case permissions
    }
}

// MARK: - Stored Auth Token

/// Token persistido para restaurar sesión.
public struct StoredAuthToken: Codable, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let issuedAt: Date

    /// `true` si el token ya superó su tiempo de vida.
    public var isExpired: Bool {
        Date().timeIntervalSince(issuedAt) >= Double(expiresIn)
    }

    public init(accessToken: String, refreshToken: String, expiresIn: Int, issuedAt: Date = Date()) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.issuedAt = issuedAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
        expiresIn = try container.decode(Int.self, forKey: .expiresIn)
        // Dato nuevo: si falta en payloads antiguos, se asume emitido ahora.
        issuedAt = try container.decodeIfPresent(Date.self, forKey: .issuedAt) ?? Date()
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case issuedAt = "issued_at"
    }
}
