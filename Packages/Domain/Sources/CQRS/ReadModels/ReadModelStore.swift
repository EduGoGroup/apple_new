import Foundation
import OSLog

/// Protocolo que todos los Read Models deben implementar.
///
/// Los Read Models son estructuras optimizadas para lectura que difieren
/// del domain model, priorizando velocidad de acceso sobre normalización.
public protocol ReadModel: Sendable, Identifiable where ID == String {
    /// Identificador único del read model para cache
    var id: String { get }

    /// Tags asociados para invalidación selectiva
    var tags: Set<String> { get }

    /// Timestamp de cuando se creó/actualizó el modelo
    var cachedAt: Date { get }

    /// TTL en segundos para este modelo específico
    var ttlSeconds: TimeInterval { get }
}

/// Extensión con valores por defecto
public extension ReadModel {
    var tags: Set<String> { [] }
    var ttlSeconds: TimeInterval { 300 } // 5 minutos por defecto
}

/// Entry de cache con metadata de expiración.
private struct CacheEntry<T: ReadModel>: Sendable {
    let model: T
    let expiresAt: Date
    let accessedAt: Date

    var isExpired: Bool {
        Date() > expiresAt
    }

    func withUpdatedAccess() -> CacheEntry<T> {
        CacheEntry(
            model: model,
            expiresAt: expiresAt,
            accessedAt: Date()
        )
    }
}

