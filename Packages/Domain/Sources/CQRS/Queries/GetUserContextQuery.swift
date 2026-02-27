import Foundation

// MARK: - GetUserContextQuery

/// Query para obtener el contexto completo del usuario autenticado.
///
/// Esta query encapsula la solicitud de lectura del contexto de usuario,
/// que incluye información del usuario, sus memberships, unidades académicas
/// y escuelas asociadas.
///
/// ## Ejemplo de Uso
/// ```swift
/// let query = GetUserContextQuery(forceRefresh: false)
/// let context = try await mediator.send(query)
/// print("Usuario: \(context.user.fullName)")
/// ```
public struct GetUserContextQuery: Query {

    public typealias Result = UserContext

    // MARK: - Properties

    /// Forzar recarga ignorando cache
    public let forceRefresh: Bool

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea una nueva query para cargar el contexto del usuario.
    ///
    /// - Parameters:
    ///   - forceRefresh: Forzar recarga desde servidor (default: false)
    ///   - metadata: Metadata opcional para tracing
    public init(
        forceRefresh: Bool = false,
        metadata: [String: String]? = nil
    ) {
        self.forceRefresh = forceRefresh
        self.metadata = metadata
    }
}

// MARK: - GetUserContextQueryHandler

/// Handler que procesa GetUserContextQuery usando LoadUserContextUseCase.
///
/// Implementa cache agresivo con scope de sesión para minimizar llamadas
/// al backend, ya que el contexto de usuario cambia muy raramente durante
/// una sesión activa.
///
/// ## Estrategia de Cache
/// - **Session-scoped**: Cache válido durante toda la sesión (30 minutos)
/// - **Agresivo**: No revalida automáticamente, solo con forceRefresh o invalidación explícita
/// - **Invalidación manual**: Debe invalidarse en logout o cambio de contexto
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = GetUserContextQueryHandler(useCase: contextUseCase)
/// try await mediator.registerQueryHandler(handler)
///
/// // En logout
/// await handler.invalidateCache()
/// ```
public actor GetUserContextQueryHandler: QueryHandler {

    public typealias QueryType = GetUserContextQuery

    // MARK: - Dependencies

    private let useCase: any LoadUserContextUseCaseProtocol

    // MARK: - Cache

    private var cachedContext: UserContext?
    private var cacheTimestamp: Date?
    private let sessionTTL: TimeInterval

    // MARK: - Initialization

    /// Crea un nuevo handler para GetUserContextQuery.
    ///
    /// - Parameters:
    ///   - useCase: Use case que coordina la carga del contexto
    ///   - sessionTTL: TTL de sesión en segundos (default: 1800 = 30 min)
    public init(
        useCase: any LoadUserContextUseCaseProtocol,
        sessionTTL: TimeInterval = 1800
    ) {
        self.useCase = useCase
        self.sessionTTL = sessionTTL
    }

    // MARK: - QueryHandler Implementation

    /// Procesa la query y retorna el contexto del usuario.
    ///
    /// - Parameter query: Query con opciones de refresh
    /// - Returns: UserContext con toda la información del usuario
    /// - Throws: Error si no se puede cargar el contexto
    public func handle(_ query: GetUserContextQuery) async throws -> UserContext {
        // Si no es forceRefresh, verificar cache de sesión
        if !query.forceRefresh {
            if let cached = cachedContext,
               let timestamp = cacheTimestamp {
                let age = Date().timeIntervalSince(timestamp)

                // Cache válido durante toda la sesión
                if age < sessionTTL {
                    return cached
                }
            }
        }

        // Ejecutar use case (no recibe input)
        let context = try await useCase.execute()

        // Cachear resultado con timestamp de sesión
        cachedContext = context
        cacheTimestamp = Date()

        return context
    }

    // MARK: - Cache Management

    /// Invalida el cache de contexto (útil en logout o cambio de escuela).
    public func invalidateCache() {
        cachedContext = nil
        cacheTimestamp = nil
    }

    /// Indica si hay un contexto cacheado válido.
    public var hasCachedContext: Bool {
        guard let timestamp = cacheTimestamp else { return false }
        let age = Date().timeIntervalSince(timestamp)
        return age < sessionTTL && cachedContext != nil
    }

    /// Tiempo en segundos desde la última actualización del cache.
    public var cacheAge: TimeInterval? {
        guard let timestamp = cacheTimestamp else { return nil }
        return Date().timeIntervalSince(timestamp)
    }
}
