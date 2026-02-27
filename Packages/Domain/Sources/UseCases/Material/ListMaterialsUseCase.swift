import Foundation
import EduFoundation
import EduCore

// MARK: - Input Types

/// Filtros para listar materiales.
public struct MaterialFilters: Sendable, Equatable, Hashable {
    /// Filtrar por ID de materia
    public let subjectId: UUID?
    /// Filtrar por ID de unidad académica
    public let unitId: UUID?
    /// Filtrar por tipo de material
    public let type: MaterialType?
    /// Filtrar por estado
    public let status: MaterialStatus?
    /// Búsqueda por texto
    public let searchQuery: String?

    public init(
        subjectId: UUID? = nil,
        unitId: UUID? = nil,
        type: MaterialType? = nil,
        status: MaterialStatus? = nil,
        searchQuery: String? = nil
    ) {
        self.subjectId = subjectId
        self.unitId = unitId
        self.type = type
        self.status = status
        self.searchQuery = searchQuery
    }

    /// Filtros vacíos (sin filtrado).
    public static let none = MaterialFilters()
}

// MaterialType está definido en StateManagement/StateMachines/DashboardState.swift

/// Paginación basada en cursor.
public struct CursorPagination: Sendable, Equatable, Hashable {
    /// Cursor para la siguiente página (nil para primera página)
    public let cursor: String?
    /// Número de items por página (máximo 100)
    public let limit: Int

    public init(cursor: String? = nil, limit: Int = 20) {
        self.cursor = cursor
        self.limit = min(max(limit, 1), 100)
    }

    /// Primera página con límite por defecto.
    public static let firstPage = CursorPagination()
}

/// Opciones de ordenamiento para materiales.
public enum MaterialSortOption: String, Sendable, Equatable, Hashable, Codable {
    case createdAt = "created_at"
    case title = "title"
    case updatedAt = "updated_at"
}

/// Orden de clasificación.
public enum MaterialSortDirection: String, Sendable, Equatable, Hashable, Codable {
    case ascending = "asc"
    case descending = "desc"
}

/// Input para listar materiales.
public struct ListMaterialsInput: Sendable, Equatable, Hashable {
    /// Filtros a aplicar
    public let filters: MaterialFilters
    /// Configuración de paginación
    public let pagination: CursorPagination
    /// Campo de ordenamiento
    public let sortBy: MaterialSortOption
    /// Dirección del orden
    public let sortOrder: MaterialSortDirection

    public init(
        filters: MaterialFilters = .none,
        pagination: CursorPagination = .firstPage,
        sortBy: MaterialSortOption = .createdAt,
        sortOrder: MaterialSortDirection = .descending
    ) {
        self.filters = filters
        self.pagination = pagination
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
}

// MARK: - Output Types

/// Página de materiales con metadata de paginación.
public struct MaterialsPage: Sendable, Equatable {
    /// Materiales en esta página
    public let items: [Material]
    /// Cursor para la siguiente página (nil si no hay más)
    public let nextCursor: String?
    /// Total de materiales (si el backend lo provee)
    public let totalCount: Int?
    /// Indica si hay más páginas disponibles
    public let hasMore: Bool
    /// Indica si los datos vienen de cache
    public let isStale: Bool

    public init(
        items: [Material],
        nextCursor: String?,
        totalCount: Int? = nil,
        hasMore: Bool,
        isStale: Bool = false
    ) {
        self.items = items
        self.nextCursor = nextCursor
        self.totalCount = totalCount
        self.hasMore = hasMore
        self.isStale = isStale
    }

    /// Página vacía.
    public static let empty = MaterialsPage(
        items: [],
        nextCursor: nil,
        totalCount: 0,
        hasMore: false
    )
}

/// Resultado acumulado para infinite scroll.
public struct AccumulatedMaterials: Sendable, Equatable {
    /// Todos los materiales cargados
    public let items: [Material]
    /// Cursor para cargar más
    public let nextCursor: String?
    /// Si hay más páginas
    public let hasMore: Bool
    /// Número de páginas cargadas
    public let pagesLoaded: Int

