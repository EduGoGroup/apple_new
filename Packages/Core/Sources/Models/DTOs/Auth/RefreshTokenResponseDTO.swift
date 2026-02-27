import Foundation

// MARK: - Refresh Token Response DTO

/// Respuesta del endpoint de refresh token.
///
/// Respuesta de `POST /v1/auth/refresh`.
public struct RefreshTokenResponseDTO: Codable, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
    }

    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        tokenType: String
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
    }
}
