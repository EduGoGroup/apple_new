import Foundation
import SwiftUI
import EduDomain
import EduCore
import EduFoundation
import EduDomain

/// ViewModel para lista de materiales usando CQRS Mediator.
///
/// Este ViewModel se refactorizó para usar el patrón CQRS en lugar de
/// llamar use cases directamente. Gestiona listado de materiales con
/// paginación cursor-based, filtrado y ordenamiento.
///
/// ## Responsabilidades
/// - Cargar materiales via ListMaterialsQuery (con cache automático)
/// - Gestionar paginación cursor-based para infinite scroll
/// - Aplicar filtros (búsqueda, materia, tipo)
/// - Suscribirse a MaterialUploadedEvent para auto-refresh
///
/// ## Integración con CQRS
/// - **Queries**: ListMaterialsQuery (con cache LRU y TTL)
/// - **Events**: MaterialUploadedEvent (invalidar cache y refrescar)
///
/// ## Paginación
/// - Cursor-based para eficiencia
/// - Soporte para infinite scroll
/// - Deduplicación automática
/// - Graceful degradation con stale cache
///
/// ## Ejemplo de uso
/// ```swift
/// @StateObject private var viewModel = MaterialListViewModel(
///     mediator: mediator,
///     eventBus: eventBus
/// )
///
/// // Cargar primera página
/// await viewModel.loadMaterials()
///
/// // Cargar siguiente página (infinite scroll)
/// await viewModel.loadMore()
///
/// // Aplicar filtro de búsqueda
/// viewModel.searchQuery = "matemáticas"
/// await viewModel.refresh()
/// ```
@MainActor
@Observable
public final class MaterialListViewModel {

    // MARK: - Published State

    /// Materiales cargados
    public var materials: [EduCore.Material] = []

    /// Indica si está cargando la primera página
    public var isLoading: Bool = false

    /// Indica si está cargando más páginas
    public var isLoadingMore: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    /// Indica si hay más páginas disponibles
    public var hasMore: Bool = false

    /// Cursor para la siguiente página
    private var nextCursor: String?

    // MARK: - Filters

    /// Query de búsqueda
    public var searchQuery: String = "" {
        didSet {
            if searchQuery != oldValue {
                Task {
                    await refresh()
                }
            }
        }
    }

    /// ID de materia para filtrar (opcional)
    public var subjectId: UUID? {
        didSet {
            if subjectId != oldValue {
                Task {
                    await refresh()
                }
            }
        }
    }

    /// Tipo de material para filtrar (opcional)
    public var materialType: MaterialType? {
        didSet {
            if materialType != oldValue {
                Task {
                    await refresh()
                }
            }
        }
    }

    /// Campo de ordenamiento
    public var sortBy: MaterialSortOption = .createdAt {
        didSet {
            if sortBy != oldValue {
                Task {
                    await refresh()
                }
            }
        }
    }

    /// Dirección del orden
    public var sortOrder: MaterialSortDirection = .descending {
        didSet {
            if sortOrder != oldValue {
                Task {
                    await refresh()
                }
            }
        }
    }

    /// Límite de items por página
    public var pageSize: Int = 20

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de queries
    private let mediator: Mediator

    /// EventBus para suscripción a eventos
    private let eventBus: EventBus

    /// IDs de suscripciones a eventos (para cleanup)
    private var subscriptionIds: [UUID] = []

    // MARK: - Initialization

    /// Crea un nuevo MaterialListViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar queries
    ///   - eventBus: EventBus para suscribirse a eventos de dominio
    public init(
        mediator: Mediator,
        eventBus: EventBus
    ) {
        self.mediator = mediator
        self.eventBus = eventBus

        // Suscribirse a eventos relevantes
        Task {
            await subscribeToEvents()
        }
    }

    // MARK: - Public Methods

    /// Carga la primera página de materiales.
    ///
    /// Utiliza ListMaterialsQuery que tiene cache LRU con TTL de 5 minutos.
    /// Los filtros se aplican automáticamente según el estado actual.
    public func loadMaterials() async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            // Crear filtros según el estado actual
            let filters = buildFilters()

            // Crear query para primera página
            let query = ListMaterialsQuery(
                filters: filters,
                limit: pageSize,
                sortBy: sortBy,
                sortOrder: sortOrder
            )

            // Ejecutar query via Mediator
            let page = try await mediator.send(query)

