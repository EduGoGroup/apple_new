import EduNetwork

/// Servicio de autenticación para la DemoApp.
///
/// Actor thread-safe que gestiona el login/logout y el token JWT.
/// Usa `NetworkClient` concreto para poder llamar `setAuthorizationToken`.
public actor AuthService {

    // MARK: - Properties

    private let networkClient: NetworkClient
    private let mobileBaseURL: String

    /// Token JWT actual, `nil` si no está autenticado.
    public private(set) var token: String?

    /// Indica si el usuario tiene una sesión activa.
    public var isAuthenticated: Bool {
        token != nil
    }

    // MARK: - Initialization

    /// Inicializa el servicio de autenticación.
    /// - Parameters:
    ///   - networkClient: Cliente de red concreto.
    ///   - mobileBaseURL: URL base de la API mobile (e.g., "http://localhost:3000").
    public init(networkClient: NetworkClient, mobileBaseURL: String) {
        self.networkClient = networkClient
        self.mobileBaseURL = mobileBaseURL
    }

    // MARK: - Auth Methods

    /// Autentica al usuario con email y contraseña.
    /// - Parameters:
    ///   - email: Email del usuario.
    ///   - password: Contraseña del usuario.
    /// - Returns: Respuesta con token y datos del usuario.
    /// - Throws: `NetworkError` si la autenticación falla.
    @discardableResult
    public func login(email: String, password: String) async throws -> LoginResponseDTO {
        let body = LoginRequestDTO(email: email, password: password)
        let url = "\(mobileBaseURL)/v1/auth/login"

        let response: LoginResponseDTO = try await networkClient.post(url, body: body)

        token = response.token
        await networkClient.setAuthorizationToken(response.token)

        return response
    }

    /// Cierra la sesión del usuario y limpia el token.
    public func logout() async {
        token = nil
        await networkClient.clearAuthorizationToken()
    }
}
