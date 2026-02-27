/// UseCases - Protocolos base para casos de uso del sistema EduGo.
///
/// Este módulo define los protocolos fundamentales para implementar la capa
/// de aplicación siguiendo Clean Architecture. Los casos de uso coordinan
/// la lógica de negocio entre entidades de dominio y repositorios.
///
/// ## Protocolos Disponibles
///
/// ### UseCase
/// Protocolo genérico base con associated types `Input` y `Output`:
/// ```swift
/// actor FetchUserUseCase: UseCase {
///     typealias Input = FetchUserRequest
///     typealias Output = User
///
///     func execute(input: FetchUserRequest) async throws -> User {
///         try await userRepository.fetch(id: input.userId)
///     }
/// }
/// ```
///
/// ### SimpleUseCase
/// Para casos de uso sin input (consultas sin parámetros):
/// ```swift
/// actor GetCurrentUserUseCase: SimpleUseCase {
///     typealias Output = User?
///
///     func execute() async throws -> User? {
///         guard let userId = await authManager.currentUserId else {
///             return nil
///         }
///         return try await userRepository.fetch(id: userId)
///     }
/// }
/// ```
///
/// ### CommandUseCase
/// Para operaciones fire-and-forget sin output:
/// ```swift
/// actor LogoutUseCase: CommandUseCase {
///     typealias Input = LogoutRequest
///
///     func execute(input: LogoutRequest) async throws {
///         try await tokenStorage.clearAll()
///         await authManager.setLoggedOut()
///     }
/// }
/// ```
///
/// ## Concurrencia y Thread-Safety
///
/// Todos los protocolos requieren conformidad a `Sendable` y están diseñados
/// para uso con Swift 6.0 Strict Concurrency. Se recomienda implementar
/// casos de uso como `actor` para garantizar thread-safety:
///
/// ```swift
/// actor MyConcurrentUseCase: UseCase {
///     private var cache: [String: Output] = [:] // Estado mutable seguro
///
///     func execute(input: Input) async throws -> Output {
///         // Acceso seguro al estado
///     }
/// }
/// ```
///
/// ## Manejo de Errores
///
/// Los casos de uso deben propagar errores usando `UseCaseError`:
/// ```swift
/// func execute(input: Input) async throws -> Output {
///     do {
///         return try await repository.fetch(id: input.id)
///     } catch let error as RepositoryError {
///         throw UseCaseError.repositoryError(error)
///     } catch let error as DomainError {
///         throw UseCaseError.domainError(error)
///     }
/// }
/// ```
///
/// ## Dependencias
/// - `EduGoCommon`: Proporciona `UseCaseError`, `DomainError`, `RepositoryError`
/// - `Models`: Proporciona protocolos de repositorio y modelos de dominio

// Re-export de tipos de error para conveniencia
@_exported import EduFoundation

// MARK: - Base Protocols

// Los protocolos base están en el directorio Base/:
// - UseCase.swift: Protocolo genérico con Input/Output
// - SimpleUseCase.swift: Para casos sin input
// - CommandUseCase.swift: Para comandos sin output
