import Foundation
import OSLog

/// Actor centralizado para todas las métricas del módulo CQRS
///
/// Este actor proporciona una API thread-safe para registrar métricas de:
/// - Latencias de queries y commands
/// - Cache hits/misses/invalidations
/// - Error rates por handler type
/// - Eventos publicados/procesados (preparatorio para EventBus)
///
/// # Ejemplo de uso:
/// ```swift
/// await CQRSMetrics.shared.recordQueryLatency(
///     queryType: "GetUserContextQuery",
///     duration: .milliseconds(45)
/// )
///
/// await CQRSMetrics.shared.recordCacheHit(queryType: "GetDashboardQuery")
/// ```
public actor CQRSMetrics {

    // MARK: - Singleton

    /// Instancia compartida
    public static let shared = CQRSMetrics()

    // MARK: - Properties

    /// Collector de métricas (pluggable)
    private let collector: MetricCollector

    /// Histogramas de latencia por tipo de query
    private var queryLatencies: [String: [Duration]] = [:]

    /// Histogramas de latencia por tipo de command
    private var commandLatencies: [String: [Duration]] = [:]

    /// Métricas de cache por handler type
    private var cacheMetrics: [String: CacheMetrics] = [:]

    /// Contadores de errores por handler type
    private var errorCounts: [String: Int] = [:]

    /// Contadores de eventos (preparatorio para EventBus)
    private var eventMetrics: EventMetrics = EventMetrics()

    /// Timestamp del último reset de métricas
    private var lastResetDate: Date = Date()

    // MARK: - Initialization

    public init(collector: MetricCollector? = nil) {
        self.collector = collector ?? OSLogMetricCollector()
    }

    // MARK: - Query Latencies

    /// Registra la latencia de una query
    ///
    /// - Parameters:
    ///   - queryType: Tipo de la query (ej: "GetUserContextQuery")
    ///   - duration: Duración de la operación
    public func recordQueryLatency(queryType: String, duration: Duration) async {
        // Agregar a histograma
        queryLatencies[queryType, default: []].append(duration)

        // Delegar al collector
        await collector.recordLatency(
            operationType: "Query",
            handlerType: queryType,
            duration: duration
        )
    }

    /// Obtiene estadísticas de latencia para un tipo de query
    ///
    /// - Parameter queryType: Tipo de la query
    /// - Returns: Estadísticas de latencia (p50, p95, p99, avg, count)
    public func getQueryLatencyStats(for queryType: String) -> LatencyStats? {
        guard let latencies = queryLatencies[queryType], !latencies.isEmpty else {
            return nil
        }
        return calculateStats(from: latencies)
    }

    /// Obtiene todas las estadísticas de latencias de queries
    public func getAllQueryLatencyStats() -> [String: LatencyStats] {
        var stats: [String: LatencyStats] = [:]
        for (queryType, latencies) in queryLatencies where !latencies.isEmpty {
            stats[queryType] = calculateStats(from: latencies)
        }
        return stats
    }

    // MARK: - Command Latencies

    /// Registra la latencia de un command
    ///
    /// - Parameters:
    ///   - commandType: Tipo del command (ej: "LoginCommand")
    ///   - duration: Duración de la operación
    public func recordCommandLatency(commandType: String, duration: Duration) async {
        // Agregar a histograma
        commandLatencies[commandType, default: []].append(duration)

        // Delegar al collector
        await collector.recordLatency(
            operationType: "Command",
            handlerType: commandType,
            duration: duration
        )
    }

    /// Obtiene estadísticas de latencia para un tipo de command
    ///
    /// - Parameter commandType: Tipo del command
    /// - Returns: Estadísticas de latencia (p50, p95, p99, avg, count)
    public func getCommandLatencyStats(for commandType: String) -> LatencyStats? {
        guard let latencies = commandLatencies[commandType], !latencies.isEmpty else {
            return nil
        }
        return calculateStats(from: latencies)
    }

    /// Obtiene todas las estadísticas de latencias de commands
    public func getAllCommandLatencyStats() -> [String: LatencyStats] {
        var stats: [String: LatencyStats] = [:]
        for (commandType, latencies) in commandLatencies where !latencies.isEmpty {
            stats[commandType] = calculateStats(from: latencies)
        }
        return stats
    }

    // MARK: - Cache Metrics

    /// Registra un cache hit
    ///
    /// - Parameter queryType: Tipo de la query
    public func recordCacheHit(queryType: String) async {
        cacheMetrics[queryType, default: CacheMetrics(handlerType: queryType)].recordHit()
        await collector.recordCacheHit(handlerType: queryType)
    }

    /// Registra un cache miss
    ///
    /// - Parameter queryType: Tipo de la query
    public func recordCacheMiss(queryType: String) async {
        cacheMetrics[queryType, default: CacheMetrics(handlerType: queryType)].recordMiss()
        await collector.recordCacheMiss(handlerType: queryType)
    }

    /// Registra una invalidación de cache
    ///
    /// - Parameter queryType: Tipo de la query
    public func recordCacheInvalidation(queryType: String) {
        cacheMetrics[queryType, default: CacheMetrics(handlerType: queryType)].recordInvalidation()
    }

    /// Registra un hit de stale-while-revalidate
    ///
    /// - Parameter queryType: Tipo de la query
    public func recordStaleHit(queryType: String) {
        cacheMetrics[queryType, default: CacheMetrics(handlerType: queryType)].recordStaleHit()
    }

    /// Obtiene las métricas de cache para un tipo de query
    ///
    /// - Parameter queryType: Tipo de la query
    /// - Returns: Métricas de cache o nil si no hay datos
    public func getCacheMetrics(for queryType: String) -> CacheMetrics? {
        cacheMetrics[queryType]
    }

    /// Obtiene todas las métricas de cache
    public func getAllCacheMetrics() -> [String: CacheMetrics] {
        cacheMetrics
    }

    // MARK: - Error Tracking

    /// Registra un error en un handler
    ///
    /// - Parameters:
    ///   - handlerType: Tipo del handler (query o command)
    ///   - error: El error ocurrido
    public func recordError(handlerType: String, error: Error) async {
        errorCounts[handlerType, default: 0] += 1
        await collector.recordError(handlerType: handlerType, error: error)
    }

    /// Obtiene el número de errores para un handler
    ///
    /// - Parameter handlerType: Tipo del handler
    /// - Returns: Número de errores registrados
    public func getErrorCount(for handlerType: String) -> Int {
        errorCounts[handlerType] ?? 0
    }

    /// Obtiene todos los contadores de errores
    public func getAllErrorCounts() -> [String: Int] {
        errorCounts
    }

    /// Calcula el error rate (errores por minuto) para un handler
    ///
    /// - Parameter handlerType: Tipo del handler
    /// - Returns: Errores por minuto
    public func getErrorRate(for handlerType: String) -> Double {
        guard let count = errorCounts[handlerType] else { return 0.0 }
        let minutesSinceReset = Date().timeIntervalSince(lastResetDate) / 60.0
        guard minutesSinceReset > 0 else { return 0.0 }
        return Double(count) / minutesSinceReset
    }

    // MARK: - Event Metrics (Preparatorio para EventBus)

    /// Registra un evento publicado
    ///
    /// - Parameter eventType: Tipo del evento (ej: "UserLoggedIn")
    public func recordEventPublished(eventType: String) {
        eventMetrics.recordPublished(eventType: eventType)
    }

    /// Registra un evento procesado
    ///
    /// - Parameter eventType: Tipo del evento
    public func recordEventProcessed(eventType: String) {
        eventMetrics.recordProcessed(eventType: eventType)
    }

    /// Obtiene las métricas de eventos
    public func getEventMetrics() -> EventMetrics {
        eventMetrics
    }

    // MARK: - Utilidades

    /// Resetea todas las métricas
    public func reset() {
        queryLatencies.removeAll()
        commandLatencies.removeAll()
        cacheMetrics.removeAll()
        errorCounts.removeAll()
        eventMetrics = EventMetrics()
        lastResetDate = Date()
    }

    /// Genera un reporte completo de todas las métricas
    public func generateReport() -> MetricsReport {
        MetricsReport(
            queryStats: getAllQueryLatencyStats(),
            commandStats: getAllCommandLatencyStats(),
            cacheMetrics: getAllCacheMetrics(),
            errorCounts: getAllErrorCounts(),
            eventMetrics: eventMetrics,
            reportDate: Date(),
            timeSinceLastReset: Date().timeIntervalSince(lastResetDate)
        )
    }

    // MARK: - Private Helpers

    private func calculateStats(from durations: [Duration]) -> LatencyStats {
        let sorted = durations.sorted { $0 < $1 }
        let count = sorted.count

        let p50Index = Int(Double(count) * 0.50)
        let p95Index = Int(Double(count) * 0.95)
        let p99Index = Int(Double(count) * 0.99)

        let totalNanoseconds = sorted.reduce(0) { $0 + $1.components.seconds * 1_000_000_000 + $1.components.attoseconds / 1_000_000_000 }
        let avgNanoseconds = totalNanoseconds / Int64(count)

        return LatencyStats(
            p50: sorted[p50Index],
            p95: sorted[min(p95Index, count - 1)],
            p99: sorted[min(p99Index, count - 1)],
            avg: Duration(secondsComponent: avgNanoseconds / 1_000_000_000, attosecondsComponent: (avgNanoseconds % 1_000_000_000) * 1_000_000_000),
            count: count
        )
    }
}