            // Actualizar estado
            self.materials = page.items
            self.hasMore = page.hasMore
            self.nextCursor = page.nextCursor
            self.isLoading = false

        } catch {
            self.error = error
            self.isLoading = false

            print("❌ Error loading materials: \(error.localizedDescription)")
        }
    }

    /// Carga la siguiente página de materiales (infinite scroll).
    ///
    /// Solo se ejecuta si hay más páginas disponibles y no está cargando.
    public func loadMore() async {
        guard !isLoadingMore, hasMore, let cursor = nextCursor else { return }

        isLoadingMore = true

        do {
            // Crear filtros
            let filters = buildFilters()

            // Crear query con cursor de la página actual
            let query = ListMaterialsQuery(
                filters: filters,
                pagination: CursorPagination(cursor: cursor, limit: pageSize),
                sortBy: sortBy,
                sortOrder: sortOrder,
                metadata: ["action": "loadMore"]
            )

            // Ejecutar query via Mediator
            let page = try await mediator.send(query)

            // Agregar nuevos items (deduplicación automática por ID)
            let existingIds = Set(materials.map { $0.id })
            let newItems = page.items.filter { !existingIds.contains($0.id) }

            self.materials.append(contentsOf: newItems)
            self.hasMore = page.hasMore
            self.nextCursor = page.nextCursor
            self.isLoadingMore = false

        } catch {
            self.error = error
            self.isLoadingMore = false

            print("❌ Error loading more materials: \(error.localizedDescription)")
        }
    }

    /// Refresca la lista completa desde el inicio.
    public func refresh() async {
        nextCursor = nil
        await loadMaterials()
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    /// Limpia todos los filtros.
    public func clearFilters() {
        searchQuery = ""
        subjectId = nil
        materialType = nil
        sortBy = .createdAt
        sortOrder = .descending
    }

    // MARK: - Private Methods

    /// Construye los filtros según el estado actual.
    private func buildFilters() -> MaterialFilters {
        let trimmedSearch = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        return MaterialFilters(
            subjectId: subjectId,
            unitId: nil,
            type: materialType,
            status: .ready,
            searchQuery: trimmedSearch.isEmpty ? nil : trimmedSearch
        )
    }

    // MARK: - Event Subscriptions

    /// Suscribe el ViewModel a eventos relevantes.
    private func subscribeToEvents() async {
        // Suscribirse a MaterialUploadedEvent para refrescar cuando se suba un material nuevo
        let uploadSubscriptionId = await eventBus.subscribe(to: MaterialUploadedEvent.self) { [weak self] event in
            guard let self = self else { return }

            await MainActor.run {
                Task {
                    // Refrescar la lista para incluir el nuevo material
                    await self.refresh()
                }
            }

            print("📢 Material uploaded: \(event.title)")
        }
        subscriptionIds.append(uploadSubscriptionId)

        // Suscribirse a MaterialAssignedEvent para actualizar si un material fue asignado
        let assignSubscriptionId = await eventBus.subscribe(to: MaterialAssignedEvent.self) { [weak self] event in
            guard let self = self else { return }

            await MainActor.run {
                // Opcionalmente refrescar si es relevante para la vista
                print("📢 Material assigned: \(event.materialId)")
            }
        }
        subscriptionIds.append(assignSubscriptionId)
    }
}

// MARK: - Convenience Computed Properties

extension MaterialListViewModel {
    /// Indica si hay materiales cargados
    public var hasMaterials: Bool {
        !materials.isEmpty
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Indica si se están aplicando filtros
    public var hasActiveFilters: Bool {
        !searchQuery.isEmpty || subjectId != nil || materialType != nil
    }

    /// Número de materiales cargados
    public var materialsCount: Int {
        materials.count
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        // Personalizar mensajes según tipo de error
        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuración del sistema"
            case .validationError(let message, _):
                return message
            case .executionError(let message, _):
                return "Error al cargar: \(message)"
            case .registrationError:
                return "Error de configuración del sistema"
            }
        }

        if let useCaseError = error as? UseCaseError {
            return useCaseError.localizedDescription
        }

        return error.localizedDescription
    }

    /// Mensaje para estado vacío
    public var emptyStateMessage: String {
        if hasActiveFilters {
            return "No se encontraron materiales con los filtros aplicados"
        } else {
            return "No hay materiales disponibles"
        }
    }
}