    public init(
        items: [Material],
        nextCursor: String?,
        hasMore: Bool,
        pagesLoaded: Int
    ) {
        self.items = items
        self.nextCursor = nextCursor
        self.hasMore = hasMore
        self.pagesLoaded = pagesLoaded
    }
}

// MARK: - Repository Protocol

/// Query para el repositorio de materiales.
public struct MaterialsQuery: Sendable, Equatable {
    public let subjectId: UUID?
    public let unitId: UUID?
    public let type: String?
    public let status: String?
    public let searchQuery: String?
    public let cursor: String?
    public let limit: Int
    public let sortBy: String
    public let sortOrder: String

    public init(
        subjectId: UUID? = nil,
        unitId: UUID? = nil,
        type: String? = nil,
        status: String? = nil,
        searchQuery: String? = nil,
        cursor: String? = nil,
        limit: Int = 20,
        sortBy: String = "created_at",
        sortOrder: String = "desc"
    ) {
        self.subjectId = subjectId
        self.unitId = unitId
        self.type = type
        self.status = status
        self.searchQuery = searchQuery
        self.cursor = cursor
        self.limit = limit
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }
}

/// Respuesta del repositorio con metadata de paginación.
public struct MaterialsRepositoryResponse: Sendable, Equatable {
    public let materials: [Material]
    public let nextCursor: String?
    public let totalCount: Int?

    public init(
        materials: [Material],
        nextCursor: String?,
        totalCount: Int? = nil
    ) {
        self.materials = materials
        self.nextCursor = nextCursor
        self.totalCount = totalCount
    }
}

/// Protocolo del repositorio de materiales para listado.
public protocol ListMaterialsRepositoryProtocol: Sendable {
    /// Lista materiales con query de paginación y filtros.
    func list(query: MaterialsQuery) async throws -> MaterialsRepositoryResponse
}

// MARK: - Cache Service

/// Entry de cache con timestamp.
private struct CacheEntry<T: Sendable>: Sendable {
    let value: T
    let timestamp: Date
    let key: String
}

/// Servicio de cache en memoria con LRU eviction.
public actor MaterialsCacheService {
    private var cache: [String: CacheEntry<MaterialsPage>] = [:]
    private var accessOrder: [String] = []
    private let maxEntries: Int
    private let ttlSeconds: TimeInterval

    public init(maxEntries: Int = 20, ttlSeconds: TimeInterval = 300) {
        self.maxEntries = maxEntries
        self.ttlSeconds = ttlSeconds
    }

    /// Obtiene una página del cache si existe y no expiró.
    public func get(key: String) -> MaterialsPage? {
        guard let entry = cache[key] else { return nil }

        // Verificar TTL
        if Date().timeIntervalSince(entry.timestamp) > ttlSeconds {
            cache.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
            return nil
        }

        // Actualizar orden de acceso (LRU)
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)

        return entry.value
    }

    /// Obtiene una página del cache incluso si expiró (para stale-while-revalidate).
    public func getStale(key: String) -> MaterialsPage? {
        guard let entry = cache[key] else { return nil }

        let isStale = Date().timeIntervalSince(entry.timestamp) > ttlSeconds
        if isStale {
            // Retornar con flag de stale
            return MaterialsPage(
                items: entry.value.items,
                nextCursor: entry.value.nextCursor,
                totalCount: entry.value.totalCount,
                hasMore: entry.value.hasMore,
                isStale: true
            )
        }

        return entry.value
    }

    /// Guarda una página en cache.
    public func set(key: String, page: MaterialsPage) {
        // Eviction LRU si está lleno
        while cache.count >= maxEntries, let oldest = accessOrder.first {
            cache.removeValue(forKey: oldest)
            accessOrder.removeFirst()
        }

        cache[key] = CacheEntry(value: page, timestamp: Date(), key: key)
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
    }

    /// Invalida todo el cache.
    public func invalidateAll() {
        cache.removeAll()
        accessOrder.removeAll()
    }

    /// Invalida entries que contengan cierto material ID.
    public func invalidate(containing materialId: UUID) {
        let keysToRemove = cache.keys.filter { key in
            cache[key]?.value.items.contains { $0.id == materialId } ?? false
        }

        for key in keysToRemove {
            cache.removeValue(forKey: key)
            accessOrder.removeAll { $0 == key }
        }
    }

    /// Número de entries en cache.
    public var count: Int {
        cache.count
    }
}

// MARK: - ListMaterialsUseCase