// MARK: - Supporting Types

/// Estadísticas de latencia
public struct LatencyStats: Sendable {
    public let p50: Duration
    public let p95: Duration
    public let p99: Duration
    public let avg: Duration
    public let count: Int

    /// Convierte una Duration a milisegundos para display
    public static func toMilliseconds(_ duration: Duration) -> Double {
        Double(duration.components.seconds) * 1000.0 +
        Double(duration.components.attoseconds) / 1_000_000_000_000_000.0
    }
}

extension LatencyStats: CustomStringConvertible {
    public var description: String {
        """
        LatencyStats(count: \(count))
          - P50: \(String(format: "%.2f", LatencyStats.toMilliseconds(p50)))ms
          - P95: \(String(format: "%.2f", LatencyStats.toMilliseconds(p95)))ms
          - P99: \(String(format: "%.2f", LatencyStats.toMilliseconds(p99)))ms
          - Avg: \(String(format: "%.2f", LatencyStats.toMilliseconds(avg)))ms
        """
    }
}

/// Métricas de eventos (preparatorio para EventBus)
public struct EventMetrics: Sendable {
    private var publishedCounts: [String: Int] = [:]
    private var processedCounts: [String: Int] = [:]

    public var totalPublished: Int {
        publishedCounts.values.reduce(0, +)
    }

