import Foundation
import EduFoundation

/// Protocolo para casos de uso que no requieren input externo.
///
/// Simplifica la implementación de casos de uso que ejecutan operaciones
/// sin parámetros de entrada, como consultas de estado, sincronizaciones
/// automáticas o inicializaciones.
///
/// ## Características
/// - **Sin Input**: `Input` está predefinido como `Void`
/// - **Método Simplificado**: `execute()` sin parámetros
/// - **Sendable**: Conformidad obligatoria para thread-safety
/// - **Actor Isolation**: Diseñado para ejecución segura en contextos concurrentes
///
/// ## Casos de Uso Típicos
/// - Obtener el usuario actualmente autenticado
/// - Sincronizar datos con el servidor
/// - Cargar configuración inicial de la aplicación
/// - Verificar el estado de la sesión
///
/// ## Ejemplo de Implementación
/// ```swift
/// actor GetCurrentUserUseCase: SimpleUseCase {
///     typealias Output = User?
///
///     private let authManager: AuthManager
///     private let userRepository: UserRepositoryProtocol
///
///     init(
///         authManager: AuthManager,
///         userRepository: UserRepositoryProtocol
///     ) {
///         self.authManager = authManager
///         self.userRepository = userRepository
///     }
///
///     func execute() async throws -> User? {
///         guard await authManager.isAuthenticated else {
///             return nil
///         }
///
///         guard let userId = await authManager.currentUserId else {
///             throw UseCaseError.preconditionFailed(
///                 description: "Usuario autenticado sin ID válido"
///             )
///         }
///
///         return try await userRepository.fetch(id: userId)
///     }
/// }
/// ```
///
/// ## Otro Ejemplo: Sincronización
/// ```swift
/// actor SyncPendingChangesUseCase: SimpleUseCase {
///     typealias Output = SyncResult
///
///     private let syncService: SyncService
///
///     init(syncService: SyncService) {
///         self.syncService = syncService
///     }
///
///     func execute() async throws -> SyncResult {
///         let pendingChanges = try await syncService.getPendingChanges()
///
///         guard !pendingChanges.isEmpty else {
///             return SyncResult(syncedCount: 0, status: .noChanges)
///         }
///
///         let syncedCount = try await syncService.sync(changes: pendingChanges)
///         return SyncResult(syncedCount: syncedCount, status: .success)
///     }
/// }
/// ```
///
/// ## Manejo de Errores
/// ```swift
/// actor CheckSessionUseCase: SimpleUseCase {
///     typealias Output = SessionStatus
///
///     func execute() async throws -> SessionStatus {
///         do {
///             let token = try await tokenStorage.getAccessToken()
///             let isValid = try await tokenValidator.validate(token)
///             return isValid ? .valid : .expired
///         } catch let error as RepositoryError {
///             throw UseCaseError.repositoryError(error)
///         }
///     }
/// }
/// ```
public protocol SimpleUseCase: Sendable {
    /// Tipo de salida producido por el caso de uso.
    ///
    /// Debe conformar a `Sendable` para garantizar thread-safety en contextos
    /// concurrentes de Swift 6.0.
    associatedtype Output: Sendable

    /// Ejecuta el caso de uso sin requerir input.
    ///
    /// - Returns: El resultado de la ejecución del caso de uso
    /// - Throws: `UseCaseError` si ocurre un error durante la ejecución
    ///
    /// ## Implementación
    /// Las implementaciones deben:
    /// 1. Obtener estado necesario de dependencias inyectadas
    /// 2. Aplicar lógica de negocio
    /// 3. Retornar resultado o lanzar error apropiado
    ///
    /// ## Ejemplo
    /// ```swift
    /// func execute() async throws -> [Notification] {
    ///     let userId = try await getCurrentUserId()
    ///     return try await notificationRepository.fetchUnread(for: userId)
    /// }
    /// ```
    func execute() async throws -> Output
}

// MARK: - SimpleUseCase Extensions

extension SimpleUseCase {
    /// Ejecuta el caso de uso capturando errores en un `Result`.
    ///
    /// Alternativa funcional al manejo de errores con `try/catch`,
    /// útil para composición de operaciones y pipelines.
    ///
    /// - Returns: `Result` con el output o el error capturado
    ///
    /// ## Ejemplo
    /// ```swift
    /// let result = await getCurrentUserUseCase.executeAsResult()
    /// switch result {
    /// case .success(let user):
    ///     updateUI(with: user)
    /// case .failure(let error):
    ///     showError(error)
    /// }
    /// ```
    public func executeAsResult() async -> Result<Output, Error> {
        do {
            let output = try await execute()
            return .success(output)
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - UseCase Conformance Bridge

/// Extensión que permite usar `SimpleUseCase` donde se espera `UseCase`.
///
/// Proporciona una implementación por defecto de `execute(input:)` que
/// ignora el input y delega a `execute()`.
///
/// ## Ejemplo de Uso
/// ```swift
/// // SimpleUseCase puede usarse en contextos genéricos de UseCase
/// func runAnyUseCase<U: UseCase>(_ useCase: U, input: U.Input) async throws -> U.Output {
///     try await useCase.execute(input: input)
/// }
///
/// // SimpleUseCase funciona pasando Void como input
/// let user = try await runAnyUseCase(getCurrentUserUseCase, input: ())
/// ```
extension SimpleUseCase {
    /// Tipo de entrada para compatibilidad con `UseCase`.
    public typealias Input = Void

    /// Ejecuta el caso de uso ignorando el input.
    ///
    /// Esta implementación permite que `SimpleUseCase` sea usado en contextos
    /// donde se espera un `UseCase` genérico.
    ///
    /// - Parameter input: Ignorado (siempre `Void`)
    /// - Returns: El resultado de `execute()`
    /// - Throws: Cualquier error lanzado por `execute()`
    public func execute(input: Void) async throws -> Output {
        try await execute()
    }
}
