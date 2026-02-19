import Foundation

/// Proveedor de tokens de autenticación.
///
/// Protocolo que abstrae la obtención de tokens para permitir
/// diferentes estrategias de autenticación.
public protocol TokenProvider: Sendable {
    /// Obtiene el token de acceso actual.
    /// - Returns: Token de acceso o nil si no hay sesión activa
    func getAccessToken() async -> String?

    /// Refresca el token de acceso.
    /// - Returns: Nuevo token de acceso o nil si el refresh falla
    func refreshToken() async -> String?

    /// Indica si el token actual está expirado o próximo a expirar.
    func isTokenExpired() async -> Bool
}

/// Interceptor que inyecta tokens de autenticación en las requests.
///
/// Maneja automáticamente:
/// - Inyección de Bearer token en el header Authorization
/// - Refresh de tokens cuando están próximos a expirar
/// - Retry automático en caso de 401 Unauthorized
///
/// ## Uso
/// ```swift
/// let tokenProvider = MyTokenProvider()
/// let authInterceptor = AuthenticationInterceptor(tokenProvider: tokenProvider)
/// let client = NetworkClient(interceptors: [authInterceptor])
/// ```
public actor AuthenticationInterceptor: RequestInterceptor {
    /// Proveedor de tokens.
    private let tokenProvider: any TokenProvider

    /// Nombre del header de autorización.
    private let headerName: String

    /// Prefijo del token (e.g., "Bearer").
    private let tokenPrefix: String

    /// Si debe intentar refresh automático antes de requests.
    private let autoRefresh: Bool

    /// Si debe reintentar en caso de 401.
    private let retryOn401: Bool

    /// Máximo número de reintentos por 401.
    private let maxRetryCount: Int

    /// URLs que no requieren autenticación (e.g., login, registro).
    private let excludedPaths: Set<String>

    /// Tarea compartida para refresh concurrente.
    private var refreshTask: Task<String?, Never>?

    /// Inicializador con configuración completa.
    /// - Parameters:
    ///   - tokenProvider: Proveedor de tokens
    ///   - headerName: Nombre del header (default: "Authorization")
    ///   - tokenPrefix: Prefijo del token (default: "Bearer")
    ///   - autoRefresh: Si hacer refresh automático (default: true)
    ///   - retryOn401: Si reintentar en 401 (default: true)
    ///   - maxRetryCount: Máximo reintentos por 401 (default: 1)
    ///   - excludedPaths: Paths sin autenticación (default: [])
    public init(
        tokenProvider: any TokenProvider,
        headerName: String = "Authorization",
        tokenPrefix: String = "Bearer",
        autoRefresh: Bool = true,
        retryOn401: Bool = true,
        maxRetryCount: Int = 1,
        excludedPaths: Set<String> = []
    ) {
        self.tokenProvider = tokenProvider
        self.headerName = headerName
        self.tokenPrefix = tokenPrefix
        self.autoRefresh = autoRefresh
        self.retryOn401 = retryOn401
        self.maxRetryCount = maxRetryCount
        self.excludedPaths = excludedPaths
    }

    // MARK: - RequestInterceptor

    public func adapt(
        _ request: URLRequest,
        context: RequestContext
    ) async throws -> URLRequest {
        // Verificar si la URL está excluida
        if isExcluded(request.url) {
            return request
        }

        // Si ya tiene header de auth, no modificar
        if request.value(forHTTPHeaderField: headerName) != nil {
            return request
        }

        // Verificar si necesita refresh
        if autoRefresh {
            let isExpired = await tokenProvider.isTokenExpired()
            if isExpired {
                await refreshTokenIfNeeded()
            }
        }

        // Obtener token
        guard let token = await tokenProvider.getAccessToken() else {
            // Sin token, enviar request sin autenticación
            return request
        }

        // Inyectar token
        var modifiedRequest = request
        let authValue = tokenPrefix.isEmpty ? token : "\(tokenPrefix) \(token)"
        modifiedRequest.setValue(authValue, forHTTPHeaderField: headerName)

        return modifiedRequest
    }

    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        context: RequestContext
    ) async -> RetryDecision {
        // Solo manejar 401 Unauthorized
        guard case .unauthorized = error else {
            return .doNotRetry
        }

        // Verificar si está habilitado el retry
        guard retryOn401 else {
            return .doNotRetry
        }

        // Verificar límite de reintentos
        guard context.attemptNumber <= maxRetryCount else {
            return .doNotRetry
        }

        // Verificar si la URL está excluida
        if isExcluded(request.url) {
            return .doNotRetry
        }

        // Intentar refresh del token
        let refreshed = await refreshTokenIfNeeded()

        guard refreshed else {
            return .doNotRetry
        }

        // Reintentar inmediatamente con el nuevo token
        return .retryImmediately
    }

    // MARK: - Private Methods

    private func isExcluded(_ url: URL?) -> Bool {
        guard let path = url?.path else { return false }

        return excludedPaths.contains { excludedPath in
            path.contains(excludedPath)
        }
    }

    @discardableResult
    private func refreshTokenIfNeeded() async -> Bool {
        if let refreshTask {
            return await refreshTask.value != nil
        }

        let task = Task { await tokenProvider.refreshToken() }
        refreshTask = task
        let newToken = await task.value
        refreshTask = nil
        return newToken != nil
    }
}

// MARK: - Simple Token Provider

/// Proveedor de tokens simple basado en closures.
///
/// Útil para casos donde no se necesita un proveedor complejo.
public struct SimpleTokenProvider: TokenProvider {
    private let getToken: @Sendable () async -> String?
    private let refresh: @Sendable () async -> String?
    private let checkExpired: @Sendable () async -> Bool

    /// Inicializador con closures.
    /// - Parameters:
    ///   - getToken: Closure que retorna el token actual
    ///   - refresh: Closure que refresca el token
    ///   - isExpired: Closure que verifica expiración
    public init(
        getToken: @escaping @Sendable () async -> String?,
        refresh: @escaping @Sendable () async -> String? = { nil },
        isExpired: @escaping @Sendable () async -> Bool = { false }
    ) {
        self.getToken = getToken
        self.refresh = refresh
        self.checkExpired = isExpired
    }

    public func getAccessToken() async -> String? {
        await getToken()
    }

    public func refreshToken() async -> String? {
        await refresh()
    }

    public func isTokenExpired() async -> Bool {
        await checkExpired()
    }
}

/// Proveedor de tokens estático para testing.
public struct StaticTokenProvider: TokenProvider {
    private let token: String?

    /// Crea un proveedor con un token fijo.
    public init(token: String?) {
        self.token = token
    }

    public func getAccessToken() async -> String? {
        token
    }

    public func refreshToken() async -> String? {
        token
    }

    public func isTokenExpired() async -> Bool {
        false
    }
}

// MARK: - Convenience Initializers

extension AuthenticationInterceptor {
    /// Crea un interceptor con paths de autenticación excluidos comunes.
    /// - Parameters:
    ///   - tokenProvider: Proveedor de tokens
    ///   - additionalExcludedPaths: Paths adicionales a excluir
    public static func standard(
        tokenProvider: any TokenProvider,
        additionalExcludedPaths: Set<String> = []
    ) -> AuthenticationInterceptor {
        let commonExcludedPaths: Set<String> = [
            "/auth/login",
            "/auth/register",
            "/auth/forgot-password",
            "/auth/reset-password",
            "/public/"
        ]

        return AuthenticationInterceptor(
            tokenProvider: tokenProvider,
            excludedPaths: commonExcludedPaths.union(additionalExcludedPaths)
        )
    }
}
