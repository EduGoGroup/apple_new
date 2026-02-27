import Foundation

/// Actor que maneja timeout y cancelación cooperativa para operaciones async.
///
/// `CancellationHandler` proporciona una forma segura y ergonómica de ejecutar
/// operaciones con timeout configurable, garantizando la cancelación cooperativa
/// de child tasks y cleanup de recursos parciales.
///
/// ## Características
///
/// - **Timeout configurable**: Por operación o usando defaults
/// - **Cancelación cooperativa**: Propaga `Task.isCancelled` a todas las child tasks
/// - **Cleanup de recursos**: Ejecuta handlers de cleanup en timeout/cancelación
/// - **Sin race conditions**: Usa structured concurrency para evitar leaks
/// - **Thread-safe**: Actor isolation garantiza acceso seguro
///
/// ## Ejemplo de Uso
///
/// ```swift
/// let handler = CancellationHandler()
///
/// // Operación simple con timeout
/// let result = try await handler.withTimeout(.seconds(30)) {
///     try await fetchData(from: url)
/// }
///
/// // Con cleanup handler
/// let data = try await handler.withTimeout(
///     .seconds(60),
///     onCancellation: { partialData in
///         await cleanupPartialData(partialData)
///     }
/// ) {
///     try await downloadLargeFile()
/// }
///
/// // Verificación de cancelación
/// try await handler.checkCancellation()
/// ```
///
/// ## Thread Safety
///
/// Como actor, todas las operaciones de configuración son serializadas.
/// Sin embargo, las operaciones con timeout ejecutan el trabajo en el
/// contexto del llamador para evitar deadlocks.
public actor CancellationHandler {

    // MARK: - Configuration

    /// Configuración de timeout por defecto.
    public struct Configuration: Sendable {
        /// Timeout por defecto para operaciones individuales.
        public let defaultTimeout: Duration

        /// Timeout por defecto para operaciones batch.
        public let defaultBatchTimeout: Duration

        /// Si es true, propaga la cancelación inmediatamente al detectarla.
        public let propagateImmediately: Bool

        /// Inicializa la configuración.
        /// - Parameters:
        ///   - defaultTimeout: Timeout individual (default: 30s)
        ///   - defaultBatchTimeout: Timeout batch (default: 120s)
        ///   - propagateImmediately: Propagar cancelación inmediatamente (default: true)
        public init(
            defaultTimeout: Duration = .seconds(30),
            defaultBatchTimeout: Duration = .seconds(120),
            propagateImmediately: Bool = true
        ) {
            self.defaultTimeout = defaultTimeout
            self.defaultBatchTimeout = defaultBatchTimeout
            self.propagateImmediately = propagateImmediately
        }

        /// Configuración por defecto.
        public static let `default` = Configuration()

        /// Configuración conservadora con timeouts largos.
        public static let conservative = Configuration(
            defaultTimeout: .seconds(60),
            defaultBatchTimeout: .seconds(300)
        )

        /// Configuración agresiva con timeouts cortos.
        public static let aggressive = Configuration(
            defaultTimeout: .seconds(10),
            defaultBatchTimeout: .seconds(30)
        )
    }

    // MARK: - Properties

    /// Configuración actual del handler.
    public private(set) var configuration: Configuration

    /// Contador de operaciones con timeout ejecutadas.
    public private(set) var totalOperations: Int = 0

    /// Contador de timeouts ocurridos.
    public private(set) var totalTimeouts: Int = 0

    /// Contador de cancelaciones ocurridas.
    public private(set) var totalCancellations: Int = 0

    // MARK: - Initialization

    /// Inicializa el handler con configuración opcional.
    /// - Parameter configuration: Configuración a usar (default: .default)
    public init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Public Methods

    /// Ejecuta una operación con timeout.
    ///
    /// La operación se ejecuta con un límite de tiempo. Si el timeout se alcanza
    /// antes de que la operación complete, se cancela la operación y se lanza
    /// `CancellationReason.timeout`.
    ///
    /// - Parameters:
    ///   - timeout: Duración máxima para la operación (usa default si nil)
    ///   - operation: Closure async a ejecutar
    /// - Returns: Resultado de la operación si completa a tiempo
    /// - Throws: `CancellationReason.timeout` si se excede el tiempo,
    ///           `CancellationReason.parentTaskCancelled` si la tarea padre se cancela,
    ///           o cualquier error que lance la operación
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// let data = try await handler.withTimeout(.seconds(30)) {
    ///     try await fetchData(from: url)
    /// }
    /// ```
    public func withTimeout<T: Sendable>(
        _ timeout: Duration? = nil,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let effectiveTimeout = timeout ?? configuration.defaultTimeout

        // Incrementar contador
        totalOperations += 1

        // Verificar cancelación antes de empezar
        if Task.isCancelled {
            totalCancellations += 1
            throw CancellationReason.parentTaskCancelled
        }

        do {
            return try await executeWithTimeout(
                timeout: effectiveTimeout,
                operation: operation
            )
        } catch let error as CancellationReason where error.isTimeout {
            totalTimeouts += 1
            throw error
        } catch is CancellationError {
            totalCancellations += 1
            throw CancellationReason.parentTaskCancelled
        }
    }

    /// Ejecuta una operación con timeout y cleanup handler.
    ///
    /// Similar a `withTimeout(_:operation:)`, pero permite especificar
    /// un handler que se ejecuta si la operación es cancelada o expira.
    /// Útil para cleanup de recursos parciales.
    ///
    /// - Parameters:
    ///   - timeout: Duración máxima para la operación
    ///   - onCancellation: Handler a ejecutar en caso de cancelación/timeout
    ///   - operation: Closure async a ejecutar
    /// - Returns: Resultado de la operación si completa a tiempo
    /// - Throws: Error de timeout, cancelación, o de la operación
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// let result = try await handler.withTimeout(
    ///     .seconds(60),
    ///     onCancellation: {
    ///         await cleanupTempFiles()
    ///     }
    /// ) {
    ///     try await processLargeDataset()
    /// }
    /// ```
    public func withTimeout<T: Sendable>(
        _ timeout: Duration? = nil,
        onCancellation: @Sendable @escaping () async -> Void,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        do {
            return try await withTimeout(timeout, operation: operation)
        } catch {
            // Ejecutar cleanup en caso de error
            if error is CancellationReason || error is CancellationError {
                await onCancellation()
            }
            throw error
        }
    }

    /// Ejecuta una operación batch con timeout específico para batches.
    ///
    /// Usa el `defaultBatchTimeout` de la configuración, que típicamente
    /// es más largo que el timeout individual.
    ///
    /// - Parameters:
    ///   - timeout: Timeout opcional (usa defaultBatchTimeout si nil)
    ///   - operation: Operación batch a ejecutar
    /// - Returns: Resultado del batch
    /// - Throws: Error de timeout, cancelación, o del batch
    public func withBatchTimeout<T: Sendable>(
        _ timeout: Duration? = nil,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        let effectiveTimeout = timeout ?? configuration.defaultBatchTimeout
        return try await withTimeout(effectiveTimeout, operation: operation)
    }

    /// Verifica si la tarea actual está cancelada y lanza si es así.
    ///
    /// Wrapper conveniente sobre `Task.checkCancellation()` que lanza
    /// `CancellationReason.parentTaskCancelled` en lugar del error estándar.
    ///
    /// - Throws: `CancellationReason.parentTaskCancelled` si la tarea está cancelada
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// for item in items {
    ///     try await handler.checkCancellation()
    ///     try await process(item)
    /// }
    /// ```
    public func checkCancellation() throws {
        if Task.isCancelled {
            totalCancellations += 1
            throw CancellationReason.parentTaskCancelled
        }
    }

    /// Verifica cancelación de forma no-throwing.
    ///
    /// - Returns: `CancellationReason` si está cancelado, nil si no
    public func checkCancellationSafe() -> CancellationReason? {
        if Task.isCancelled {
            totalCancellations += 1
            return .parentTaskCancelled
        }
        return nil
    }

    /// Actualiza la configuración del handler.
    /// - Parameter configuration: Nueva configuración
    public func updateConfiguration(_ configuration: Configuration) {
        self.configuration = configuration
    }

    /// Resetea las métricas del handler.
    public func resetMetrics() {
        totalOperations = 0
        totalTimeouts = 0
        totalCancellations = 0
    }

    // MARK: - Metrics

    /// Tasa de timeouts (timeouts / operaciones totales).
    public var timeoutRate: Double {
        guard totalOperations > 0 else { return 0 }
        return Double(totalTimeouts) / Double(totalOperations)
    }

    /// Tasa de cancelaciones (cancelaciones / operaciones totales).
    public var cancellationRate: Double {
        guard totalOperations > 0 else { return 0 }
        return Double(totalCancellations) / Double(totalOperations)
    }

    // MARK: - Private Methods

    private func executeWithTimeout<T: Sendable>(
        timeout: Duration,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        // Usamos withThrowingTaskGroup para race entre operación y timeout
        try await withThrowingTaskGroup(of: TimeoutResult<T>.self) { group in
            // Task de timeout
            group.addTask {
                try await Task.sleep(for: timeout)
                return .timeout
            }

            // Task de operación
            group.addTask {
                let result = try await operation()
                return .result(result)
            }

            // Esperamos el primero que complete
            guard let first = try await group.next() else {
                // No debería pasar, pero por seguridad
                throw CancellationReason.systemCancelled(reason: "No task completed")
            }

            // Cancelamos el resto
            group.cancelAll()

            switch first {
            case .timeout:
                // El timeout ganó la race
                throw CancellationReason.timeout(duration: Double(timeout.components.seconds))

            case .result(let value):
                return value
            }
        }
    }
}