    public var totalProcessed: Int {
        processedCounts.values.reduce(0, +)
    }

    public init() {}

    mutating func recordPublished(eventType: String) {
        publishedCounts[eventType, default: 0] += 1
    }

    mutating func recordProcessed(eventType: String) {
        processedCounts[eventType, default: 0] += 1
    }

    public func getPublishedCount(for eventType: String) -> Int {
        publishedCounts[eventType] ?? 0
    }

    public func getProcessedCount(for eventType: String) -> Int {
        processedCounts[eventType] ?? 0
    }

    public var allPublished: [String: Int] {
        publishedCounts
    }

    public var allProcessed: [String: Int] {
        processedCounts
    }
}

extension EventMetrics: CustomStringConvertible {
    public var description: String {
        """
        EventMetrics
          - Total Published: \(totalPublished)
          - Total Processed: \(totalProcessed)
          - By Type Published: \(publishedCounts)
          - By Type Processed: \(processedCounts)
        """
    }
}

/// Reporte completo de métricas
public struct MetricsReport: Sendable {
    public let queryStats: [String: LatencyStats]
    public let commandStats: [String: LatencyStats]
    public let cacheMetrics: [String: CacheMetrics]
    public let errorCounts: [String: Int]
    public let eventMetrics: EventMetrics
    public let reportDate: Date
    public let timeSinceLastReset: TimeInterval

    /// Genera un reporte en texto plano
    public func formatted() -> String {
        var output = """
        ═══════════════════════════════════════════════════════
        CQRS Metrics Report
        Generated: \(reportDate)
        Time Since Reset: \(String(format: "%.2f", timeSinceLastReset / 60.0)) minutes
        ═══════════════════════════════════════════════════════

        """

        // Query Latencies
        output += "\n📊 Query Latencies\n"
        if queryStats.isEmpty {
            output += "  (No data)\n"
        } else {
            for (queryType, stats) in queryStats.sorted(by: { $0.key < $1.key }) {
                output += "  \(queryType):\n"
                output += "    \(stats.description.replacingOccurrences(of: "\n", with: "\n    "))\n"
            }
        }

        // Command Latencies
        output += "\n📊 Command Latencies\n"
        if commandStats.isEmpty {
            output += "  (No data)\n"
        } else {
            for (commandType, stats) in commandStats.sorted(by: { $0.key < $1.key }) {
                output += "  \(commandType):\n"
                output += "    \(stats.description.replacingOccurrences(of: "\n", with: "\n    "))\n"
            }
        }

        // Cache Metrics
        output += "\n💾 Cache Metrics\n"
        if cacheMetrics.isEmpty {
            output += "  (No data)\n"
        } else {
            for (_, metrics) in cacheMetrics.sorted(by: { $0.key < $1.key }) {
                output += "  \(metrics.description.replacingOccurrences(of: "\n", with: "\n  "))\n"
            }
        }

        // Error Counts
        output += "\n❌ Error Counts\n"
        if errorCounts.isEmpty {
            output += "  (No errors)\n"
        } else {
            for (handlerType, count) in errorCounts.sorted(by: { $0.key < $1.key }) {
                output += "  \(handlerType): \(count) errors\n"
            }
        }

        // Event Metrics
        output += "\n📡 Event Metrics (Preparatorio)\n"
        output += "  \(eventMetrics.description.replacingOccurrences(of: "\n", with: "\n  "))\n"

        output += "\n═══════════════════════════════════════════════════════\n"

        return output
    }
}
