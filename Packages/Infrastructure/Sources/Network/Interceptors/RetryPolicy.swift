import Foundation

/// Política de retry para requests fallidas.
///
/// Define la estrategia para reintentar requests que fallan
/// debido a errores transitorios de red.
public protocol RetryPolicy: Sendable {
    /// Determina si un error es elegible para retry.
    /// - Parameter error: Error a evaluar
    /// - Returns: true si el error es retriable
    func shouldRetry(error: NetworkError) -> Bool

    /// Calcula el delay antes del próximo intento.
    /// - Parameter attemptNumber: Número de intento actual (1-based)
    /// - Returns: Delay en segundos antes del retry
    func delay(forAttempt attemptNumber: Int) -> TimeInterval

    /// Máximo número de reintentos permitidos.
    var maxRetryCount: Int { get }
}

/// Política de retry con exponential backoff y jitter.
///
/// Implementa una estrategia de retry exponencial con jitter aleatorio
/// para evitar el "thundering herd problem" cuando múltiples clientes
/// reintentan simultáneamente.
///
/// ## Fórmula
/// ```
/// delay = min(baseDelay * (2 ^ (attempt - 1)) + jitter, maxDelay)
/// jitter = random(0, baseDelay * jitterFactor)
/// ```
///
/// ## Ejemplo
/// Con baseDelay=1s, maxDelay=30s, jitterFactor=0.5:
/// - Intento 1: ~1.0-1.5s
/// - Intento 2: ~2.0-2.5s
/// - Intento 3: ~4.0-4.5s
/// - Intento 4: ~8.0-8.5s
public struct ExponentialBackoffRetryPolicy: RetryPolicy {
    /// Delay base en segundos.
    public let baseDelay: TimeInterval

    /// Delay máximo en segundos.
    public let maxDelay: TimeInterval

    /// Factor de jitter (0.0 a 1.0).
    public let jitterFactor: Double

    /// Máximo número de reintentos.
    public let maxRetryCount: Int

    /// Errores que son elegibles para retry.
    public let retriableErrors: Set<RetriableErrorType>

    /// Códigos HTTP que son elegibles para retry.
    public let retriableStatusCodes: Set<Int>

    /// Inicializador con configuración completa.
    /// - Parameters:
    ///   - baseDelay: Delay base (default: 1.0)
    ///   - maxDelay: Delay máximo (default: 30.0)
    ///   - jitterFactor: Factor de jitter (default: 0.5)
    ///   - maxRetryCount: Máximo reintentos (default: 3)
    ///   - retriableErrors: Tipos de error retriables
    ///   - retriableStatusCodes: Códigos HTTP retriables
    public init(
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        jitterFactor: Double = 0.5,
        maxRetryCount: Int = 3,
        retriableErrors: Set<RetriableErrorType> = RetriableErrorType.defaultRetriable,
        retriableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.jitterFactor = min(max(jitterFactor, 0.0), 1.0)
        self.maxRetryCount = maxRetryCount
        self.retriableErrors = retriableErrors
        self.retriableStatusCodes = retriableStatusCodes
    }

    // MARK: - RetryPolicy

    public func shouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .timeout:
            return retriableErrors.contains(.timeout)

        case .networkFailure:
            return retriableErrors.contains(.networkFailure)

        case .serverError(let statusCode, _):
            return retriableStatusCodes.contains(statusCode)

        case .rateLimited:
            return retriableErrors.contains(.rateLimited)

        case .cancelled, .invalidURL, .noData, .decodingError,
             .sslError, .unauthorized, .forbidden, .notFound:
            return false
        }
    }

    public func delay(forAttempt attemptNumber: Int) -> TimeInterval {
        // Calcular delay exponencial
        let exponentialDelay = baseDelay * pow(2.0, Double(attemptNumber - 1))

        // Calcular jitter aleatorio
        let jitterRange = baseDelay * jitterFactor
        let jitter: Double
        if jitterRange > 0 {
            jitter = Double.random(in: 0..<jitterRange)
        } else {
            jitter = 0
        }

        // Aplicar límite máximo
        let totalDelay = min(exponentialDelay + jitter, maxDelay)

        return totalDelay
    }
}

/// Tipos de error que pueden ser retriables.
public enum RetriableErrorType: String, Sendable, Hashable, CaseIterable {
    case timeout
    case networkFailure
    case rateLimited
    case serverError

    /// Conjunto por defecto de errores retriables.
    public static let defaultRetriable: Set<RetriableErrorType> = [
        .timeout,
        .networkFailure,
        .rateLimited
    ]

    /// Todos los tipos de error como retriables.
    public static let all: Set<RetriableErrorType> = Set(allCases)
}

/// Interceptor que implementa retry automático con una política configurable.
///
/// Integra una `RetryPolicy` con el sistema de interceptors para
/// proporcionar retry automático transparente.
///
/// ## Uso
/// ```swift
/// let retryPolicy = ExponentialBackoffRetryPolicy(maxRetryCount: 3)
/// let retryInterceptor = RetryInterceptor(policy: retryPolicy)
/// let client = NetworkClient(interceptors: [retryInterceptor])
/// ```
public struct RetryInterceptor: RequestInterceptor {
    /// Política de retry a usar.
    public let policy: any RetryPolicy

