import Foundation
import EduFoundation
import EduCore

// MARK: - SessionRepositoryProtocol

/// Protocolo para gestionar sesiones locales del usuario.
public protocol SessionRepositoryProtocol: Sendable {
    /// Limpia toda la información de sesión local.
    ///
    /// - Throws: `RepositoryError` si falla la limpieza
    func clearSession() async throws
}

// MARK: - LogoutUseCase

/// Actor que implementa el caso de uso de logout.
///
/// Cierra la sesión del usuario tanto en el backend como localmente,
/// limpiando todos los datos de autenticación de forma coordinada.
///
/// ## Patrón All-or-Nothing con Cleanup Paralelo
/// El logout ejecuta las operaciones de limpieza en paralelo usando
/// TaskGroup para mayor eficiencia. Si falla la llamada al backend,
/// el logout local se ejecuta de todas formas.
///
/// ## Flujo de Ejecución
/// 1. Llamar a AuthRepository.logout() (no bloquea si falla)
/// 2. Ejecutar en paralelo:
///    - TokenRepository.clearTokens()
///    - SessionRepository.clearSession()
/// 3. No retorna nada (CommandUseCase pattern)
///
/// ## Manejo de Errores
/// - Error en backend: Se registra pero no bloquea el logout local
/// - Error en limpieza local: Se propaga como UseCaseError
///
/// ## Ejemplo de Uso
/// ```swift
/// let logoutUseCase = LogoutUseCase(
///     authRepository: authRepo,
///     tokenRepository: tokenRepo,
///     sessionRepository: sessionRepo
/// )
///
/// do {
///     try await logoutUseCase.execute()
///     print("Sesión cerrada exitosamente")
/// } catch let error as UseCaseError {
///     print("Error al cerrar sesión: \(error.localizedDescription)")
/// }
/// ```
public actor LogoutUseCase: SimpleUseCase {

    public typealias Output = Void

    // MARK: - Dependencies

    private let authRepository: AuthRepositoryProtocol
    private let tokenRepository: TokenRepositoryProtocol
    private let sessionRepository: SessionRepositoryProtocol

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso de logout.
    ///
    /// - Parameters:
    ///   - authRepository: Repositorio para operaciones de autenticación
    ///   - tokenRepository: Repositorio para gestionar tokens
    ///   - sessionRepository: Repositorio para gestionar sesión local
    public init(
        authRepository: AuthRepositoryProtocol,
        tokenRepository: TokenRepositoryProtocol,
        sessionRepository: SessionRepositoryProtocol
    ) {
        self.authRepository = authRepository
        self.tokenRepository = tokenRepository
        self.sessionRepository = sessionRepository
    }

    // MARK: - SimpleUseCase Implementation

    /// Ejecuta el proceso de logout.
    ///
    /// Cierra la sesión en el backend y limpia todos los datos locales
    /// de forma coordinada. Si falla el backend, la limpieza local
    /// se ejecuta de todas formas.
    ///
    /// - Throws: `UseCaseError` si falla la limpieza local
    public func execute() async throws {
        // PASO 1: Intentar logout en el backend (no bloquea si falla)
        do {
            try await authRepository.logout()
        } catch {
            // Registrar error pero continuar con limpieza local
            // En producción, esto debería enviarse a analytics/logging
            print("⚠️ Advertencia: Logout en backend falló: \(error.localizedDescription)")
        }

        // PASO 2: Ejecutar limpieza local en paralelo
        try await withThrowingTaskGroup(of: Void.self) { group in
            // Tarea 1: Limpiar tokens
            group.addTask {
                do {
                    try await self.tokenRepository.clearTokens()
                } catch let error as RepositoryError {
                    throw UseCaseError.repositoryError(error)
                } catch {
                    throw UseCaseError.executionFailed(
                        reason: "Error al limpiar tokens: \(error.localizedDescription)"
                    )
                }
            }

            // Tarea 2: Limpiar sesión
            group.addTask {
                do {
                    try await self.sessionRepository.clearSession()
                } catch let error as RepositoryError {
                    throw UseCaseError.repositoryError(error)
                } catch {
                    throw UseCaseError.executionFailed(
                        reason: "Error al limpiar sesión: \(error.localizedDescription)"
                    )
                }
            }

            // Esperar a que todas las tareas completen
            // Si alguna falla, se propaga el error
            for try await _ in group {
                // Cada iteración completa una tarea exitosamente
            }
        }

        // PASO 3: Logout completado (implícito - función Void)
    }
}
