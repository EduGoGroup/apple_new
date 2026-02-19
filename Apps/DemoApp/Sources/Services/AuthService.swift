import EduNetwork
import EduStorage

/// Servicio de autenticación para la DemoApp.
///
/// Actor thread-safe que gestiona el login/logout, persistencia de tokens
/// y conforma `TokenProvider` para uso con `AuthenticationInterceptor`.
public actor AuthService: TokenProvider {

    // MARK: - Properties

    private let networkClient: NetworkClient
    private let adminBaseURL: String
    private let storage: StorageManager

    private static let tokenKey = "auth_token"
    private static let userKey = "auth_user"
    private static let contextKey = "auth_context"

    /// Token JWT actual, `nil` si no está autenticado.
    public private(set) var token: String?

    /// Refresh token actual.
    public private(set) var refreshTokenValue: String?

    /// Rol del usuario en el contexto activo.
    public private(set) var userRole: String?

    /// Indica si el usuario tiene una sesión activa.
    public var isAuthenticated: Bool { token != nil }

    // MARK: - Initialization

    public init(networkClient: NetworkClient, adminBaseURL: String, storage: StorageManager = .shared) {
        self.networkClient = networkClient
        self.adminBaseURL = adminBaseURL
        self.storage = storage
    }

    // MARK: - TokenProvider

    public func getAccessToken() async -> String? { token }

    public func refreshToken() async -> String? {
        // TODO: implement refresh flow in future
        return token
    }

    public func isTokenExpired() async -> Bool { false }

    // MARK: - Auth Methods

    /// Autentica al usuario con email y contraseña.
    @discardableResult
    public func login(email: String, password: String) async throws -> LoginResponseDTO {
        let body = LoginRequestDTO(email: email, password: password)
        let url = "\(adminBaseURL)/v1/auth/login"
        let response: LoginResponseDTO = try await networkClient.post(url, body: body)

        token = response.accessToken
        refreshTokenValue = response.refreshToken
        userRole = response.activeContext.roleName
        await networkClient.setAuthorizationToken(response.accessToken)

        // Persist token
        let storedToken = StoredAuthToken(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresIn: response.expiresIn
        )
        try? await storage.save(storedToken, forKey: Self.tokenKey)

        return response
    }

    /// Cierra la sesión del usuario y limpia el token.
    public func logout() async {
        // Call logout API (ignore errors)
        if token != nil {
            let request = HTTPRequest.post("\(adminBaseURL)/v1/auth/logout")
            _ = try? await networkClient.requestData(request)
        }

        token = nil
        refreshTokenValue = nil
        userRole = nil
        await networkClient.clearAuthorizationToken()

        await storage.remove(forKey: Self.tokenKey)
        await storage.remove(forKey: Self.userKey)
        await storage.remove(forKey: Self.contextKey)
    }

    /// Restaura sesión desde token persistido.
    public func restoreSession() async -> Bool {
        guard let stored = try? await storage.retrieve(StoredAuthToken.self, forKey: Self.tokenKey) else {
            return false
        }
        token = stored.accessToken
        refreshTokenValue = stored.refreshToken
        await networkClient.setAuthorizationToken(stored.accessToken)
        return true
    }
}
