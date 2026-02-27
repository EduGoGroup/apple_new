import Foundation
import EduCore

/// Read Model optimizado para listas de materiales con paginación.
///
/// Este modelo contiene una página de materiales pre-calculada con
/// metadata de paginación completa. Diseñado para consultas frecuentes
/// de listado con filtros y paginación cursor-based.
///
/// # Características
/// - Lista paginada pre-calculada
/// - Metadata de paginación (totalCount, pageCount, currentPage)
/// - TTL de 10 minutos por defecto
/// - Tags para invalidación por subject, unit, o query
/// - Soporte para infinite scroll
///
/// # Ejemplo de uso:
/// ```swift
/// let readModel = MaterialListReadModel(
///     queryKey: "subject:math|sort:createdAt",
///     materials: materialSummaries,
///     pagination: PaginationMeta(
///         currentCursor: nil,
///         nextCursor: "page2",
///         totalCount: 150,
///         pageSize: 20,
///         currentPage: 1
///     )
/// )
///
/// await materialListStore.save(readModel)
/// ```
public struct MaterialListReadModel: ReadModel {

    // MARK: - ReadModel Protocol

    public var id: String { "materials-\(queryKey)" }
    public var tags: Set<String>
    public let cachedAt: Date
    public var ttlSeconds: TimeInterval { 600 } // 10 minutos

    // MARK: - Query Key

    /// Clave única que identifica la combinación de filtros/ordenamiento
    public let queryKey: String

    // MARK: - Materials (Denormalized Summaries)

    /// Materiales en esta página (resúmenes ligeros)
    public let materials: [MaterialSummary]

    // MARK: - Pagination Metadata

    /// Metadata de paginación pre-calculada
    public let pagination: PaginationMeta

    // MARK: - Filter Context

    /// Contexto de filtros aplicados
    public let filterContext: MaterialFilterContext

    // MARK: - Initialization

    /// Crea un nuevo MaterialListReadModel.
    public init(
        queryKey: String,
        materials: [MaterialSummary],
        pagination: PaginationMeta,
        filterContext: MaterialFilterContext = .none,
        cachedAt: Date = Date()
    ) {
        self.queryKey = queryKey
        self.materials = materials
        self.pagination = pagination
        self.filterContext = filterContext
        self.cachedAt = cachedAt

        // Generar tags basados en el contexto
        var tags: Set<String> = ["materials"]
        if let subjectId = filterContext.subjectId {
            tags.insert("subject-\(subjectId)")
        }
        if let unitId = filterContext.unitId {
            tags.insert("unit-\(unitId)")
        }
        if filterContext.hasSearchQuery {
            tags.insert("search")
        }
        self.tags = tags
    }

    /// Crea un MaterialListReadModel desde una MaterialsPage del use case.
    public init(
        from page: MaterialsPage,
        queryKey: String,
        filterContext: MaterialFilterContext,
        currentPage: Int
    ) {
        self.queryKey = queryKey
        self.materials = page.items.map { MaterialSummary(from: $0) }
        self.pagination = PaginationMeta(
            currentCursor: nil,
            nextCursor: page.nextCursor,
            totalCount: page.totalCount,
            pageSize: page.items.count,
            currentPage: currentPage,
            hasMore: page.hasMore
        )
        self.filterContext = filterContext
        self.cachedAt = Date()

        var tags: Set<String> = ["materials"]
        if let subjectId = filterContext.subjectId {
            tags.insert("subject-\(subjectId)")
        }
        if let unitId = filterContext.unitId {
            tags.insert("unit-\(unitId)")
        }
        self.tags = tags
    }
}

// MARK: - Material Summary