/// Actor que almacena Read Models en memoria con LRU eviction y TTL configurable.
///
/// `ReadModelStore` proporciona un cache thread-safe para Read Models,
/// implementando:
/// - TTL (Time To Live) configurable por modelo
/// - LRU (Least Recently Used) eviction cuando se alcanza el límite
/// - Invalidación por ID, tag, o completa
/// - Métricas de rendimiento (hit rate, miss rate)
///
/// # Características
/// - Thread-safe mediante actor isolation
/// - Genérico sobre cualquier ReadModel
/// - Soporte para stale-while-revalidate
/// - Integración con CQRSMetrics
///
/// # Ejemplo de uso:
/// ```swift
/// let store = ReadModelStore<DashboardReadModel>(maxEntries: 100)
///
/// // Guardar un read model
/// await store.save(dashboardModel)
///
/// // Obtener (solo si fresh)
/// if let fresh = await store.get(id: "user-123") {
///     print("Dashboard cargado: \(fresh.studentName)")
/// }
///
/// // Obtener incluso si stale
/// if let stale = await store.getStale(id: "user-123") {
///     print("Dashboard (posiblemente stale): \(stale.studentName)")
/// }
///
/// // Invalidar por tag
/// await store.invalidateByTag("user-123")
/// ```
public actor ReadModelStore<T: ReadModel> {

    // MARK: - Properties

    /// Cache principal indexado por ID
    private var cache: [String: CacheEntry<T>] = [:]

    /// Índice de tags a IDs para invalidación rápida
    private var tagIndex: [String: Set<String>] = [:]

    /// Orden de acceso para LRU eviction
    private var accessOrder: [String] = []

    /// Número máximo de entries antes de eviction
    private let maxEntries: Int

    /// TTL por defecto si el modelo no especifica uno
    private let defaultTTL: TimeInterval

    /// Logger para debugging
    private let logger: Logger

    /// Indica si el logging está habilitado
    private let loggingEnabled: Bool

    /// Métricas del store
    private var metrics: StoreMetrics

    // MARK: - Initialization

    /// Crea un nuevo ReadModelStore.
    ///
    /// - Parameters:
    ///   - maxEntries: Número máximo de entries (default: 100)
    ///   - defaultTTL: TTL por defecto en segundos (default: 300)
    ///   - loggingEnabled: Habilita logging (default: true en debug)
    public init(
        maxEntries: Int = 100,
        defaultTTL: TimeInterval = 300,
        loggingEnabled: Bool = true
    ) {
        self.maxEntries = maxEntries
        self.defaultTTL = defaultTTL
        self.loggingEnabled = loggingEnabled
        self.logger = Logger(subsystem: "com.edugo.cqrs", category: "ReadModelStore")
        self.metrics = StoreMetrics()
    }

    // MARK: - CRUD Operations

    /// Obtiene un read model por su ID si existe y no expiró.
    ///
    /// - Parameter id: ID del read model
    /// - Returns: El read model si existe y está fresh, nil si no existe o expiró
    public func get(id: String) -> T? {
        guard let entry = cache[id] else {
            metrics.recordMiss()
            return nil
        }

        if entry.isExpired {
            // Entry expirado, remover y reportar miss
            removeEntry(id: id)
            metrics.recordMiss()
            return nil
        }

        // Actualizar acceso para LRU
        updateAccessOrder(id: id)
        cache[id] = entry.withUpdatedAccess()

        metrics.recordHit()

        if loggingEnabled {
            logger.debug("Cache hit for: \(id)")
        }

        return entry.model
    }

    /// Obtiene un read model incluso si expiró (para stale-while-revalidate).
    ///
    /// - Parameter id: ID del read model
    /// - Returns: El read model si existe (fresh o stale), nil si no existe
    public func getStale(id: String) -> T? {
        guard let entry = cache[id] else {
            metrics.recordMiss()
            return nil
        }

        // Actualizar acceso aunque esté stale
        updateAccessOrder(id: id)

        if entry.isExpired {
            metrics.recordStaleHit()
            if loggingEnabled {
                logger.debug("Stale cache hit for: \(id)")
            }
        } else {
            metrics.recordHit()
        }

        return entry.model
    }

    /// Guarda un read model en el store.
    ///
    /// Si el store está lleno, aplica LRU eviction antes de guardar.
    ///
    /// - Parameter model: El read model a guardar
    public func save(_ model: T) {
        let id = model.id

        // LRU eviction si está lleno
        while cache.count >= maxEntries && cache[id] == nil {
            evictLRU()
        }

        // Calcular expiración
        let ttl = model.ttlSeconds > 0 ? model.ttlSeconds : defaultTTL
        let expiresAt = Date().addingTimeInterval(ttl)

        // Crear entry
        let entry = CacheEntry(
            model: model,
            expiresAt: expiresAt,
            accessedAt: Date()
        )

        // Actualizar índices
        if let existingEntry = cache[id] {
            // Remover tags anteriores
            removeFromTagIndex(id: id, tags: existingEntry.model.tags)
        }

        cache[id] = entry
        addToTagIndex(id: id, tags: model.tags)
        updateAccessOrder(id: id)

        if loggingEnabled {
            logger.debug("Saved read model: \(id) with TTL: \(ttl)s")
        }
    }

    /// Invalida un read model específico.
    ///
    /// - Parameter id: ID del read model a invalidar
    /// - Returns: true si existía y fue invalidado
    @discardableResult
    public func invalidate(id: String) -> Bool {
        guard cache[id] != nil else { return false }

        removeEntry(id: id)
        metrics.recordInvalidation()

        if loggingEnabled {
            logger.debug("Invalidated: \(id)")
        }

        return true
    }

    /// Invalida todos los read models que tengan un tag específico.
    ///
    /// - Parameter tag: Tag a buscar para invalidación
    /// - Returns: Número de entries invalidados
    @discardableResult
    public func invalidateByTag(_ tag: String) -> Int {
        guard let ids = tagIndex[tag] else { return 0 }

        var count = 0
        for id in ids {
            if cache.removeValue(forKey: id) != nil {
                count += 1
                metrics.recordInvalidation()
            }
            accessOrder.removeAll { $0 == id }
        }

        tagIndex.removeValue(forKey: tag)

        if loggingEnabled && count > 0 {
            logger.debug("Invalidated \(count) entries by tag: \(tag)")
        }

        return count
    }

    /// Invalida todos los read models.
    public func invalidateAll() {
        let count = cache.count
        cache.removeAll()
        tagIndex.removeAll()
        accessOrder.removeAll()

        metrics.recordInvalidation(count: count)

        if loggingEnabled {
            logger.warning("Invalidated all entries (\(count))")
        }
    }

    // MARK: - Bulk Operations

    /// Obtiene múltiples read models por sus IDs.
    ///
    /// - Parameter ids: IDs a buscar
    /// - Returns: Diccionario de ID a modelo para los que existen y están fresh
    public func getMany(ids: [String]) -> [String: T] {
        var result: [String: T] = [:]
        for id in ids {
            if let model = get(id: id) {
                result[id] = model
            }
        }
        return result
    }

    /// Guarda múltiples read models.
    ///
    /// - Parameter models: Read models a guardar
    public func saveMany(_ models: [T]) {
        for model in models {
            save(model)
        }
    }

    // MARK: - Query Operations

    /// Verifica si existe un entry (fresh) para un ID.
    ///
    /// - Parameter id: ID a verificar
    /// - Returns: true si existe y está fresh
    public func contains(id: String) -> Bool {
        guard let entry = cache[id] else { return false }
        return !entry.isExpired
    }

    /// Obtiene todos los IDs de entries actualmente en cache.
    public var allIds: [String] {
        cache.keys.filter { id in
            cache[id].map { !$0.isExpired } ?? false
        }
    }

    /// Número de entries en cache (incluyendo expirados).
    public var count: Int {
        cache.count
    }

    /// Número de entries fresh en cache.
    public var freshCount: Int {
        cache.values.filter { !$0.isExpired }.count
    }

    // MARK: - Metrics

    /// Estadísticas actuales del store.
    public var currentMetrics: StoreMetrics {
        metrics
    }

    /// Resetea las métricas.
    public func resetMetrics() {
        metrics = StoreMetrics()
    }

    // MARK: - Maintenance

    /// Limpia entries expirados del cache.
    ///
    /// Llama a este método periódicamente para liberar memoria.
    ///
    /// - Returns: Número de entries limpiados
    @discardableResult
    public func cleanExpired() -> Int {
        let expiredIds = cache.filter { $0.value.isExpired }.map { $0.key }

        for id in expiredIds {
            removeEntry(id: id)
        }

        if loggingEnabled && !expiredIds.isEmpty {
            logger.debug("Cleaned \(expiredIds.count) expired entries")
        }

        return expiredIds.count
    }

    // MARK: - Private Methods

    /// Remueve un entry y actualiza índices.
    private func removeEntry(id: String) {
        if let entry = cache.removeValue(forKey: id) {
            removeFromTagIndex(id: id, tags: entry.model.tags)
        }
        accessOrder.removeAll { $0 == id }
    }

    /// Actualiza el orden de acceso para LRU.
    private func updateAccessOrder(id: String) {
        accessOrder.removeAll { $0 == id }
        accessOrder.append(id)
    }

    /// Aplica LRU eviction del entry más antiguo.
    private func evictLRU() {
        guard let oldest = accessOrder.first else { return }
        removeEntry(id: oldest)

        if loggingEnabled {
            logger.debug("LRU evicted: \(oldest)")
        }
    }

    /// Agrega un ID al índice de tags.
    private func addToTagIndex(id: String, tags: Set<String>) {
        for tag in tags {
            tagIndex[tag, default: []].insert(id)
        }
    }

    /// Remueve un ID del índice de tags.
    private func removeFromTagIndex(id: String, tags: Set<String>) {
        for tag in tags {
            tagIndex[tag]?.remove(id)
            if tagIndex[tag]?.isEmpty == true {
                tagIndex.removeValue(forKey: tag)
            }
        }
    }
}