    /// Inicializador con política personalizada.
    public init(policy: any RetryPolicy) {
        self.policy = policy
    }

    /// Inicializador con política exponential backoff por defecto.
    public init(
        maxRetryCount: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0
    ) {
        self.policy = ExponentialBackoffRetryPolicy(
            baseDelay: baseDelay,
            maxDelay: maxDelay,
            maxRetryCount: maxRetryCount
        )
    }

    // MARK: - RequestInterceptor

    public func retry(
        _ request: URLRequest,
        dueTo error: NetworkError,
        context: RequestContext
    ) async -> RetryDecision {
        // Verificar límite de reintentos
        guard context.attemptNumber <= policy.maxRetryCount else {
            return .doNotRetry
        }

        // Verificar si el error es retriable
        guard policy.shouldRetry(error: error) else {
            return .doNotRetry
        }

        // Caso especial: rate limiting con Retry-After
        if case .rateLimited(let retryAfter) = error, let delay = retryAfter {
            return .retryAfter(delay)
        }

        // Calcular delay según la política
        let delay = policy.delay(forAttempt: context.attemptNumber)

        return .retryAfter(delay)
    }
}

// MARK: - Predefined Policies

extension ExponentialBackoffRetryPolicy {
    /// Política agresiva con reintentos rápidos.
    /// Ideal para operaciones críticas de baja latencia.
    public static var aggressive: ExponentialBackoffRetryPolicy {
        ExponentialBackoffRetryPolicy(
            baseDelay: 0.5,
            maxDelay: 10.0,
            jitterFactor: 0.3,
            maxRetryCount: 5
        )
    }

    /// Política conservadora con delays más largos.
    /// Ideal para operaciones en background.
    public static var conservative: ExponentialBackoffRetryPolicy {
        ExponentialBackoffRetryPolicy(
            baseDelay: 2.0,
            maxDelay: 60.0,
            jitterFactor: 0.5,
            maxRetryCount: 3
        )
    }

    /// Política estándar balanceada.
    public static var standard: ExponentialBackoffRetryPolicy {
        ExponentialBackoffRetryPolicy()
    }

    /// Sin reintentos.
    public static var none: ExponentialBackoffRetryPolicy {
        ExponentialBackoffRetryPolicy(maxRetryCount: 0)
    }
}

// MARK: - Linear Backoff Policy

/// Política de retry con backoff lineal.
///
/// El delay aumenta linealmente con cada intento.
public struct LinearBackoffRetryPolicy: RetryPolicy {
    public let baseDelay: TimeInterval
    public let delayIncrement: TimeInterval
    public let maxDelay: TimeInterval
    public let maxRetryCount: Int
    public let retriableErrors: Set<RetriableErrorType>

    public init(
        baseDelay: TimeInterval = 1.0,
        delayIncrement: TimeInterval = 1.0,
        maxDelay: TimeInterval = 10.0,
        maxRetryCount: Int = 3,
        retriableErrors: Set<RetriableErrorType> = RetriableErrorType.defaultRetriable
    ) {
        self.baseDelay = baseDelay
        self.delayIncrement = delayIncrement
        self.maxDelay = maxDelay
        self.maxRetryCount = maxRetryCount
        self.retriableErrors = retriableErrors
    }

    public func shouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .timeout:
            return retriableErrors.contains(.timeout)
        case .networkFailure:
            return retriableErrors.contains(.networkFailure)
        case .rateLimited:
            return retriableErrors.contains(.rateLimited)
        case .serverError:
            return retriableErrors.contains(.serverError)
        default:
            return false
        }
    }

    public func delay(forAttempt attemptNumber: Int) -> TimeInterval {
        let linearDelay = baseDelay + (delayIncrement * Double(attemptNumber - 1))
        return min(linearDelay, maxDelay)
    }
}

// MARK: - Fixed Delay Policy

/// Política de retry con delay fijo.
///
/// Siempre espera el mismo tiempo entre intentos.
public struct FixedDelayRetryPolicy: RetryPolicy {
    public let delay: TimeInterval
    public let maxRetryCount: Int
    public let retriableErrors: Set<RetriableErrorType>

    public init(
        delay: TimeInterval = 1.0,
        maxRetryCount: Int = 3,
        retriableErrors: Set<RetriableErrorType> = RetriableErrorType.defaultRetriable
    ) {
        self.delay = delay
        self.maxRetryCount = maxRetryCount
        self.retriableErrors = retriableErrors
    }

    public func shouldRetry(error: NetworkError) -> Bool {
        switch error {
        case .timeout:
            return retriableErrors.contains(.timeout)
        case .networkFailure:
            return retriableErrors.contains(.networkFailure)
        case .rateLimited:
            return retriableErrors.contains(.rateLimited)
        case .serverError:
            return retriableErrors.contains(.serverError)
        default:
            return false
        }
    }

    public func delay(forAttempt attemptNumber: Int) -> TimeInterval {
        delay
    }
}
