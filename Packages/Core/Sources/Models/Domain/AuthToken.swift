import Foundation

// MARK: - AuthToken

/// Token de autenticacion con logica de expiracion.
///
/// Modelo de dominio inmutable que encapsula el access token,
/// refresh token y momento de expiracion. Provee computed properties
/// para verificar si el token ha expirado o necesita renovarse.
///
/// ## Ejemplo
/// ```swift
/// let token = AuthToken(
///     accessToken: "eyJ...",
///     refreshToken: "dGhpcyBpcyBhIH...",
///     expiresAt: Date().addingTimeInterval(3600),
///     tokenType: "Bearer"
/// )
///
/// if token.isExpired {
///     // Renovar token
/// } else if token.shouldRefresh() {
///     // Renovar proactivamente (faltan < 5 min)
/// }
/// ```
public struct AuthToken: Sendable, Equatable, Codable, Hashable {

    // MARK: - Properties

    /// JWT access token para autorizar requests.
    public let accessToken: String

    /// Token para renovar el access token cuando expire.
    public let refreshToken: String

    /// Momento exacto en que el token expira.
    public let expiresAt: Date

    /// Tipo de token (e.g. "Bearer").
    public let tokenType: String

    // MARK: - Computed Properties

    /// `true` si el token ya expiro.
    public var isExpired: Bool {
        Date.now >= expiresAt
    }

    // MARK: - Methods

    /// Indica si el token deberia renovarse proactivamente.
    ///
    /// - Parameter thresholdMinutes: Minutos antes de la expiracion
    ///   en los que se considera necesario renovar. Default: 5.
    /// - Returns: `true` si el token expira dentro del umbral o ya expiro.
    public func shouldRefresh(thresholdMinutes: Int = 5) -> Bool {
        let threshold = TimeInterval(thresholdMinutes * 60)
        return Date.now.addingTimeInterval(threshold) >= expiresAt
    }

    // MARK: - Initialization

    public init(
        accessToken: String,
        refreshToken: String,
        expiresAt: Date,
        tokenType: String = "Bearer"
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
        self.tokenType = tokenType
    }
}

// MARK: - Factory Methods

extension AuthToken {
    /// Crea un `AuthToken` a partir de la respuesta de login.
    public static func from(response: LoginResponseDTO) -> AuthToken {
        AuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date.now.addingTimeInterval(TimeInterval(response.expiresIn)),
            tokenType: response.tokenType
        )
    }

    /// Crea un `AuthToken` a partir de la respuesta de refresh.
    public static func from(response: RefreshTokenResponseDTO) -> AuthToken {
        AuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: Date.now.addingTimeInterval(TimeInterval(response.expiresIn)),
            tokenType: response.tokenType
        )
    }
}
