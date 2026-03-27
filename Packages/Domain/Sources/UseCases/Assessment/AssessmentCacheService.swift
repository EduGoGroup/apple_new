import Foundation

// MARK: - Assessment Cache Service

/// Cache in-memory para evaluaciones con TTL configurable.
///
/// Implementa `AssessmentCacheServiceProtocol` del dominio con un almacenamiento
/// en memoria basado en diccionario. Las entradas expiran automaticamente
/// despues del TTL configurado (default: 10 minutos).
///
/// ## Thread Safety
/// Como actor de Swift 6.2, todas las operaciones son thread-safe.
///
/// ## Ejemplo de uso
/// ```swift
/// let cacheService = AssessmentCacheService()
///
/// // Guardar en cache
/// let entry = AssessmentCacheEntry(assessment: assessment, eligibility: eligibility)
/// await cacheService.save(entry, for: assessmentId)
///
/// // Obtener del cache
/// if let cached = await cacheService.get(assessmentId: assessmentId) {
///     print("Cached at: \(cached.cachedAt)")
/// }
///
/// // Eliminar del cache
/// await cacheService.remove(assessmentId: assessmentId)
/// ```
public actor AssessmentCacheService: AssessmentCacheServiceProtocol {

    // MARK: - Properties

    /// Almacenamiento interno con timestamp de guardado.
    private var cache: [UUID: (entry: AssessmentCacheEntry, savedAt: Date)] = [:]

    /// Tiempo de vida de las entradas en segundos (default: 10 minutos).
    private let ttl: TimeInterval

    // MARK: - Initialization

    /// Crea un nuevo servicio de cache para assessments.
    ///
    /// - Parameter ttl: Tiempo de vida de las entradas en segundos.
    ///   Default: 600 (10 minutos).
    public init(ttl: TimeInterval = 600) {
        self.ttl = ttl
    }

    // MARK: - AssessmentCacheServiceProtocol

    public func get(assessmentId: UUID) async -> AssessmentCacheEntry? {
        guard let cached = cache[assessmentId] else {
            return nil
        }

        // Verificar TTL
        if Date().timeIntervalSince(cached.savedAt) > ttl {
            cache[assessmentId] = nil
            return nil
        }

        return cached.entry
    }

    public func save(_ entry: AssessmentCacheEntry, for assessmentId: UUID) async {
        cache[assessmentId] = (entry, Date())
    }

    public func remove(assessmentId: UUID) async {
        cache[assessmentId] = nil
    }

    // MARK: - Maintenance

    /// Elimina todas las entradas expiradas del cache.
    ///
    /// Puede llamarse periodicamente para liberar memoria.
    public func evictExpired() {
        let now = Date()
        for (key, value) in cache {
            if now.timeIntervalSince(value.savedAt) > ttl {
                cache[key] = nil
            }
        }
    }

    /// Elimina todas las entradas del cache.
    public func clear() {
        cache.removeAll()
    }

    /// Numero de entradas actualmente en cache.
    public var count: Int {
        cache.count
    }
}
