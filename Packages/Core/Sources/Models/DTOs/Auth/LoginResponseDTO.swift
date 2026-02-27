import Foundation

// MARK: - Login Response DTO

/// Respuesta del endpoint de login.
///
/// Respuesta de `POST /v1/auth/login`.
public struct LoginResponseDTO: Codable, Sendable, Equatable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let tokenType: String
    public let user: AuthUserInfoDTO
    public let schools: [SchoolInfoDTO]
    public let activeContext: UserContextDTO

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case user
        case schools
        case activeContext = "active_context"
    }

    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int,
        tokenType: String,
        user: AuthUserInfoDTO,
        schools: [SchoolInfoDTO],
        activeContext: UserContextDTO
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.user = user
        self.schools = schools
        self.activeContext = activeContext
    }
}
