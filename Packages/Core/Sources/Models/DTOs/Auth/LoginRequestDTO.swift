import Foundation

// MARK: - Login Request DTO

/// Request para autenticacion de usuario.
///
/// Usado en `POST /v1/auth/login`.
public struct LoginRequestDTO: Codable, Sendable, Equatable {
    public let email: String
    public let password: String

    enum CodingKeys: String, CodingKey {
        case email
        case password
    }

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}
