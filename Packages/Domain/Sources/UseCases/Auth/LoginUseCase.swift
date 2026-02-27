import Foundation
import EduFoundation
import EduCore

// MARK: - LoginInput

/// Input para el caso de uso de login.
///
/// Contiene las credenciales necesarias para autenticar un usuario
/// en el sistema EduGo.
public struct LoginInput: Sendable, Equatable {
    /// Email del usuario (será validado con RFC 5322)
    public let email: String

    /// Contraseña del usuario (mínimo 8 caracteres)
    public let password: String

    /// Crea un nuevo input para login.
    ///
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

// MARK: - LoginOutput

/// Output del caso de uso de login.
///
/// Contiene la información del usuario autenticado y los tokens
/// necesarios para mantener la sesión.
public struct LoginOutput: Sendable, Equatable {
    /// Usuario autenticado
    public let user: User

    /// Token de acceso (JWT) para autenticar requests
    public let accessToken: String

    /// Token de refresh para renovar el access token
    public let refreshToken: String

    /// Crea un nuevo output de login.
    ///
    /// - Parameters:
    ///   - user: Usuario autenticado
    ///   - accessToken: Token de acceso
    ///   - refreshToken: Token de refresh
    public init(user: User, accessToken: String, refreshToken: String) {
        self.user = user
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

// MARK: - AuthRepositoryProtocol

/// Protocolo que define las operaciones de autenticación en el backend.
///
/// Este protocolo abstrae la capa de red para operaciones de auth,
/// permitiendo implementaciones mock para testing.
public protocol AuthRepositoryProtocol: Sendable {
    /// Autentica un usuario con email y contraseña.
    ///
    /// - Parameters:
    ///   - email: Email del usuario
    ///   - password: Contraseña del usuario
    /// - Returns: Tupla con usuario, access token y refresh token
    /// - Throws: `RepositoryError` si falla la autenticación
    func login(email: String, password: String) async throws -> (user: User, accessToken: String, refreshToken: String)

    /// Refresca un access token usando un refresh token.
    ///
    /// - Parameter refreshToken: Token de refresh válido
    /// - Returns: Tupla con nuevo access token y refresh token
    /// - Throws: `RepositoryError` si el token es inválido o expiró
    func refreshToken(_ refreshToken: String) async throws -> (accessToken: String, refreshToken: String)

    /// Cierra la sesión del usuario en el backend.
    ///
    /// - Throws: `RepositoryError` si falla la comunicación (no bloquea logout local)
    func logout() async throws
}

// MARK: - TokenRepositoryProtocol

/// Protocolo para almacenar tokens de autenticación localmente.
public protocol TokenRepositoryProtocol: Sendable {
    /// Guarda los tokens de autenticación.
    ///
    /// - Parameters:
    ///   - accessToken: Token de acceso
    ///   - refreshToken: Token de refresh
    /// - Throws: `RepositoryError` si falla el almacenamiento
    func saveTokens(accessToken: String, refreshToken: String) async throws

    /// Obtiene el access token almacenado.
    ///
    /// - Returns: Access token o nil si no existe
    /// - Throws: `RepositoryError` si falla la lectura
    func getAccessToken() async throws -> String?

    /// Obtiene el refresh token almacenado.
    ///
    /// - Returns: Refresh token o nil si no existe
    /// - Throws: `RepositoryError` si falla la lectura
    func getRefreshToken() async throws -> String?

    /// Elimina todos los tokens almacenados.
    ///
    /// - Throws: `RepositoryError` si falla la eliminación
    func clearTokens() async throws
}

// MARK: - LoginUseCase

/// Actor que implementa el caso de uso de login.
///
/// Coordina la autenticación del usuario validando credenciales,
/// llamando al backend y guardando la información localmente.
///
/// ## Flujo de Ejecución
/// 1. Validar formato de email (RFC 5322)
/// 2. Validar longitud mínima de contraseña (8 caracteres)
/// 3. Llamar a AuthRepository.login()
/// 4. Guardar usuario en UserRepository
/// 5. Guardar tokens en TokenRepository
/// 6. Retornar LoginOutput
///
/// ## Ejemplo de Uso
/// ```swift
/// let loginUseCase = LoginUseCase(
///     authRepository: authRepo,
///     userRepository: userRepo,
///     tokenRepository: tokenRepo
/// )
///
/// let input = LoginInput(
///     email: "user@edugo.com",
///     password: "securePassword123"
/// )
///
/// do {
///     let output = try await loginUseCase.execute(input: input)
///     print("Usuario autenticado: \(output.user.fullName)")
/// } catch let error as UseCaseError {
///     print("Error de login: \(error.localizedDescription)")
/// }
/// ```
public actor LoginUseCase: UseCase {

    public typealias Input = LoginInput
    public typealias Output = LoginOutput

    // MARK: - Dependencies

    private let authRepository: AuthRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private let tokenRepository: TokenRepositoryProtocol

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso de login.
    ///
    /// - Parameters:
    ///   - authRepository: Repositorio para operaciones de autenticación
    ///   - userRepository: Repositorio para gestionar usuarios
    ///   - tokenRepository: Repositorio para almacenar tokens
    public init(
        authRepository: AuthRepositoryProtocol,
        userRepository: UserRepositoryProtocol,
        tokenRepository: TokenRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.tokenRepository = tokenRepository
    }

    // MARK: - UseCase Implementation

    /// Ejecuta el proceso de login.
    ///
    /// - Parameter input: Credenciales del usuario (email y password)
    /// - Returns: LoginOutput con usuario y tokens
    /// - Throws: `UseCaseError` si falla alguna validación o proceso
    public func execute(input: LoginInput) async throws -> LoginOutput {
        // PASO 1: Validar formato de email (RFC 5322)
        do {
            try EmailValidator.validate(input.email)
        } catch {
            throw UseCaseError.preconditionFailed(
                description: "Formato de email inválido"
            )
        }

        // PASO 2: Validar longitud mínima de password
        guard input.password.count >= 8 else {
            throw UseCaseError.preconditionFailed(
                description: "La contraseña debe tener al menos 8 caracteres"
            )
        }

        // PASO 3: Llamar al backend para autenticar
        let (user, accessToken, refreshToken): (User, String, String)
        do {
            (user, accessToken, refreshToken) = try await authRepository.login(
                email: input.email,
                password: input.password
            )
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error inesperado durante la autenticación: \(error.localizedDescription)"
            )
        }

        // PASO 4: Guardar usuario localmente
        do {
            try await userRepository.save(user)
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error al guardar usuario localmente: \(error.localizedDescription)"
            )
        }

        // PASO 5: Guardar tokens localmente
        do {
            try await tokenRepository.saveTokens(
                accessToken: accessToken,
                refreshToken: refreshToken
            )
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error al guardar tokens: \(error.localizedDescription)"
            )
        }

        // PASO 6: Retornar resultado exitoso
        return LoginOutput(
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken
        )
    }
}
