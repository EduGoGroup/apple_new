import Foundation
import EduFoundation
import EduCore

// MARK: - RefreshTokenInput

/// Input para el caso de uso de refresh token.
///
/// Contiene el refresh token necesario para obtener un nuevo access token.
public struct RefreshTokenInput: Sendable, Equatable {
    /// Token de refresh para renovar el access token
    public let refreshToken: String

    /// Crea un nuevo input para refresh token.
    ///
    /// - Parameter refreshToken: Token de refresh válido
    public init(refreshToken: String) {
        self.refreshToken = refreshToken
    }
}

// MARK: - TokenOutput

/// Output del caso de uso de refresh token.
///
/// Contiene los nuevos tokens generados por el backend.
public struct TokenOutput: Sendable, Equatable {
    /// Nuevo token de acceso (JWT)
    public let accessToken: String

    /// Nuevo token de refresh (rotation de tokens)
    public let refreshToken: String

    /// Crea un nuevo output de tokens.
    ///
    /// - Parameters:
    ///   - accessToken: Nuevo access token
    ///   - refreshToken: Nuevo refresh token
    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}

// MARK: - RefreshTokenUseCase

/// Actor que implementa el caso de uso de refresh token.
///
/// Renueva el access token usando un refresh token válido,
/// implementando el patrón de token rotation para mayor seguridad.
///
/// ## Token Rotation
/// Cuando se refresca un token, el backend genera tanto un nuevo
/// access token como un nuevo refresh token. El refresh token anterior
/// queda invalidado.
///
/// ## Flujo de Ejecución
/// 1. Validar que el refresh token no esté vacío
/// 2. Llamar a AuthRepository.refreshToken()
/// 3. Guardar nuevos tokens atómicamente en TokenRepository
/// 4. Retornar TokenOutput
///
/// ## Atomic Save
/// Los tokens se guardan de forma atómica para evitar estados
/// inconsistentes donde solo un token se guarda correctamente.
///
/// ## Ejemplo de Uso
/// ```swift
/// let refreshUseCase = RefreshTokenUseCase(
///     authRepository: authRepo,
///     tokenRepository: tokenRepo
/// )
///
/// let input = RefreshTokenInput(refreshToken: currentRefreshToken)
///
/// do {
///     let output = try await refreshUseCase.execute(input: input)
///     print("Token renovado exitosamente")
/// } catch let error as UseCaseError {
///     print("Error al renovar token: \(error.localizedDescription)")
///     // Re-autenticar al usuario
/// }
/// ```
public actor RefreshTokenUseCase: UseCase {

    public typealias Input = RefreshTokenInput
    public typealias Output = TokenOutput

    // MARK: - Dependencies

    private let authRepository: AuthRepositoryProtocol
    private let tokenRepository: TokenRepositoryProtocol

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso de refresh token.
    ///
    /// - Parameters:
    ///   - authRepository: Repositorio para operaciones de autenticación
    ///   - tokenRepository: Repositorio para almacenar tokens
    public init(
        authRepository: AuthRepositoryProtocol,
        tokenRepository: TokenRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.tokenRepository = tokenRepository
    }

    // MARK: - UseCase Implementation

    /// Ejecuta el proceso de refresh token.
    ///
    /// - Parameter input: Refresh token a usar para renovación
    /// - Returns: TokenOutput con nuevos tokens
    /// - Throws: `UseCaseError` si falla alguna validación o proceso
    public func execute(input: RefreshTokenInput) async throws -> TokenOutput {
        // PASO 1: Validar que el refresh token no esté vacío
        let trimmedToken = input.refreshToken.trimmingCharacters(in: .whitespaces)
        guard !trimmedToken.isEmpty else {
            throw UseCaseError.preconditionFailed(
                description: "El refresh token no puede estar vacío"
            )
        }

        // PASO 2: Validar longitud mínima del token (tokens JWT típicamente > 100 chars)
        guard trimmedToken.count > 20 else {
            throw UseCaseError.preconditionFailed(
                description: "El refresh token parece inválido (muy corto)"
            )
        }

        // PASO 3: Llamar al backend para refrescar el token
        let (newAccessToken, newRefreshToken): (String, String)
        do {
            (newAccessToken, newRefreshToken) = try await authRepository.refreshToken(trimmedToken)
        } catch let error as RepositoryError {
            // Si el token expiró o es inválido, wrappear el error
            throw UseCaseError.repositoryError(error)
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error inesperado al refrescar token: \(error.localizedDescription)"
            )
        }

        // PASO 4: Guardar nuevos tokens atómicamente
        // Importante: Si falla el guardado, los tokens nuevos se pierden
        // y el usuario deberá re-autenticarse
        do {
            try await tokenRepository.saveTokens(
                accessToken: newAccessToken,
                refreshToken: newRefreshToken
            )
        } catch let error as RepositoryError {
            throw UseCaseError.repositoryError(error)
        } catch {
            throw UseCaseError.executionFailed(
                reason: "Error al guardar nuevos tokens: \(error.localizedDescription)"
            )
        }

        // PASO 5: Retornar nuevos tokens
        return TokenOutput(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken
        )
    }
}
