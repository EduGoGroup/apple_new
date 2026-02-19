import Foundation

// MARK: - Login Request DTO

/// Request para autenticación de usuario.
///
/// Usado en `POST /v1/auth/login`.
public struct LoginRequestDTO: Encodable, Sendable, Equatable {
    /// Email del usuario.
    public let email: String

    /// Contraseña del usuario.
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }

    /// Maps JSON snake_case keys to Swift camelCase properties.
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
    /// Token JWT de autenticación.
    public let token: String

    /// Datos del usuario autenticado.
    public let user: ActiveContextDTO

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case token
        case user
    }
}

// MARK: - Active Context DTO

/// Datos del contexto activo del usuario autenticado.
public struct ActiveContextDTO: Decodable, Sendable, Equatable {
    /// ID del usuario.
    public let id: String

    /// Nombre del usuario.
    public let firstName: String

    /// Apellido del usuario.
    public let lastName: String

    /// Email del usuario.
    public let email: String

    /// Rol del usuario (e.g., "student", "teacher", "admin").
    public let role: String

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case role
    }
}
