import Foundation

// MARK: - Supporting Types (Top Level)

/// Estrategia de retry para operaciones fallidas.
public enum TaskRetryStrategy: Sendable {
    /// Sin reintentos.
    case none

    /// Reintentos con delay fijo.
    case fixed(delay: Duration, maxAttempts: Int)

    /// Reintentos con backoff exponencial.
    case exponential(baseDelay: Duration, maxDelay: Duration, maxAttempts: Int)

    /// Delay para un intento específico.
    func delay(forAttempt attempt: Int) -> Duration? {
        switch self {
        case .none:
            return nil
        case .fixed(let delay, let maxAttempts):
            guard attempt < maxAttempts else { return nil }
            return delay
        case .exponential(let baseDelay, let maxDelay, let maxAttempts):
            guard attempt < maxAttempts else { return nil }
            let exponentialSeconds = Double(baseDelay.components.seconds) * pow(2.0, Double(attempt - 1))
            let cappedSeconds = min(exponentialSeconds, Double(maxDelay.components.seconds))
            return .seconds(Int64(cappedSeconds))
        }
    }

    /// Número máximo de intentos.
    var maxAttempts: Int {
        switch self {
        case .none:
            return 1
        case .fixed(_, let max), .exponential(_, _, let max):
            return max
        }
    }
}

/// Opciones de configuración para ejecución batch.
public struct TaskBatchOptions: Sendable {
    /// Configuración del task group.
    public let configuration: TaskGroupConfiguration

    /// Estrategia de retry para operaciones individuales.
    public let retryStrategy: TaskRetryStrategy

    /// Si es true, lanza excepción si hay cualquier fallo.
    public let throwOnAnyFailure: Bool

    /// Inicializa las opciones batch.
    /// - Parameters:
    ///   - configuration: Configuración del task group
    ///   - retryStrategy: Estrategia de retry
    ///   - throwOnAnyFailure: Lanzar si hay fallos
    public init(
        configuration: TaskGroupConfiguration = .default,
        retryStrategy: TaskRetryStrategy = .none,
        throwOnAnyFailure: Bool = false
    ) {
        self.configuration = configuration
        self.retryStrategy = retryStrategy
        self.throwOnAnyFailure = throwOnAnyFailure
    }

    /// Opciones por defecto.
    public static let `default` = TaskBatchOptions()

    /// Opciones estrictas que fallan ante cualquier error.
    public static let strict = TaskBatchOptions(throwOnAnyFailure: true)

    /// Opciones con timeout estándar de 30 segundos.
    public static let withTimeout = TaskBatchOptions(
        configuration: .standard
    )

    /// Opciones con reintentos exponenciales.
    public static let withRetry = TaskBatchOptions(
        retryStrategy: .exponential(
            baseDelay: .seconds(1),
            maxDelay: .seconds(30),
            maxAttempts: 3
        )
    )
}

/// Métricas de ejecución del coordinador.
public struct CoordinatorMetrics: Sendable {
    /// Total de operaciones ejecutadas.
    public let totalOperations: Int

    /// Operaciones exitosas.
    public let successes: Int

    /// Operaciones fallidas.
    public let failures: Int

    /// Tasa de éxito (0.0 - 1.0).
    public var successRate: Double {
        guard totalOperations > 0 else { return 0 }
        return Double(successes) / Double(totalOperations)
    }
}

// MARK: - TaskGroupCoordinator

