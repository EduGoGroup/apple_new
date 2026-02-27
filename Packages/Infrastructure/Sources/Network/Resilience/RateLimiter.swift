import Foundation

/// Error cuando se excede el rate limit.
public struct RateLimitExceededError: Error, Sendable {
    public let retryAfter: TimeInterval
}

/// Configuración del rate limiter.
public struct RateLimiterConfig: Sendable {
    public let maxRequests: Int
    public let windowDuration: TimeInterval

    public init(maxRequests: Int, windowDuration: TimeInterval) {
        self.maxRequests = maxRequests
        self.windowDuration = windowDuration
    }

    /// 60 requests por minuto.
    public static let standard = RateLimiterConfig(maxRequests: 60, windowDuration: 60)

    /// 30 requests por minuto (conservador).
    public static let conservative = RateLimiterConfig(maxRequests: 30, windowDuration: 60)

    /// 120 requests por minuto (agresivo).
    public static let aggressive = RateLimiterConfig(maxRequests: 120, windowDuration: 60)
}

/// Rate limiter con sliding window para controlar la frecuencia de requests.
public actor RateLimiter {
    private let config: RateLimiterConfig
    private var requestTimestamps: [Date] = []

    public init(config: RateLimiterConfig = .standard) {
        self.config = config
    }

    /// Adquiere permiso para hacer un request. Espera si es necesario.
    public func acquire() async throws {
        cleanExpiredTimestamps()

        if requestTimestamps.count < config.maxRequests {
            requestTimestamps.append(Date())
            return
        }

        // Calculate wait time until oldest request expires
        guard let oldest = requestTimestamps.first else { return }
        let waitTime = config.windowDuration - Date().timeIntervalSince(oldest)

        if waitTime > 0 {
            try await Task.sleep(for: .seconds(waitTime))
            cleanExpiredTimestamps()
        }

        requestTimestamps.append(Date())
    }

    /// Intenta adquirir permiso sin esperar.
    public func tryAcquire() -> Bool {
        cleanExpiredTimestamps()

        if requestTimestamps.count < config.maxRequests {
            requestTimestamps.append(Date())
            return true
        }

        return false
    }

    /// Número de requests disponibles en la ventana actual.
    public var availableRequests: Int {
        var timestamps = requestTimestamps
        let cutoff = Date().addingTimeInterval(-config.windowDuration)
        timestamps.removeAll { $0 < cutoff }
        return max(0, config.maxRequests - timestamps.count)
    }

    private func cleanExpiredTimestamps() {
        let cutoff = Date().addingTimeInterval(-config.windowDuration)
        requestTimestamps.removeAll { $0 < cutoff }
    }
}