/// Actor que coordina la carga eficiente de materiales con paginación y filtros.
///
/// Implementa:
/// - Paginación cursor-based
/// - Filtros avanzados (materia, unidad, tipo, estado, búsqueda)
/// - Cache inteligente con LRU eviction
/// - Soporte para infinite scroll con deduplicación
/// - Graceful degradation con stale cache
///
/// ## Ejemplo de Uso Básico
/// ```swift
/// let useCase = ListMaterialsUseCase(repository: repo)
///
/// // Primera página
/// let input = ListMaterialsInput(
///     filters: MaterialFilters(subjectId: mathId),
///     sortBy: .createdAt,
///     sortOrder: .descending
/// )
/// let page = try await useCase.execute(input: input)
///
/// // Siguiente página
/// if page.hasMore {
///     let nextInput = ListMaterialsInput(
///         filters: input.filters,
///         pagination: CursorPagination(cursor: page.nextCursor),
///         sortBy: input.sortBy,
///         sortOrder: input.sortOrder
///     )
///     let nextPage = try await useCase.execute(input: nextInput)
/// }
/// ```
///
/// ## Infinite Scroll
/// ```swift
/// // Cargar primera página
/// let materials = try await useCase.loadInitial(input: input)
///
/// // Cargar más cuando usuario hace scroll
/// if await useCase.canLoadMore {
///     let updated = try await useCase.loadMore()
/// }
/// ```
public actor ListMaterialsUseCase: UseCase {

    public typealias Input = ListMaterialsInput
    public typealias Output = MaterialsPage

    // MARK: - Dependencies

    private let repository: ListMaterialsRepositoryProtocol
    private let cache: MaterialsCacheService

    // MARK: - Infinite Scroll State

    private var currentInput: ListMaterialsInput?
    private var accumulatedItems: [Material] = []
    private var loadedMaterialIds: Set<UUID> = []
    private var nextCursor: String?
    private var pagesLoaded: Int = 0

    // MARK: - Configuration

    private let maxLimit = 100

    // MARK: - Initialization

    /// Crea una nueva instancia del caso de uso.
    ///
    /// - Parameters:
    ///   - repository: Repositorio de materiales
    ///   - cache: Servicio de cache (opcional, se crea uno por defecto)
    public init(
        repository: ListMaterialsRepositoryProtocol,
        cache: MaterialsCacheService? = nil
    ) {
        self.repository = repository
        self.cache = cache ?? MaterialsCacheService()
    }

    // MARK: - UseCase Implementation

    /// Ejecuta la carga de una página de materiales.
    ///
    /// - Parameter input: Configuración de filtros, paginación y ordenamiento
    /// - Returns: Página de materiales
    public func execute(input: ListMaterialsInput) async throws -> MaterialsPage {
        // Validar input
        try validateInput(input)

        // Generar cache key
        let cacheKey = generateCacheKey(for: input)

        // Intentar obtener del cache
        if let cached = await cache.get(key: cacheKey) {
            return cached
        }

        // Build query
        let query = buildQuery(from: input)

        do {
            // Fetch del repositorio
            let response = try await repository.list(query: query)

            // Crear página de resultado
            let page = MaterialsPage(
                items: response.materials,
                nextCursor: response.nextCursor,
                totalCount: response.totalCount,
                hasMore: response.nextCursor != nil
            )

            // Cachear resultado
            await cache.set(key: cacheKey, page: page)

            return page

        } catch {
            // Intentar retornar cache stale si existe
            if let stale = await cache.getStale(key: cacheKey) {
                return stale
            }

            throw error
        }
    }

    // MARK: - Infinite Scroll API

    /// Indica si hay más páginas para cargar.
    public var canLoadMore: Bool {
        nextCursor != nil
    }

    /// Materiales acumulados del infinite scroll.
    public var accumulated: AccumulatedMaterials {
        AccumulatedMaterials(
            items: accumulatedItems,
            nextCursor: nextCursor,
            hasMore: nextCursor != nil,
            pagesLoaded: pagesLoaded
        )
    }

    /// Carga la primera página e inicializa el estado de infinite scroll.
    ///
    /// - Parameter input: Configuración inicial
    /// - Returns: Materiales acumulados
    public func loadInitial(input: ListMaterialsInput) async throws -> AccumulatedMaterials {
        // Reset estado
        resetScrollState()
        currentInput = input

        // Cargar primera página
        let page = try await execute(input: input)

        // Acumular resultados
        appendItems(page.items)
        nextCursor = page.nextCursor
        pagesLoaded = 1

        return accumulated
    }

    /// Carga la siguiente página y acumula resultados.
    ///
    /// - Returns: Materiales acumulados actualizados
    /// - Throws: Error si no hay más páginas o no se ha inicializado
    public func loadMore() async throws -> AccumulatedMaterials {
        guard let input = currentInput else {
            throw UseCaseError.preconditionFailed(
                description: "Debe llamar loadInitial primero"
            )
        }

        guard let cursor = nextCursor else {
            throw UseCaseError.preconditionFailed(
                description: "No hay más páginas para cargar"
            )
        }

        // Crear input para siguiente página
        let nextInput = ListMaterialsInput(
            filters: input.filters,
            pagination: CursorPagination(cursor: cursor, limit: input.pagination.limit),
            sortBy: input.sortBy,
            sortOrder: input.sortOrder
        )

        // Cargar página
        let page = try await execute(input: nextInput)

        // Acumular con deduplicación
        appendItems(page.items)
        nextCursor = page.nextCursor
        pagesLoaded += 1

        return accumulated
    }

    /// Reinicia el estado del infinite scroll.
    public func resetScrollState() {
        currentInput = nil
        accumulatedItems = []
        loadedMaterialIds = []
        nextCursor = nil
        pagesLoaded = 0
    }

    /// Recarga desde el principio manteniendo los filtros actuales.
    public func refresh() async throws -> AccumulatedMaterials {
        guard let input = currentInput else {
            throw UseCaseError.preconditionFailed(
                description: "No hay configuración para refrescar"
            )
        }

        // Invalidar cache relacionado
        await cache.invalidateAll()

        // Recargar
        return try await loadInitial(input: input)
    }

    // MARK: - Cache Management

    /// Invalida todo el cache.
    public func invalidateCache() async {
        await cache.invalidateAll()
    }

    /// Invalida cache que contenga un material específico.
    public func invalidateCache(for materialId: UUID) async {
        await cache.invalidate(containing: materialId)

        // También remover del estado acumulado
        accumulatedItems.removeAll { $0.id == materialId }
        loadedMaterialIds.remove(materialId)
    }

    // MARK: - Private Methods

    /// Valida el input.
    private func validateInput(_ input: ListMaterialsInput) throws {
        if input.pagination.limit > maxLimit {
            throw UseCaseError.preconditionFailed(
                description: "El límite máximo es \(maxLimit)"
            )
        }

        if input.pagination.limit < 1 {
            throw UseCaseError.preconditionFailed(
                description: "El límite mínimo es 1"
            )
        }
    }

    /// Genera una clave de cache única para el input.
    private func generateCacheKey(for input: ListMaterialsInput) -> String {
        var components: [String] = []

        // Filtros
        if let subjectId = input.filters.subjectId {
            components.append("sub:\(subjectId)")
        }
        if let unitId = input.filters.unitId {
            components.append("unit:\(unitId)")
        }
        if let type = input.filters.type {
            components.append("type:\(type.rawValue)")
        }
        if let status = input.filters.status {
            components.append("status:\(status.rawValue)")
        }
        if let query = input.filters.searchQuery, !query.isEmpty {
            components.append("q:\(query)")
        }

        // Paginación
        if let cursor = input.pagination.cursor {
            components.append("cursor:\(cursor)")
        }
        components.append("limit:\(input.pagination.limit)")

        // Ordenamiento
        components.append("sort:\(input.sortBy.rawValue)")
        components.append("order:\(input.sortOrder.rawValue)")

        return components.joined(separator: "|")
    }

    /// Construye el query para el repositorio.
    private func buildQuery(from input: ListMaterialsInput) -> MaterialsQuery {
        MaterialsQuery(
            subjectId: input.filters.subjectId,
            unitId: input.filters.unitId,
            type: input.filters.type?.rawValue,
            status: input.filters.status?.rawValue,
            searchQuery: input.filters.searchQuery,
            cursor: input.pagination.cursor,
            limit: input.pagination.limit,
            sortBy: input.sortBy.rawValue,
            sortOrder: input.sortOrder.rawValue
        )
    }

    /// Agrega items con deduplicación.
    private func appendItems(_ items: [Material]) {
        for item in items {
            if !loadedMaterialIds.contains(item.id) {
                accumulatedItems.append(item)
                loadedMaterialIds.insert(item.id)
            }
        }
    }
}