// MARK: - Internal Types

/// Resultado interno para race entre timeout y operación.
/// Usado tanto por CancellationHandler como por las funciones globales de timeout.
enum TimeoutResult<T: Sendable>: Sendable {
    case timeout
    case result(T)
}

// MARK: - Global Convenience Functions

/// Ejecuta una operación con timeout usando un handler por defecto.
///
/// Función de conveniencia para operaciones que no necesitan un handler
/// persistente con métricas.
///
/// - Parameters:
///   - timeout: Duración máxima para la operación
///   - operation: Closure async a ejecutar
/// - Returns: Resultado de la operación
/// - Throws: `CancellationReason.timeout` o error de la operación
///
/// ## Ejemplo
///
/// ```swift
/// let data = try await withTimeout(.seconds(30)) {
///     try await fetchData(from: url)
/// }
/// ```
public func withTimeout<T: Sendable>(
    _ timeout: Duration,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    // Verificar cancelación antes de empezar
    try Task.checkCancellation()

    return try await withThrowingTaskGroup(of: TimeoutResult<T>.self) { group in
        // Task de timeout
        group.addTask {
            try await Task.sleep(for: timeout)
            return .timeout
        }

        // Task de operación
        group.addTask {
            let result = try await operation()
            return .result(result)
        }

        // Esperamos el primero que complete
        guard let first = try await group.next() else {
            throw CancellationReason.systemCancelled(reason: "No task completed")
        }

        // Cancelamos el resto
        group.cancelAll()

        switch first {
        case .timeout:
            throw CancellationReason.timeout(duration: Double(timeout.components.seconds))

        case .result(let value):
            return value
        }
    }
}