// MARK: - Store Metrics

/// Métricas de rendimiento del ReadModelStore.
public struct StoreMetrics: Sendable {
    /// Número de cache hits
    public private(set) var hits: Int = 0

    /// Número de cache misses
    public private(set) var misses: Int = 0

    /// Número de stale hits (stale-while-revalidate)
    public private(set) var staleHits: Int = 0

    /// Número de invalidaciones
    public private(set) var invalidations: Int = 0

    /// Ratio de hits sobre total de accesos
    public var hitRatio: Double {
        let total = hits + misses
        guard total > 0 else { return 0.0 }
        return Double(hits) / Double(total)
    }

    /// Total de accesos
    public var totalAccesses: Int {
        hits + misses
    }

    public init() {}

    mutating func recordHit() {
        hits += 1
    }

    mutating func recordMiss() {
        misses += 1
    }

    mutating func recordStaleHit() {
        staleHits += 1
        hits += 1 // Stale hits también cuentan como hits
    }

    mutating func recordInvalidation(count: Int = 1) {
        invalidations += count
    }
}

extension StoreMetrics: CustomStringConvertible {
    public var description: String {
        """
        StoreMetrics:
          - Hits: \(hits)
          - Misses: \(misses)
          - Stale Hits: \(staleHits)
          - Hit Ratio: \(String(format: "%.2f%%", hitRatio * 100))
          - Invalidations: \(invalidations)
          - Total Accesses: \(totalAccesses)
        """
    }
}
