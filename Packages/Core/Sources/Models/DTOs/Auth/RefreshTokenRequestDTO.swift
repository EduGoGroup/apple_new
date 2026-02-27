import Foundation

// MARK: - Refresh Token Request DTO

/// Request para renovar el access token.
///
/// Usado en `POST /v1/auth/refresh`.
public struct RefreshTokenRequestDTO: Codable, Sendable, Equatable {
    public let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }

    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}
