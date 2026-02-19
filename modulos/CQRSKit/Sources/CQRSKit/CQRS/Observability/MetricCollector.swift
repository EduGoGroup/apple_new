import Foundation
import OSLog

/// Protocol para collectors de métricas personalizables
public protocol MetricCollector: Sendable {
    /// Registra el inicio de una operación
    func beginOperation(name: String, type: String) async

    /// Registra el fin de una operación
    func endOperation(name: String, type: String) async

    /// Registra una latencia de operación
    func recordLatency(operationType: String, handlerType: String, duration: Duration) async

    /// Registra un cache hit
    func recordCacheHit(handlerType: String) async

    /// Registra un cache miss
    func recordCacheMiss(handlerType: String) async

    /// Registra un error
    func recordError(handlerType: String, error: Error) async
}

/// Implementación default del MetricCollector usando OSLog signposts
public actor OSLogMetricCollector: MetricCollector {
    private let logger: Logger
    private let signpostLog: OSLog

    public init(subsystem: String = "com.edugo.cqrs", category: String = "metrics") {
        self.logger = Logger(subsystem: subsystem, category: category)
        self.signpostLog = OSLog(subsystem: subsystem, category: .pointsOfInterest)
    }

    public func beginOperation(name: String, type: String) {
        // OSLog signposts con strings dinámicos
        logger.debug("BEGIN \(name, privacy: .public) - type: \(type, privacy: .public)")
    }

    public func endOperation(name: String, type: String) {
        // OSLog signposts con strings dinámicos
        logger.debug("END \(name, privacy: .public) - type: \(type, privacy: .public)")
    }

    public func recordLatency(operationType: String, handlerType: String, duration: Duration) {
        let milliseconds = Double(duration.components.seconds) * 1000.0 +
                          Double(duration.components.attoseconds) / 1_000_000_000_000_000.0

        logger.debug(
            "Latency - \(operationType, privacy: .public): \(handlerType, privacy: .public) = \(milliseconds, privacy: .public)ms"
        )
    }

    public func recordCacheHit(handlerType: String) {
        logger.debug("Cache HIT - \(handlerType, privacy: .public)")
    }

    public func recordCacheMiss(handlerType: String) {
        logger.debug("Cache MISS - \(handlerType, privacy: .public)")
    }

    public func recordError(handlerType: String, error: Error) {
        logger.error("Error in \(handlerType, privacy: .public): \(error.localizedDescription, privacy: .public)")
    }
}
