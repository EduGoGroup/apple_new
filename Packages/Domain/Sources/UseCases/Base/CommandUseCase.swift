import Foundation
import EduFoundation

/// Protocolo para casos de uso de tipo comando sin output.
///
/// Simplifica la implementación de operaciones "fire-and-forget" que
/// ejecutan una acción sin retornar un resultado, como actualizaciones,
/// eliminaciones o notificaciones.
///
/// ## Características
/// - **Sin Output**: `Output` está predefinido como `Void`
/// - **Método Simplificado**: `execute(input:)` sin retorno
/// - **Sendable**: Conformidad obligatoria para thread-safety
/// - **Actor Isolation**: Diseñado para ejecución segura en contextos concurrentes
///
/// ## Casos de Uso Típicos
/// - Actualizar preferencias de usuario
/// - Eliminar un recurso
/// - Enviar una notificación
/// - Marcar elementos como leídos
/// - Cerrar sesión
///
/// ## Ejemplo de Implementación
/// ```swift
/// actor UpdateUserPreferencesUseCase: CommandUseCase {
///     typealias Input = UserPreferences
///
///     private let preferencesRepository: PreferencesRepositoryProtocol
///
///     init(preferencesRepository: PreferencesRepositoryProtocol) {
///         self.preferencesRepository = preferencesRepository
///     }
///
///     func execute(input: UserPreferences) async throws {
///         // Validar preferencias
///         guard input.isValid else {
///             throw UseCaseError.preconditionFailed(
///                 description: "Las preferencias contienen valores inválidos"
///             )
///         }
///
///         // Persistir cambios
///         try await preferencesRepository.save(input)
///     }
/// }
/// ```
///
/// ## Ejemplo: Eliminar Recurso
/// ```swift
/// actor DeleteDocumentUseCase: CommandUseCase {
///     typealias Input = DeleteDocumentRequest
///
///     private let documentRepository: DocumentRepositoryProtocol
///     private let authManager: AuthManager
///
///     init(
///         documentRepository: DocumentRepositoryProtocol,
///         authManager: AuthManager
///     ) {
///         self.documentRepository = documentRepository
///         self.authManager = authManager
///     }
///
///     func execute(input: DeleteDocumentRequest) async throws {
///         // Verificar autorización
///         guard await authManager.hasPermission(.deleteDocuments) else {
///             throw UseCaseError.unauthorized(
///                 action: "Eliminar documentos"
///             )
///         }
///
///         // Verificar que el documento existe
///         let document = try await documentRepository.fetch(id: input.documentId)
///
///         // Verificar propiedad
///         guard document.ownerId == await authManager.currentUserId else {
///             throw UseCaseError.unauthorized(
///                 action: "Eliminar documentos de otros usuarios"
///             )
///         }
///
///         // Ejecutar eliminación
///         try await documentRepository.delete(id: input.documentId)
///     }
/// }
/// ```
///
/// ## Ejemplo: Logout
/// ```swift
/// actor LogoutUseCase: CommandUseCase {
///     typealias Input = LogoutRequest
///
///     private let authManager: AuthManager
///     private let tokenStorage: TokenStorage
///     private let analyticsService: AnalyticsService
///
///     func execute(input: LogoutRequest) async throws {
///         // Registrar evento de analytics
///         await analyticsService.track(.logout(reason: input.reason))
///
///         // Limpiar tokens
///         try await tokenStorage.clearAll()
///
///         // Actualizar estado de autenticación
///         await authManager.setLoggedOut()
///     }
/// }
/// ```
///
/// ## Manejo de Errores
/// ```swift
/// actor MarkNotificationsReadUseCase: CommandUseCase {
///     typealias Input = [NotificationId]
///
///     func execute(input: [NotificationId]) async throws {
///         guard !input.isEmpty else {
///             throw UseCaseError.preconditionFailed(
///                 description: "Debe proporcionar al menos una notificación"
///             )
///         }
///
///         do {
///             try await notificationRepository.markAsRead(ids: input)
///         } catch let error as RepositoryError {
///             throw UseCaseError.repositoryError(error)
///         }
///     }
/// }
/// ```
public protocol CommandUseCase: Sendable {
    /// Tipo de entrada requerido para ejecutar el comando.
    ///
    /// Debe conformar a `Sendable` para garantizar thread-safety en contextos
    /// concurrentes de Swift 6.0.
    associatedtype Input: Sendable

    /// Ejecuta el comando con el input proporcionado.
    ///
    /// - Parameter input: Los datos de entrada necesarios para la ejecución
    /// - Throws: `UseCaseError` si ocurre un error durante la ejecución
    ///
    /// ## Implementación
    /// Las implementaciones deben:
    /// 1. Validar precondiciones y autorización
    /// 2. Ejecutar la operación de manera idempotente cuando sea posible
    /// 3. Propagar errores como `UseCaseError`
    ///
    /// ## Ejemplo
    /// ```swift
    /// func execute(input: DeleteRequest) async throws {
    ///     guard !input.resourceId.isEmpty else {
    ///         throw UseCaseError.preconditionFailed(
    ///             description: "El ID del recurso es requerido"
    ///         )
    ///     }
    ///     try await repository.delete(id: input.resourceId)
    /// }
    /// ```
    func execute(input: Input) async throws
}

// MARK: - CommandUseCase Extensions

extension CommandUseCase {
    /// Ejecuta el comando capturando errores en un `Result`.
    ///
    /// Alternativa funcional al manejo de errores con `try/catch`,
    /// útil para composición de operaciones y pipelines.
    ///
    /// - Parameter input: Los datos de entrada necesarios para la ejecución
    /// - Returns: `Result` indicando éxito o el error capturado
    ///
    /// ## Ejemplo
    /// ```swift
    /// let result = await deleteDocumentUseCase.executeAsResult(input: request)
    /// switch result {
    /// case .success:
    ///     showSuccessMessage("Documento eliminado")
    /// case .failure(let error):
    ///     showError(error)
    /// }
    /// ```
    public func executeAsResult(input: Input) async -> Result<Void, Error> {
        do {
            try await execute(input: input)
            return .success(())
        } catch {
            return .failure(error)
        }
    }
}

// MARK: - UseCase Conformance Bridge

/// Extensión que permite usar `CommandUseCase` donde se espera `UseCase`.
///
/// Proporciona una implementación por defecto que retorna `Void` como output,
/// permitiendo interoperabilidad con código genérico.
///
/// ## Ejemplo de Uso
/// ```swift
/// // CommandUseCase puede usarse en contextos genéricos de UseCase
/// func runAnyUseCase<U: UseCase>(_ useCase: U, input: U.Input) async throws -> U.Output {
///     try await useCase.execute(input: input)
/// }
///
/// // CommandUseCase retorna Void
/// _ = try await runAnyUseCase(deleteUseCase, input: deleteRequest)
/// ```
extension CommandUseCase {
    /// Tipo de salida para compatibilidad con `UseCase`.
    public typealias Output = Void

    /// Ejecuta el comando y retorna `Void` para compatibilidad con `UseCase`.
    ///
    /// - Parameter input: Los datos de entrada para el comando
    /// - Returns: `Void` (implícito)
    /// - Throws: Cualquier error lanzado por `execute(input:)`
    public func executeAsUseCase(input: Input) async throws -> Void {
        try await execute(input: input)
    }
}
