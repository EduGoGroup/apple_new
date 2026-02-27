import Foundation

// MARK: - GetStudentDashboardQuery

/// Query para obtener el dashboard completo de un estudiante.
///
/// Esta query encapsula la solicitud de lectura del dashboard y coordina
/// la ejecución a través de su handler, que utiliza el LoadStudentDashboardUseCase
/// internamente con una capa de cache adicional.
///
/// ## Ejemplo de Uso
/// ```swift
/// let query = GetStudentDashboardQuery(
///     userId: studentId,
///     includeProgress: true,
///     forceRefresh: false
/// )
/// let dashboard = try await mediator.send(query)
/// ```
public struct GetStudentDashboardQuery: Query {

    public typealias Result = StudentDashboard

    // MARK: - Properties

    /// ID del estudiante
    public let userId: UUID

    /// Si se debe incluir el resumen de progreso
    public let includeProgress: Bool

    /// Forzar recarga ignorando cache
    public let forceRefresh: Bool

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea una nueva query para cargar el dashboard del estudiante.
    ///
    /// - Parameters:
    ///   - userId: ID del estudiante
    ///   - includeProgress: Si incluir resumen de progreso (default: true)
    ///   - forceRefresh: Forzar recarga desde servidor (default: false)
    ///   - metadata: Metadata opcional para tracing
    public init(
        userId: UUID,
        includeProgress: Bool = true,
        forceRefresh: Bool = false,
        metadata: [String: String]? = nil
    ) {
        self.userId = userId
        self.includeProgress = includeProgress
        self.forceRefresh = forceRefresh
        self.metadata = metadata
    }
}

// MARK: - GetStudentDashboardQueryHandler

/// Handler que procesa GetStudentDashboardQuery usando LoadStudentDashboardUseCase.
///
/// Implementa una capa de cache adicional con TTL configurable (5 minutos por defecto)
/// sobre el use case existente para maximizar la eficiencia en lecturas repetidas.
///
/// ## Estrategia de Cache
/// - **Fresh** (< 5 min): Retorna cache sin revalidar
/// - **Stale** (5-10 min): Retorna cache marcado como stale
/// - **Expired** (> 10 min): Fetch desde use case
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = GetStudentDashboardQueryHandler(useCase: dashboardUseCase)
/// try await mediator.registerQueryHandler(handler)
/// ```
public actor GetStudentDashboardQueryHandler: QueryHandler {

    public typealias QueryType = GetStudentDashboardQuery

    // MARK: - Dependencies

    private let useCase: any LoadStudentDashboardUseCaseProtocol

    // MARK: - Cache

    private var cache: [UUID: CachedDashboard] = [:]
    private let freshTTL: TimeInterval
    private let staleTTL: TimeInterval

    // MARK: - Initialization

    /// Crea un nuevo handler para GetStudentDashboardQuery.
    ///
    /// - Parameters:
    ///   - useCase: Use case que coordina la carga del dashboard
    ///   - freshTTL: TTL para considerar cache fresh en segundos (default: 300)
    ///   - staleTTL: TTL para considerar cache usable en segundos (default: 600)
    public init(
        useCase: any LoadStudentDashboardUseCaseProtocol,
        freshTTL: TimeInterval = 300,
        staleTTL: TimeInterval = 600
    ) {
        self.useCase = useCase
        self.freshTTL = freshTTL
        self.staleTTL = staleTTL
    }

    // MARK: - QueryHandler Implementation

    /// Procesa la query y retorna el dashboard del estudiante.
    ///
    /// - Parameter query: Query con userId y opciones
    /// - Returns: StudentDashboard con toda la información
    /// - Throws: Error si no se puede cargar el dashboard
    public func handle(_ query: GetStudentDashboardQuery) async throws -> StudentDashboard {
        // Si no es forceRefresh, verificar cache
        if !query.forceRefresh {
            if let cached = cache[query.userId] {
                let age = Date().timeIntervalSince(cached.timestamp)

                // Cache fresh: retornar inmediatamente
                if age < freshTTL {
                    return cached.dashboard
                }

                // Cache stale pero usable: retornar y actualizar en background
                if age < staleTTL {
                    Task {
                        await revalidateInBackground(query: query)
                    }
                    return cached.dashboard
                }

                // Cache expirado: continuar con fetch
            }
        }

        // Crear input para el use case
        let input = LoadDashboardInput(
            userId: query.userId,
            includeProgress: query.includeProgress
        )

        // Ejecutar use case
        let dashboard = try await useCase.execute(input: input)

        // Cachear resultado
        cache[query.userId] = CachedDashboard(
            dashboard: dashboard,
            timestamp: Date()
        )

        return dashboard
    }

    // MARK: - Cache Management

    /// Invalida el cache para un usuario específico.
    ///
    /// - Parameter userId: ID del usuario
    public func invalidateCache(for userId: UUID) {
        cache.removeValue(forKey: userId)
    }

    /// Invalida todo el cache.
    public func invalidateAllCache() {
        cache.removeAll()
    }

    // MARK: - Private Methods

    /// Revalida el cache en background sin bloquear.
    private func revalidateInBackground(query: GetStudentDashboardQuery) async {
        do {
            let input = LoadDashboardInput(
                userId: query.userId,
                includeProgress: query.includeProgress
            )
            let dashboard = try await useCase.execute(input: input)

            cache[query.userId] = CachedDashboard(
                dashboard: dashboard,
                timestamp: Date()
            )
        } catch {
            // Silently fail - el usuario ya tiene datos del cache
        }
    }
}

// MARK: - Helper Types

/// Entry de cache con timestamp.
private struct CachedDashboard: Sendable {
    let dashboard: StudentDashboard
    let timestamp: Date
}
