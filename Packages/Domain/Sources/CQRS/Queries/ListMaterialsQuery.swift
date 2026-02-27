import Foundation

// MARK: - ListMaterialsQuery

/// Query para listar materiales con filtros, paginación y ordenamiento.
///
/// Esta query encapsula todas las opciones de listado de materiales,
/// incluyendo filtros avanzados, paginación cursor-based y soporte
/// para infinite scroll.
///
/// ## Ejemplo de Uso Básico
/// ```swift
/// // Primera página con filtro
/// let query = ListMaterialsQuery(
///     filters: MaterialFilters(subjectId: mathId),
///     sortBy: .createdAt,
///     sortOrder: .descending
/// )
/// let page = try await mediator.send(query)
///
/// // Siguiente página
/// if page.hasMore {
///     let nextQuery = ListMaterialsQuery(
///         filters: query.filters,
///         pagination: CursorPagination(cursor: page.nextCursor),
///         sortBy: query.sortBy,
///         sortOrder: query.sortOrder
///     )
///     let nextPage = try await mediator.send(nextQuery)
/// }
/// ```
///
/// ## Ejemplo de Búsqueda
/// ```swift
/// let searchQuery = ListMaterialsQuery(
///     filters: MaterialFilters(searchQuery: "matemáticas"),
///     limit: 20
/// )
/// let results = try await mediator.send(searchQuery)
/// ```
public struct ListMaterialsQuery: Query {

    public typealias Result = MaterialsPage

    // MARK: - Properties

    /// Filtros a aplicar
    public let filters: MaterialFilters

    /// Configuración de paginación
    public let pagination: CursorPagination

    /// Campo de ordenamiento
    public let sortBy: MaterialSortOption

    /// Dirección del orden
    public let sortOrder: MaterialSortDirection

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea una nueva query para listar materiales.
    ///
    /// - Parameters:
    ///   - filters: Filtros a aplicar (default: .none)
    ///   - pagination: Configuración de paginación (default: .firstPage)
    ///   - sortBy: Campo de ordenamiento (default: .createdAt)
    ///   - sortOrder: Dirección del orden (default: .descending)
    ///   - metadata: Metadata opcional para tracing
    public init(
        filters: MaterialFilters = .none,
        pagination: CursorPagination = .firstPage,
        sortBy: MaterialSortOption = .createdAt,
        sortOrder: MaterialSortDirection = .descending,
        metadata: [String: String]? = nil
    ) {
        self.filters = filters
        self.pagination = pagination
        self.sortBy = sortBy
        self.sortOrder = sortOrder
        self.metadata = metadata
    }

    // MARK: - Convenience Initializers

    /// Crea una query para la primera página con límite específico.
    ///
    /// - Parameters:
    ///   - filters: Filtros a aplicar
    ///   - limit: Número de items por página
    ///   - sortBy: Campo de ordenamiento
    ///   - sortOrder: Dirección del orden
    public init(
        filters: MaterialFilters = .none,
        limit: Int,
        sortBy: MaterialSortOption = .createdAt,
        sortOrder: MaterialSortDirection = .descending
    ) {
        self.init(
            filters: filters,
            pagination: CursorPagination(cursor: nil, limit: limit),
            sortBy: sortBy,
            sortOrder: sortOrder,
            metadata: [String: String]?.none
        )
    }
}

// MARK: - ListMaterialsQueryHandler

/// Handler que procesa ListMaterialsQuery usando ListMaterialsUseCase.
///
/// Actúa como adaptador entre la capa CQRS y el use case de dominio,
/// delegando toda la lógica de paginación, filtrado y cache al use case.
///
/// ## Características Heredadas del UseCase
/// - Paginación cursor-based eficiente
/// - Cache LRU con TTL de 5 minutos
/// - Soporte para infinite scroll con deduplicación
/// - Graceful degradation con stale cache
///
/// ## Integración con Read Model
/// El use case pre-calcula índices y paginación en el read model,
/// optimizando las queries repetidas y reduciendo la carga del backend.
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = ListMaterialsQueryHandler(useCase: listMaterialsUseCase)
/// try await mediator.registerQueryHandler(handler)
/// ```
public actor ListMaterialsQueryHandler: QueryHandler {

    public typealias QueryType = ListMaterialsQuery

    // MARK: - Dependencies

    private let useCase: any ListMaterialsUseCaseProtocol

    // MARK: - Initialization

    /// Crea un nuevo handler para ListMaterialsQuery.
    ///
    /// - Parameter useCase: Use case que coordina el listado de materiales
    public init(useCase: any ListMaterialsUseCaseProtocol) {
        self.useCase = useCase
    }

    // MARK: - QueryHandler Implementation

    /// Procesa la query y retorna una página de materiales.
    ///
    /// - Parameter query: Query con filtros, paginación y ordenamiento
    /// - Returns: MaterialsPage con items y metadata de paginación
    /// - Throws: Error si no se pueden cargar los materiales
    public func handle(_ query: ListMaterialsQuery) async throws -> MaterialsPage {
        // Crear input para el use case
        let input = ListMaterialsInput(
            filters: query.filters,
            pagination: query.pagination,
            sortBy: query.sortBy,
            sortOrder: query.sortOrder
        )

        // Ejecutar use case
        let page = try await useCase.execute(input: input)

        return page
    }

    // MARK: - Cache Management

    /// Invalida todo el cache del handler.
    ///
    /// Útil cuando se crea/actualiza/elimina un material y se necesita
    /// refrescar todas las listas.
    ///
    /// NOTA: Para usar esto con protocolos, el UseCase concreto debe
    /// exponerse o usar un protocolo extendido con invalidación.
    public func invalidateCache() async {
        // Si el useCase es el concreto, podemos usar type-casting
        if let concreteUseCase = useCase as? ListMaterialsUseCase {
            await concreteUseCase.invalidateCache()
        }
    }

    /// Invalida cache que contenga un material específico.
    ///
    /// - Parameter materialId: ID del material modificado
    public func invalidateCache(for materialId: UUID) async {
        if let concreteUseCase = useCase as? ListMaterialsUseCase {
            await concreteUseCase.invalidateCache(for: materialId)
        }
    }
}