/// Actor genérico que coordina la ejecución de operaciones batch usando task groups.
///
/// `TaskGroupCoordinator` encapsula la lógica de coordinación de task groups para
/// operaciones batch, centralizando el manejo de concurrencia estructurada,
/// agregación de errores, y cancelación siguiendo los patrones establecidos
/// en el módulo Network.
///
/// ## Características
///
/// - **Actor Isolation**: Garantiza thread-safety mediante Swift actors
/// - **Error Aggregation**: Recolecta errores parciales manteniendo resultados exitosos
/// - **Cancellation Support**: Propaga cancelación a todas las child tasks
/// - **Configurable Timeout**: Timeout sin race conditions
/// - **Retry Support**: Reintentos con backoff exponencial
///
/// ## Ejemplo de Uso
///
/// ```swift
/// // Crear coordinador
/// let coordinator = TaskGroupCoordinator<Data>()
///
/// // Ejecutar batch de operaciones
/// let urls = ["https://api.example.com/1", "https://api.example.com/2"]
/// let operations: [@Sendable () async throws -> Data] = urls.map { url in
///     { try await fetchData(from: url) }
/// }
///
/// // Opción 1: Ejecutar y fallar si hay cualquier error
/// let results = try await coordinator.executeBatch(operations)
///
/// // Opción 2: Ejecutar recolectando errores parciales
/// let batchResult = await coordinator.executeBatchCollecting(operations)
/// if batchResult.hasPartialSuccess {
///     print("Algunos fallaron: \(batchResult.failures.count)")
/// }
///
/// // Opción 3: Ejecutar con reintentos
/// let result = try await coordinator.executeWithRetry(maxAttempts: 3) {
///     try await riskyOperation()
/// }
/// ```
///
/// ## Thread Safety
///
/// Como actor, todas las operaciones son serializadas automáticamente.
/// Los closures de operación deben ser `@Sendable` para garantizar
/// seguridad en contextos concurrentes.
public actor TaskGroupCoordinator<T: Sendable> {

    // MARK: - Type Aliases

    /// Alias para compatibilidad con código existente.
    public typealias RetryStrategy = TaskRetryStrategy

    /// Alias para compatibilidad con código existente.
    public typealias BatchOptions = TaskBatchOptions

    // MARK: - Properties

    /// Configuración actual del coordinador.
    public private(set) var defaultOptions: TaskBatchOptions

    /// Contador de operaciones ejecutadas (para métricas).
    public private(set) var totalOperationsExecuted: Int = 0

    /// Contador de operaciones exitosas.
    public private(set) var totalSuccesses: Int = 0

    /// Contador de operaciones fallidas.
    public private(set) var totalFailures: Int = 0

    // MARK: - Initialization

    /// Inicializa el coordinador con opciones por defecto.
    /// - Parameter defaultOptions: Opciones a usar cuando no se especifican
    public init(defaultOptions: TaskBatchOptions = .default) {
        self.defaultOptions = defaultOptions
    }

    // MARK: - Public Methods

    /// Ejecuta un batch de operaciones en paralelo.
    ///
    /// Todas las operaciones se ejecutan concurrentemente y se espera
    /// a que todas completen. Si alguna falla, se lanza el error apropiado
    /// dependiendo de la configuración.
    ///
    /// - Parameters:
    ///   - operations: Array de closures async a ejecutar
    ///   - options: Opciones de ejecución (usa defaultOptions si nil)
    /// - Returns: Array de resultados en el mismo orden que las operaciones
    /// - Throws: `TaskGroupError` si hay fallos según la configuración
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// let results = try await coordinator.executeBatch([
    ///     { try await fetchUser(id: 1) },
    ///     { try await fetchUser(id: 2) },
    ///     { try await fetchUser(id: 3) }
    /// ])
    /// ```
    public func executeBatch(
        _ operations: [@Sendable () async throws -> T],
        options: TaskBatchOptions? = nil
    ) async throws -> [T] {
        let opts = options ?? defaultOptions

        guard !operations.isEmpty else {
            throw TaskGroupError.emptyBatch
        }

        // Verificar cancelación antes de empezar
        try Task.checkCancellation()

        let batchResult = await executeBatchCollecting(operations, options: opts)

        // Actualizar métricas
        totalOperationsExecuted += batchResult.totalCount
        totalSuccesses += batchResult.successes.count
        totalFailures += batchResult.failures.count

        // Manejar resultados según configuración
        if batchResult.allSucceeded {
            return batchResult.values
        }

        if batchResult.allFailed {
            throw TaskGroupError.allFailed(errors: batchResult.errors)
        }

        // Resultados parciales
        if opts.throwOnAnyFailure {
            throw TaskGroupError.partialFailure(
                successCount: batchResult.successes.count,
                errors: batchResult.errors
            )
        }

        // Retornar solo éxitos (el llamador puede usar executeBatchCollecting si necesita errores)
        return batchResult.values
    }

    /// Ejecuta un batch de operaciones recolectando tanto éxitos como fallos.
    ///
    /// A diferencia de `executeBatch`, este método nunca lanza excepciones
    /// por fallos en las operaciones individuales. En su lugar, retorna
    /// un `BatchResult` con todos los resultados.
    ///
    /// - Parameters:
    ///   - operations: Array de closures async a ejecutar
    ///   - options: Opciones de ejecución
    /// - Returns: BatchResult con éxitos, fallos y métricas
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// let result = await coordinator.executeBatchCollecting([
    ///     { try await uploadFile(file1) },
    ///     { try await uploadFile(file2) },
    ///     { try await uploadFile(file3) }
    /// ])
    ///
    /// if result.hasPartialSuccess {
    ///     // Reintentar solo los fallos
    ///     let failedIndices = result.failures.map { $0.index }
    /// }
    /// ```
    public func executeBatchCollecting(
        _ operations: [@Sendable () async throws -> T],
        options: TaskBatchOptions? = nil
    ) async -> BatchResult<T> {
        let opts = options ?? defaultOptions

        guard !operations.isEmpty else {
            return BatchResult(
                successes: [],
                failures: [],
                duration: .zero
            )
        }

        // Si hay estrategia de retry, envolver operaciones
        let wrappedOperations: [@Sendable () async throws -> T]
        if case .none = opts.retryStrategy {
            wrappedOperations = operations
        } else {
            wrappedOperations = operations.map { operation in
                { [retryStrategy = opts.retryStrategy] in
                    try await Self.executeWithRetryStatic(
                        maxAttempts: retryStrategy.maxAttempts,
                        strategy: retryStrategy,
                        operation: operation
                    )
                }
            }
        }

        return await withTaskGroupCollectingResults(
            configuration: opts.configuration,
            operations: wrappedOperations
        )
    }

    /// Ejecuta un batch con límite de concurrencia.
    ///
    /// Útil cuando se necesita limitar el número de operaciones
    /// concurrentes para evitar sobrecargar recursos.
    ///
    /// - Parameters:
    ///   - operations: Array de closures async a ejecutar
    ///   - maxConcurrency: Número máximo de operaciones simultáneas
    ///   - options: Opciones adicionales
    /// - Returns: Array de resultados en orden
    /// - Throws: `TaskGroupError` si hay fallos
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// // Máximo 5 requests simultáneas
    /// let results = try await coordinator.executeBatch(
    ///     operations,
    ///     maxConcurrency: 5
    /// )
    /// ```
    public func executeBatch(
        _ operations: [@Sendable () async throws -> T],
        maxConcurrency: Int,
        options: TaskBatchOptions? = nil
    ) async throws -> [T] {
        let opts = options ?? defaultOptions
        let newOptions = TaskBatchOptions(
            configuration: TaskGroupConfiguration(
                timeout: opts.configuration.timeout,
                cancelOnFirstError: opts.configuration.cancelOnFirstError,
                maxConcurrency: maxConcurrency
            ),
            retryStrategy: opts.retryStrategy,
            throwOnAnyFailure: opts.throwOnAnyFailure
        )
        return try await executeBatch(operations, options: newOptions)
    }

    /// Ejecuta una operación con reintentos automáticos.
    ///
    /// La operación se reintenta según la estrategia configurada
    /// hasta que tenga éxito o se agoten los intentos.
    ///
    /// - Parameters:
    ///   - maxAttempts: Número máximo de intentos
    ///   - strategy: Estrategia de retry (default: exponential)
    ///   - operation: Closure async a ejecutar
    /// - Returns: Resultado de la operación exitosa
    /// - Throws: `TaskGroupError.maxRetriesExceeded` si se agotan los intentos
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// let data = try await coordinator.executeWithRetry(maxAttempts: 3) {
    ///     try await fetchData(from: url)
    /// }
    /// ```
    public func executeWithRetry(
        maxAttempts: Int = 3,
        strategy: TaskRetryStrategy? = nil,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        let effectiveStrategy = strategy ?? .exponential(
            baseDelay: .seconds(1),
            maxDelay: .seconds(30),
            maxAttempts: maxAttempts
        )

        return try await Self.executeWithRetryStatic(
            maxAttempts: maxAttempts,
            strategy: effectiveStrategy,
            operation: operation
        )
    }

    /// Resetea las métricas del coordinador.
    public func resetMetrics() {
        totalOperationsExecuted = 0
        totalSuccesses = 0
        totalFailures = 0
    }

    /// Actualiza las opciones por defecto.
    /// - Parameter options: Nuevas opciones por defecto
    public func updateDefaultOptions(_ options: TaskBatchOptions) {
        defaultOptions = options
    }

    // MARK: - Private Static Methods

    private static func executeWithRetryStatic(
        maxAttempts: Int,
        strategy: TaskRetryStrategy,
        operation: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: (any Error)?
        var attempt = 1

        while attempt <= maxAttempts {
            // Verificar cancelación
            try Task.checkCancellation()

            do {
                return try await operation()
            } catch {
                lastError = error

                // No reintentar si es cancelación
                if error is CancellationError {
                    throw TaskGroupError.cancelled
                }

                // Verificar si hay más intentos
                guard attempt < maxAttempts else { break }

                // Calcular delay
                if let delay = strategy.delay(forAttempt: attempt) {
                    try await Task.sleep(for: delay)
                }

                attempt += 1
            }
        }

        throw TaskGroupError.maxRetriesExceeded(
            attempts: attempt,
            lastError: WrappedError(lastError ?? CancellationError())
        )
    }
}

