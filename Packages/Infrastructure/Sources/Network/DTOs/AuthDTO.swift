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
    public let name: String

    enum CodingKeys: String, CodingKey {
        case id, email, name
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

    public init(accessToken: String, refreshToken: String, expiresIn: Int) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
    }
}
