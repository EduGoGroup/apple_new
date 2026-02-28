import Foundation

/// Estados del circuit breaker.
public enum CircuitBreakerState: String, Sendable {
    case closed
    case open
    case halfOpen
}

/// Error cuando el circuit breaker está abierto.
public struct CircuitBreakerOpenError: Error, Sendable {
    public let resetTimeout: TimeInterval
    public let failureCount: Int
}

/// Configuración del circuit breaker.
public struct CircuitBreakerConfig: Sendable {
    public let failureThreshold: Int
    public let resetTimeout: TimeInterval
    public let halfOpenMaxAttempts: Int

    public init(
        failureThreshold: Int = 5,
        resetTimeout: TimeInterval = 30,
        halfOpenMaxAttempts: Int = 1
    ) {
        self.failureThreshold = failureThreshold
        self.resetTimeout = resetTimeout
        self.halfOpenMaxAttempts = halfOpenMaxAttempts
    }

    public static let `default` = CircuitBreakerConfig()

    public static let aggressive = CircuitBreakerConfig(
        failureThreshold: 3,
        resetTimeout: 15,
        halfOpenMaxAttempts: 1
    )

    public static let conservative = CircuitBreakerConfig(
        failureThreshold: 10,
        resetTimeout: 60,
        halfOpenMaxAttempts: 2
    )
}

/// Circuit breaker para proteger contra fallos en cascada.
///
/// Implementa el patrón Circuit Breaker con tres estados:
/// - **closed**: Operación normal, se monitorean fallos
/// - **open**: Rechaza requests inmediatamente tras alcanzar el umbral de fallos
/// - **halfOpen**: Permite un número limitado de requests de prueba
public actor CircuitBreaker {
    private let config: CircuitBreakerConfig
    private var state: CircuitBreakerState = .closed
    private var failureCount: Int = 0
    private var lastFailureTime: Date?
    private var halfOpenAttempts: Int = 0

    public init(config: CircuitBreakerConfig = .default) {
        self.config = config
    }

    /// Estado actual del circuit breaker.
    public var currentState: CircuitBreakerState {
        state
    }

    /// Ejecuta una operación protegida por el circuit breaker.
    public func execute<T: Sendable>(
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        // Check if we should transition from open to half-open
        if state == .open {
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) >= config.resetTimeout {
                state = .halfOpen
                halfOpenAttempts = 0
            } else {
                throw CircuitBreakerOpenError(
                    resetTimeout: config.resetTimeout,
                    failureCount: failureCount
                )
            }
        }

        // Check half-open attempt limit
        if state == .halfOpen && halfOpenAttempts >= config.halfOpenMaxAttempts {
            throw CircuitBreakerOpenError(
                resetTimeout: config.resetTimeout,
                failureCount: failureCount
            )
        }

        do {
            if state == .halfOpen {
                halfOpenAttempts += 1
            }

            let result = try await operation()

            // Success: reset to closed
            recordSuccess()

            return result
        } catch {
            // CancellationError should not trip the circuit breaker
            if !(error is CancellationError) {
                recordFailure()
            }
            throw error
        }
    }

    /// Resetea el circuit breaker al estado cerrado.
    public func reset() {
        state = .closed
        failureCount = 0
        lastFailureTime = nil
        halfOpenAttempts = 0
    }

    private func recordSuccess() {
        failureCount = 0
        state = .closed
        halfOpenAttempts = 0
    }

    private func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()

        if state == .halfOpen {
            state = .open
        } else if failureCount >= config.failureThreshold {
            state = .open
        }
    }
}