// MARK: - Convenience Extensions

extension TaskGroupCoordinator {
    /// Ejecuta operaciones y mapea los resultados.
    ///
    /// - Parameters:
    ///   - operations: Array de closures a ejecutar
    ///   - transform: Función de transformación para cada resultado
    /// - Returns: Array de resultados transformados
    public func executeBatchAndMap<U: Sendable>(
        _ operations: [@Sendable () async throws -> T],
        transform: @Sendable (T) -> U
    ) async throws -> [U] {
        let results = try await executeBatch(operations)
        return results.map(transform)
    }

    /// Ejecuta operaciones filtrando resultados nulos.
    ///
    /// - Parameter operations: Array de closures que pueden retornar nil
    /// - Returns: Array de resultados no nulos
    public func executeBatchCompact(
        _ operations: [@Sendable () async throws -> T?]
    ) async throws -> [T] where T: Sendable {
        let coordinator = TaskGroupCoordinator<T?>()
        let results = try await coordinator.executeBatch(operations)
        return results.compactMap { $0 }
    }
}

// MARK: - Metrics

extension TaskGroupCoordinator {
    /// Métricas actuales del coordinador.
    public var metrics: CoordinatorMetrics {
        CoordinatorMetrics(
            totalOperations: totalOperationsExecuted,
            successes: totalSuccesses,
            failures: totalFailures
        )
    }
}
