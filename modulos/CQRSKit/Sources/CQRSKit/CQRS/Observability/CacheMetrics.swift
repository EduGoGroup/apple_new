import Foundation

/// Estadísticas de cache para un handler específico
public struct CacheMetrics: Sendable {
    public let handlerType: String
    public private(set) var hits: Int
    public private(set) var misses: Int
    public private(set) var invalidations: Int
    public private(set) var staleWhileRevalidateHits: Int

    /// Ratio de hits sobre total de accesos
    public var hitRatio: Double {
        let total = hits + misses
        guard total > 0 else { return 0.0 }
        return Double(hits) / Double(total)
    }

    /// Ratio de misses sobre total de accesos
    public var missRatio: Double {
        let total = hits + misses
        guard total > 0 else { return 0.0 }
        return Double(misses) / Double(total)
    }

    /// Total de accesos al cache
    public var totalAccesses: Int {
        hits + misses
    }

    public init(handlerType: String) {
        self.handlerType = handlerType
        self.hits = 0
        self.misses = 0
        self.invalidations = 0
        self.staleWhileRevalidateHits = 0
    }

    /// Registra un cache hit
    public mutating func recordHit() {
        hits += 1
    }

    /// Registra un cache miss
    public mutating func recordMiss() {
        misses += 1
    }

    /// Registra una invalidación de cache
    public mutating func recordInvalidation() {
        invalidations += 1
    }

    /// Registra un hit de stale-while-revalidate
    public mutating func recordStaleHit() {
        staleWhileRevalidateHits += 1
    }

    /// Resetea todas las métricas a cero
    public mutating func reset() {
        hits = 0
        misses = 0
        invalidations = 0
        staleWhileRevalidateHits = 0
    }
}

extension CacheMetrics: CustomStringConvertible {
    public var description: String {
        """
        CacheMetrics(handler: \(handlerType))
          - Hits: \(hits)
          - Misses: \(misses)
          - Hit Ratio: \(String(format: "%.2f%%", hitRatio * 100))
          - Invalidations: \(invalidations)
          - Stale Hits: \(staleWhileRevalidateHits)
          - Total Accesses: \(totalAccesses)
        """
    }
}