/// Ejecuta una operación con timeout y cleanup handler.
///
/// - Parameters:
///   - timeout: Duración máxima
///   - onCancellation: Handler de cleanup
///   - operation: Operación a ejecutar
/// - Returns: Resultado de la operación
/// - Throws: Error de timeout, cancelación, o de la operación
public func withTimeout<T: Sendable>(
    _ timeout: Duration,
    onCancellation: @Sendable @escaping () async -> Void,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    do {
        return try await withTimeout(timeout, operation: operation)
    } catch {
        if error is CancellationReason || error is CancellationError {
            await onCancellation()
        }
        throw error
    }
}

// MARK: - Persistence Namespace

/// Namespace para funciones de utilidad de persistencia.
public enum Persistence {
    /// Ejecuta una operación con timeout.
    ///
    /// - Parameters:
    ///   - timeout: Duración máxima
    ///   - operation: Operación a ejecutar
    /// - Returns: Resultado de la operación
    /// - Throws: Error de timeout o de la operación
    ///
    /// ## Ejemplo
    ///
    /// ```swift
    /// let result = try await Persistence.withTimeout(.seconds(30)) {
    ///     try await fetchData()
    /// }
    /// ```
    public static func withTimeout<T: Sendable>(
        _ timeout: Duration,
        operation: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        // Verificar cancelación antes de empezar
        try Task.checkCancellation()

        return try await withThrowingTaskGroup(of: TimeoutResult<T>.self) { group in
            // Task de timeout
            group.addTask {
                try await Task.sleep(for: timeout)
                return .timeout
            }

            // Task de operación
            group.addTask {
                let result = try await operation()
                return .result(result)
            }

            // Esperamos el primero que complete
            guard let first = try await group.next() else {
                throw CancellationReason.systemCancelled(reason: "No task completed")
            }

            // Cancelamos el resto
            group.cancelAll()

            switch first {
            case .timeout:
                throw CancellationReason.timeout(duration: Double(timeout.components.seconds))

            case .result(let value):
                return value
            }
        }
    }
}

// Backwards compatibility: LocalPersistence name alias
public typealias LocalPersistence = Persistence