/// Resumen ligero de un material para listados.
///
/// Contiene solo los campos necesarios para mostrar en una lista,
/// evitando cargar datos pesados como contenido o metadata extendida.
public struct MaterialSummary: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String?
    public let status: MaterialStatus
    public let fileType: String?
    public let fileSizeBytes: Int?
    public let subject: String?
    public let grade: String?
    public let isPublic: Bool
    public let createdAt: Date
    public let updatedAt: Date

    /// Tamaño formateado (ej: "2.5 MB")
    public var formattedSize: String? {
        guard let bytes = fileSizeBytes else { return nil }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    /// Indica si el material está listo para usar
    public var isReady: Bool {
        status == .ready
    }

    public init(
        id: UUID,
        title: String,
        description: String?,
        status: MaterialStatus,
        fileType: String?,
        fileSizeBytes: Int?,
        subject: String?,
        grade: String?,
        isPublic: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.status = status
        self.fileType = fileType
        self.fileSizeBytes = fileSizeBytes
        self.subject = subject
        self.grade = grade
        self.isPublic = isPublic
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Crea un MaterialSummary desde un Material del dominio.
    public init(from material: Material) {
        self.id = material.id
        self.title = material.title
        self.description = material.description
        self.status = material.status
        self.fileType = material.fileType
        self.fileSizeBytes = material.fileSizeBytes
        self.subject = material.subject
        self.grade = material.grade
        self.isPublic = material.isPublic
        self.createdAt = material.createdAt
        self.updatedAt = material.updatedAt
    }
}

// MARK: - Pagination Metadata

/// Metadata de paginación pre-calculada.
public struct PaginationMeta: Sendable, Equatable {
    /// Cursor de la página actual (nil para primera página)
    public let currentCursor: String?

    /// Cursor para la siguiente página (nil si es última)
    public let nextCursor: String?

    /// Total de items (si el backend lo provee)
    public let totalCount: Int?

    /// Tamaño de página usado
    public let pageSize: Int

    /// Número de página actual (1-indexed)
    public let currentPage: Int

    /// Indica si hay más páginas
    public let hasMore: Bool

    /// Número total de páginas (calculado)
    public var totalPages: Int? {
        guard let total = totalCount, pageSize > 0 else { return nil }
        return (total + pageSize - 1) / pageSize
    }

    /// Indica si es la primera página
    public var isFirstPage: Bool {
        currentPage == 1 || currentCursor == nil
    }

    /// Indica si es la última página
    public var isLastPage: Bool {
        !hasMore
    }

    public init(
        currentCursor: String?,
        nextCursor: String?,
        totalCount: Int?,
        pageSize: Int,
        currentPage: Int,
        hasMore: Bool
    ) {
        self.currentCursor = currentCursor
        self.nextCursor = nextCursor
        self.totalCount = totalCount
        self.pageSize = pageSize
        self.currentPage = currentPage
        self.hasMore = hasMore
    }

    /// Metadata vacía para página inicial.
    public static let empty = PaginationMeta(
        currentCursor: nil,
        nextCursor: nil,
        totalCount: 0,
        pageSize: 20,
        currentPage: 1,
        hasMore: false
    )
}

// MARK: - Filter Context

/// Contexto de filtros aplicados a la lista.
public struct MaterialFilterContext: Sendable, Equatable {
    public let subjectId: UUID?
    public let unitId: UUID?
    public let type: MaterialType?
    public let status: MaterialStatus?
    public let searchQuery: String?
    public let sortBy: MaterialSortOption
    public let sortOrder: MaterialSortDirection

    /// Indica si hay una búsqueda activa
    public var hasSearchQuery: Bool {
        guard let query = searchQuery else { return false }
        return !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// Indica si hay filtros activos (además del ordenamiento)
    public var hasFilters: Bool {
        subjectId != nil || unitId != nil || type != nil || status != nil || hasSearchQuery
    }

    public init(
        subjectId: UUID? = nil,
        unitId: UUID? = nil,
        type: MaterialType? = nil,
        status: MaterialStatus? = nil,
        searchQuery: String? = nil,
        sortBy: MaterialSortOption = .createdAt,
        sortOrder: MaterialSortDirection = .descending
    ) {
        self.subjectId = subjectId
        self.unitId = unitId
        self.type = type
        self.status = status
        self.searchQuery = searchQuery
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }

    /// Crea desde MaterialFilters del use case.
    public init(from filters: MaterialFilters, sortBy: MaterialSortOption, sortOrder: MaterialSortDirection) {
        self.subjectId = filters.subjectId
        self.unitId = filters.unitId
        self.type = filters.type
        self.status = filters.status
        self.searchQuery = filters.searchQuery
        self.sortBy = sortBy
        self.sortOrder = sortOrder
    }

    /// Contexto sin filtros.
    public static let none = MaterialFilterContext()

    /// Genera una clave de cache única para este contexto.
    public var cacheKey: String {
        var components: [String] = []

        if let subjectId = subjectId {
            components.append("sub:\(subjectId)")
        }
        if let unitId = unitId {
            components.append("unit:\(unitId)")
        }
        if let type = type {
            components.append("type:\(type.rawValue)")
        }
        if let status = status {
            components.append("status:\(status.rawValue)")
        }
        if let query = searchQuery, !query.isEmpty {
            components.append("q:\(query)")
        }
        components.append("sort:\(sortBy.rawValue)")
        components.append("order:\(sortOrder.rawValue)")

        return components.joined(separator: "|")
    }
}

// MARK: - Accumulated Materials Read Model

/// Read Model para infinite scroll con materiales acumulados.
public struct AccumulatedMaterialsReadModel: ReadModel {

    public var id: String { "accumulated-\(queryKey)" }
    public var tags: Set<String> { ["materials", "accumulated"] }
    public let cachedAt: Date
    public var ttlSeconds: TimeInterval { 300 } // 5 minutos

    /// Clave de query
    public let queryKey: String

    /// Todos los materiales acumulados
    public let materials: [MaterialSummary]

    /// IDs cargados para deduplicación
    public let loadedIds: Set<UUID>

    /// Cursor para siguiente página
    public let nextCursor: String?

    /// Páginas cargadas
    public let pagesLoaded: Int

    /// Indica si hay más
    public var hasMore: Bool {
        nextCursor != nil
    }

    public init(
        queryKey: String,
        materials: [MaterialSummary],
        loadedIds: Set<UUID>,
        nextCursor: String?,
        pagesLoaded: Int,
        cachedAt: Date = Date()
    ) {
        self.queryKey = queryKey
        self.materials = materials
        self.loadedIds = loadedIds
        self.nextCursor = nextCursor
        self.pagesLoaded = pagesLoaded
        self.cachedAt = cachedAt
    }

    /// Agrega una nueva página con deduplicación.
    public func appending(page: MaterialListReadModel) -> AccumulatedMaterialsReadModel {
        var newMaterials = materials
        var newLoadedIds = loadedIds

        for material in page.materials {
            if !loadedIds.contains(material.id) {
                newMaterials.append(material)
                newLoadedIds.insert(material.id)
            }
        }

        return AccumulatedMaterialsReadModel(
            queryKey: queryKey,
            materials: newMaterials,
            loadedIds: newLoadedIds,
            nextCursor: page.pagination.nextCursor,
            pagesLoaded: pagesLoaded + 1,
            cachedAt: Date()
        )
    }
}
