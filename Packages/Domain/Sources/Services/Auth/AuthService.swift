// AuthService.swift
// EduDomain
//
// Actor that manages authentication, token lifecycle, and session state.

import Foundation
import EduCore
import EduInfrastructure

/// Actor que gestiona autenticación, ciclo de vida de tokens y estado de sesión.
///
/// Implementa `TokenProvider` para que el `AuthenticationInterceptor` pueda
/// obtener y renovar tokens de forma transparente.
///
/// ## Arquitectura
/// - Usa un `NetworkClientProtocol` **sin interceptor de auth** para llamadas
///   de login y refresh (evita dependencia circular).
/// - Persiste `AuthToken` en Keychain para almacenamiento seguro entre lanzamientos.
/// - Migra automáticamente tokens de UserDefaults a Keychain en el primer uso.
/// - Expone `sessionStream` para observar cambios de sesión (login/logout/expired).
///
/// ## Ejemplo
/// ```swift
/// let authService = AuthService(
///     networkClient: plainClient,
///     apiConfig: .forEnvironment(.staging)
/// )
///
/// // Login
/// let session = try await authService.login(email: "user@example.com", password: "pass")
///
/// // Usar como TokenProvider para el interceptor
/// let interceptor = AuthenticationInterceptor.standard(
///     tokenProvider: authService,
///     sessionExpiredHandler: authService
/// )
/// ```
public actor AuthService: TokenProvider, SessionExpiredHandler {

    // MARK: - Storage Keys

    private static let tokenStorageKey = "com.edugo.auth.token"
    private static let contextStorageKey = "com.edugo.auth.context"

    // MARK: - Properties

    /// Cliente de red SIN interceptor de auth (para login/refresh).
    private let networkClient: any NetworkClientProtocol
    private let apiConfig: APIConfiguration

    /// Keychain manager for secure token persistence.
    private let keychainManager: KeychainManager

    /// Token actual en memoria.
    private var currentToken: AuthToken?

    /// Contexto activo (rol + escuela).
    private var currentContext: AuthContext?

    /// Info del usuario autenticado.
    private var userInfo: EduModels.AuthUserInfoDTO?

    /// Flag para evitar refresh recursivo.
    private var isRefreshing = false

    /// Whether migration from UserDefaults has been attempted.
    private var hasMigratedFromUserDefaults = false

    // MARK: - Session Stream

    private var sessionContinuation: AsyncStream<SessionEvent>.Continuation?
    private var _sessionStream: AsyncStream<SessionEvent>?

    /// Stream para observar eventos de sesión.
    public var sessionStream: AsyncStream<SessionEvent> {
        if _sessionStream == nil {
            let (stream, continuation) = AsyncStream<SessionEvent>.makeStream(
                bufferingPolicy: .unbounded
            )
            self._sessionStream = stream
            self.sessionContinuation = continuation
        }
        return _sessionStream!
    }

    // MARK: - Initialization

    /// Crea un AuthService.
    ///
    /// - Parameters:
    ///   - networkClient: Cliente de red **sin** interceptor de auth.
    ///   - apiConfig: Configuración de API con URLs base.
    ///   - keychainManager: Keychain manager for secure storage. Defaults to a shared instance.
    public init(
        networkClient: any NetworkClientProtocol,
        apiConfig: APIConfiguration,
        keychainManager: KeychainManager = KeychainManager()
    ) {
        self.networkClient = networkClient
        self.apiConfig = apiConfig
        self.keychainManager = keychainManager
    }

    // MARK: - Login

    /// Autentica al usuario con email y contraseña.
    ///
    /// - Parameters:
    ///   - email: Email del usuario.
    ///   - password: Contraseña del usuario.
    /// - Returns: Respuesta completa del login.
    /// - Throws: Error de red o autenticación.
    @discardableResult
    public func login(email: String, password: String) async throws -> EduModels.LoginResponseDTO {
        let url = "\(apiConfig.iamBaseURL)/api/v1/auth/login"
        let body = EduModels.LoginRequestDTO(email: email, password: password)
        let response: EduModels.LoginResponseDTO = try await networkClient.post(url, body: body)

        let token = AuthToken.from(response: response)
        currentToken = token
        currentContext = AuthContext.from(dto: response.activeContext)
        userInfo = response.user

        await persistToken(token)
        sessionContinuation?.yield(.loggedIn)

        return response
    }

    // MARK: - Logout

    /// Cierra la sesión del usuario.
    public func logout() async {
        currentToken = nil
        currentContext = nil
        userInfo = nil
        isRefreshing = false

        await clearPersistedToken()
        sessionContinuation?.yield(.loggedOut)
    }

    // MARK: - Session State

    /// Si el usuario tiene una sesión activa.
    public var isAuthenticated: Bool {
        currentToken != nil && !(currentToken?.isExpired ?? true)
    }

    /// Contexto activo actual.
    public var activeContext: AuthContext? {
        currentContext
    }

    /// Info del usuario autenticado.
    public var authenticatedUser: EduModels.AuthUserInfoDTO? {
        userInfo
    }

    // MARK: - Restore Session

    /// Intenta restaurar la sesión desde Keychain.
    ///
    /// On first call, migrates any existing tokens from UserDefaults to Keychain
    /// and removes the UserDefaults entries.
    ///
    /// - Returns: `true` si se restauró un token válido (no expirado).
    @discardableResult
    public func restoreSession() async -> Bool {
        // Migrate from UserDefaults to Keychain on first use
        if !hasMigratedFromUserDefaults {
            await migrateFromUserDefaults()
            hasMigratedFromUserDefaults = true
        }

        guard let token = try? await keychainManager.retrieve(AuthToken.self, for: Self.tokenStorageKey),
              !token.isExpired else {
            await clearPersistedToken()
            return false
        }

        currentToken = token

        if let context = try? await keychainManager.retrieve(AuthContext.self, for: Self.contextStorageKey) {
            currentContext = context
        }

        return true
    }

    // MARK: - Context Switching

    /// Cambia el contexto activo (rol + escuela).
    ///
    /// - Parameter context: Nuevo contexto del usuario.
    /// - Returns: Respuesta con nuevo token si el backend lo requiere.
    public func switchContext(_ contextDTO: UserContextDTO) async throws {
        guard let token = currentToken else { return }

        let url = "\(apiConfig.iamBaseURL)/api/v1/auth/switch-context"
        let body = SwitchContextRequestDTO(
            schoolId: contextDTO.schoolId ?? "",
            roleId: contextDTO.roleId
        )

        let response: EduModels.LoginResponseDTO = try await networkClient.post(
            url,
            body: body,
            headers: ["Authorization": "Bearer \(token.accessToken)"]
        )

        let newToken = AuthToken.from(response: response)
        currentToken = newToken
        currentContext = AuthContext.from(dto: response.activeContext)
        userInfo = response.user

        await persistToken(newToken)
        sessionContinuation?.yield(.contextSwitched)
    }

    // MARK: - TokenProvider

    public func getAccessToken() async -> String? {
        currentToken?.accessToken
    }

    public func refreshToken() async -> String? {
        guard !isRefreshing else { return currentToken?.accessToken }
        guard let token = currentToken else { return nil }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let url = "\(apiConfig.iamBaseURL)/api/v1/auth/refresh"
            let body = RefreshTokenRequestDTO(refreshToken: token.refreshToken)
            let response: RefreshTokenResponseDTO = try await networkClient.post(url, body: body)

            let newToken = AuthToken.from(response: response)
            currentToken = newToken
            await persistToken(newToken)

            return newToken.accessToken
        } catch {
            return nil
        }
    }

    public func isTokenExpired() async -> Bool {
        guard let token = currentToken else { return true }
        return token.shouldRefresh()
    }

    // MARK: - SessionExpiredHandler

    public func onSessionExpired() async {
        currentToken = nil
        currentContext = nil
        userInfo = nil
        await clearPersistedToken()
        sessionContinuation?.yield(.expired)
    }

    // MARK: - Private Helpers

    private func persistToken(_ token: AuthToken) async {
        try? await keychainManager.save(token, for: Self.tokenStorageKey)
        if let context = currentContext {
            try? await keychainManager.save(context, for: Self.contextStorageKey)
        }
    }

    private func clearPersistedToken() async {
        try? await keychainManager.delete(for: Self.tokenStorageKey)
        try? await keychainManager.delete(for: Self.contextStorageKey)
    }

    // MARK: - UserDefaults → Keychain Migration

    /// Migrates tokens from UserDefaults to Keychain (one-time).
    /// After successful migration, removes entries from UserDefaults.
    private func migrateFromUserDefaults() async {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        // Migrate token — only remove from UserDefaults after confirmed Keychain write
        if let tokenData = UserDefaults.standard.data(forKey: Self.tokenStorageKey),
           let token = try? decoder.decode(AuthToken.self, from: tokenData) {
            do {
                try await keychainManager.save(token, for: Self.tokenStorageKey)
                UserDefaults.standard.removeObject(forKey: Self.tokenStorageKey)
            } catch {
                // Keep UserDefaults value if Keychain save fails to avoid losing the session.
            }
        }

        // Migrate context — same safe pattern
        if let contextData = UserDefaults.standard.data(forKey: Self.contextStorageKey),
           let context = try? decoder.decode(AuthContext.self, from: contextData) {
            do {
                try await keychainManager.save(context, for: Self.contextStorageKey)
                UserDefaults.standard.removeObject(forKey: Self.contextStorageKey)
            } catch {
                // Keep UserDefaults value if Keychain save fails to avoid losing the context.
            }
        }
    }
}

// MARK: - Session Events

/// Eventos de sesión emitidos por AuthService.
public enum SessionEvent: Sendable, Equatable {
    /// Usuario autenticado exitosamente.
    case loggedIn

    /// Usuario cerró sesión.
    case loggedOut

    /// Sesión expirada (refresh token falló).
    case expired

    /// Contexto activo cambió (rol/escuela).
    case contextSwitched
}
