import Foundation

/// Configuración para operaciones de task group con timeout.
///
/// Permite especificar límites de tiempo y comportamiento de cancelación
/// para operaciones batch.
public struct TaskGroupConfiguration: Sendable {
    /// Timeout máximo para la operación completa.
    public let timeout: Duration?

    /// Si es true, cancela todas las tareas pendientes al primer error.
    public let cancelOnFirstError: Bool

    /// Número máximo de tareas concurrentes (nil = sin límite).
    public let maxConcurrency: Int?

    /// Inicializa la configuración con valores por defecto.
    /// - Parameters:
    ///   - timeout: Timeout opcional (nil = sin timeout)
    ///   - cancelOnFirstError: Cancelar al primer error (default: false)
    ///   - maxConcurrency: Límite de concurrencia (nil = sin límite)
    public init(
        timeout: Duration? = nil,
        cancelOnFirstError: Bool = false,
        maxConcurrency: Int? = nil
    ) {
        self.timeout = timeout
        self.cancelOnFirstError = cancelOnFirstError
        self.maxConcurrency = maxConcurrency
    }

    /// Configuración por defecto sin restricciones.
    public static let `default` = TaskGroupConfiguration()

    /// Configuración con timeout de 30 segundos.
    public static let standard = TaskGroupConfiguration(timeout: .seconds(30))

    /// Configuración conservadora con timeout largo y sin cancelación temprana.
    public static let conservative = TaskGroupConfiguration(
        timeout: .seconds(120),
        cancelOnFirstError: false
    )

    /// Configuración agresiva con timeout corto y cancelación temprana.
    public static let aggressive = TaskGroupConfiguration(
        timeout: .seconds(10),
        cancelOnFirstError: true
    )
}

/// Resultado de una operación individual dentro del task group.
///
/// Encapsula el resultado exitoso o el error de una operación,
/// junto con su índice para trazabilidad.
public enum TaskResult<Success: Sendable>: Sendable {
    /// Operación completada exitosamente.
    case success(index: Int, value: Success)

    /// Operación falló con error.
    case failure(index: Int, error: WrappedError)

    /// Índice de la operación.
    public var index: Int {
        switch self {
        case .success(let index, _), .failure(let index, _):
            return index
        }
    }

    /// Indica si fue exitosa.
    public var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    /// Valor si fue exitosa, nil si falló.
    public var value: Success? {
        if case .success(_, let value) = self { return value }
        return nil
    }

    /// Error si falló, nil si fue exitosa.
    public var error: WrappedError? {
        if case .failure(_, let error) = self { return error }
        return nil
    }
}

/// Resultado consolidado de una operación batch.
///
/// Contiene los resultados exitosos, los errores, y métricas
/// de la ejecución.
public struct BatchResult<T: Sendable>: Sendable {
    /// Resultados exitosos ordenados por índice original.
    public let successes: [(index: Int, value: T)]

    /// Errores ocurridos ordenados por índice original.
    public let failures: [(index: Int, error: WrappedError)]

    /// Duración total de la operación.
    public let duration: Duration

    /// Indica si todas las operaciones fueron exitosas.
    public var allSucceeded: Bool {
        failures.isEmpty
    }

    /// Indica si todas las operaciones fallaron.
    public var allFailed: Bool {
        successes.isEmpty && !failures.isEmpty
    }

    /// Indica si hubo resultados mixtos.
    public var hasPartialSuccess: Bool {
        !successes.isEmpty && !failures.isEmpty
    }

    /// Número total de operaciones.
    public var totalCount: Int {
        successes.count + failures.count
    }

    /// Tasa de éxito como porcentaje (0.0 - 1.0).
    public var successRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(successes.count) / Double(totalCount)
    }

    /// Valores exitosos en orden original (sin índices).
    public var values: [T] {
        successes.sorted { $0.index < $1.index }.map { $0.value }
    }

    /// Errores en orden original (sin índices).
    public var errors: [WrappedError] {
        failures.sorted { $0.index < $1.index }.map { $0.error }
    }

    init(
        successes: [(index: Int, value: T)],
        failures: [(index: Int, error: WrappedError)],
        duration: Duration
    ) {
        self.successes = successes.sorted { $0.index < $1.index }
        self.failures = failures.sorted { $0.index < $1.index }
        self.duration = duration
    }
}

// MARK: - Internal Timeout Signal

/// Señal interna para indicar timeout (no exponemos resultado real).
private enum TimeoutSignal<T: Sendable>: Sendable {
    case timeout
    case result(index: Int, value: T)
}

// MARK: - Task Group Extensions

/// Ejecuta operaciones en paralelo con timeout opcional.
///
/// Esta función proporciona una forma segura de ejecutar múltiples
/// operaciones concurrentes con control de timeout y cancelación.
///
/// ## Ejemplo
///
/// ```swift
/// let results = try await withThrowingTaskGroupWithTimeout(
///     timeout: .seconds(30),
///     operations: urls.enumerated().map { index, url in
///         { try await fetchData(from: url) }
///     }
/// )
/// ```
///
/// - Parameters:
///   - timeout: Duración máxima para completar todas las operaciones
///   - operations: Array de closures async que ejecutar
/// - Returns: Array de resultados en el mismo orden que las operaciones
/// - Throws: `TaskGroupError.timeout` si se excede el tiempo,
///           `TaskGroupError.cancelled` si se cancela
public func withThrowingTaskGroupWithTimeout<T: Sendable>(
    timeout: Duration,
    operations: [@Sendable () async throws -> T]
) async throws -> [T] {
    guard !operations.isEmpty else {
        return []
    }

    return try await withThrowingTaskGroup(of: TimeoutSignal<T>.self) { group in
        // Agregar task de timeout
        group.addTask {
            try await Task.sleep(for: timeout)
            return .timeout
        }

        // Agregar todas las operaciones
        for (index, operation) in operations.enumerated() {
            group.addTask {
                let value = try await operation()
                return .result(index: index, value: value)
            }
        }

        var results: [(Int, T)] = []
        results.reserveCapacity(operations.count)

        // Recolectar resultados
        while let signal = try await group.next() {
            // Verificar cancelación
            if Task.isCancelled {
                group.cancelAll()
                throw TaskGroupError.cancelled
            }

            switch signal {
            case .timeout:
                // Timeout alcanzado
                group.cancelAll()
                throw TaskGroupError.timeout(duration: Double(timeout.components.seconds))

            case .result(let index, let value):
                results.append((index, value))
                if results.count == operations.count {
                    // Todas las operaciones completadas, cancelar timeout
                    group.cancelAll()
                    break
                }
            }
        }

        // Ordenar por índice y retornar valores
        return results.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
}

/// Ejecuta operaciones en paralelo recolectando éxitos y fallos.
///
/// A diferencia de `withThrowingTaskGroup`, esta función no falla
/// al primer error, sino que continúa ejecutando todas las operaciones
/// y recolecta resultados parciales.
///
/// ## Ejemplo
///
/// ```swift
/// let batchResult = await withTaskGroupCollectingResults(
///     configuration: .standard,
///     operations: items.enumerated().map { index, item in
///         { try await process(item) }
///     }
/// )
///
/// print("Éxitos: \(batchResult.successes.count)")
/// print("Fallos: \(batchResult.failures.count)")
/// ```
///
/// - Parameters:
///   - configuration: Configuración del task group
///   - operations: Array de closures async que ejecutar
/// - Returns: BatchResult con éxitos, fallos y métricas
public func withTaskGroupCollectingResults<T: Sendable>(
    configuration: TaskGroupConfiguration = .default,
    operations: [@Sendable () async throws -> T]
) async -> BatchResult<T> {
    let startTime = ContinuousClock.now

    guard !operations.isEmpty else {
        return BatchResult(
            successes: [],
            failures: [],
            duration: ContinuousClock.now - startTime
        )
    }

    // Si hay timeout, usar race con timeout task
    if let timeout = configuration.timeout {
        return await withTaskGroupCollectingResultsWithTimeout(
            timeout: timeout,
            cancelOnFirstError: configuration.cancelOnFirstError,
            maxConcurrency: configuration.maxConcurrency,
            operations: operations,
            startTime: startTime
        )
    }

    // Sin timeout
    return await withTaskGroupCollectingResultsNoTimeout(
        cancelOnFirstError: configuration.cancelOnFirstError,
        maxConcurrency: configuration.maxConcurrency,
        operations: operations,
        startTime: startTime
    )
}

// MARK: - Private Helpers

private func withTaskGroupCollectingResultsWithTimeout<T: Sendable>(
    timeout: Duration,
    cancelOnFirstError: Bool,
    maxConcurrency: Int?,
    operations: [@Sendable () async throws -> T],
    startTime: ContinuousClock.Instant
) async -> BatchResult<T> {
    await withTaskGroup(of: TaskResult<T>?.self) { group in
        var successes: [(index: Int, value: T)] = []
        var failures: [(index: Int, error: WrappedError)] = []
        var completedCount = 0
        var timedOut = false

        // Task de timeout
        group.addTask {
            do {
                try await Task.sleep(for: timeout)
                return nil // Señal de timeout
            } catch {
                return nil // Cancelado
            }
        }

        // Agregar operaciones respetando maxConcurrency
        var pendingOperations = Array(operations.enumerated())

        func addNextOperation() {
            guard !pendingOperations.isEmpty else { return }
            let (index, operation) = pendingOperations.removeFirst()
            group.addTask {
                do {
                    let value = try await operation()
                    return .success(index: index, value: value)
                } catch {
                    return .failure(index: index, error: WrappedError(error, operationIndex: index))
                }
            }
        }

        // Agregar operaciones iniciales
        let initialCount = maxConcurrency ?? operations.count
        for _ in 0..<min(initialCount, operations.count) {
            addNextOperation()
        }

        // Recolectar resultados
        while let result = await group.next() {
            guard let taskResult = result else {
                // Timeout alcanzado
                timedOut = true
                group.cancelAll()
                break
            }

            completedCount += 1

            switch taskResult {
            case .success(let index, let value):
                successes.append((index, value))
            case .failure(let index, let error):
                failures.append((index, error))
                if cancelOnFirstError {
                    group.cancelAll()
                    break
                }
            }

            // Agregar siguiente operación si hay maxConcurrency
            if maxConcurrency != nil {
                addNextOperation()
            }

            if completedCount == operations.count {
                break
            }
        }

        // Si hubo timeout, agregar errores para operaciones no completadas
        if timedOut {
            let completedIndices = Set(successes.map { $0.index } + failures.map { $0.index })
            for (index, _) in operations.enumerated() where !completedIndices.contains(index) {
                failures.append((
                    index,
                    WrappedError(
                        description: "Operation timed out",
                        errorType: "TimeoutError",
                        operationIndex: index
                    )
                ))
            }
        }

        return BatchResult(
            successes: successes,
            failures: failures,
            duration: ContinuousClock.now - startTime
        )
    }
}

// MARK: - Enhanced Timeout Support

/// Ejecuta operaciones batch con timeout y propagación de cancelación mejorada.
///
/// Esta función extiende `withTaskGroupCollectingResults` con:
/// - Propagación activa de `Task.isCancelled` a child tasks
/// - Cleanup de recursos parciales en caso de timeout
/// - Métricas de cancelación
///
/// ## Ejemplo
///
/// ```swift
/// let result = await withCancellableTaskGroup(
///     timeout: .seconds(60),
///     onCancellation: { completedResults in
///         await cleanupPartialResults(completedResults)
///     },
///     operations: operations
/// )
/// ```
///
/// - Parameters:
///   - timeout: Timeout máximo para todas las operaciones
///   - cancelOnFirstError: Cancelar todo al primer error (default: false)
///   - maxConcurrency: Límite de concurrencia opcional
///   - onCancellation: Handler llamado con resultados parciales en cancelación
///   - operations: Array de operaciones a ejecutar
/// - Returns: BatchResult con éxitos, fallos y duración
public func withCancellableTaskGroup<T: Sendable>(
    timeout: Duration,
    cancelOnFirstError: Bool = false,
    maxConcurrency: Int? = nil,
    onCancellation: (@Sendable ([(index: Int, value: T)]) async -> Void)? = nil,
    operations: [@Sendable () async throws -> T]
) async -> BatchResult<T> {
    let startTime = ContinuousClock.now

    guard !operations.isEmpty else {
        return BatchResult(
            successes: [],
            failures: [],
            duration: ContinuousClock.now - startTime
        )
    }

    return await withTaskGroup(of: CancellableTaskResult<T>?.self) { group in
        var successes: [(index: Int, value: T)] = []
        var failures: [(index: Int, error: WrappedError)] = []
        var completedCount = 0
        var wasCancelled = false
        var wasTimeout = false

        // Task de timeout
        group.addTask {
            do {
                try await Task.sleep(for: timeout)
                return nil // Señal de timeout
            } catch {
                return nil // Cancelado
            }
        }

        // Agregar operaciones con verificación de cancelación
        var pendingOperations = Array(operations.enumerated())

        func addNextOperationWithCancellationCheck() {
            guard !pendingOperations.isEmpty else { return }
            let (index, operation) = pendingOperations.removeFirst()
            group.addTask {
                // Verificar cancelación antes de ejecutar
                if Task.isCancelled {
                    return .cancelled(index: index)
                }

                do {
                    let value = try await operation()

                    // Verificar cancelación después de ejecutar
                    if Task.isCancelled {
                        return .cancelledAfterCompletion(index: index, value: value)
                    }

                    return .success(index: index, value: value)
                } catch is CancellationError {
                    return .cancelled(index: index)
                } catch {
                    return .failure(index: index, error: WrappedError(error, operationIndex: index))
                }
            }
        }

        // Agregar operaciones iniciales
        let initialCount = maxConcurrency ?? operations.count
        for _ in 0..<min(initialCount, operations.count) {
            addNextOperationWithCancellationCheck()
        }

        // Recolectar resultados
        while let result = await group.next() {
            guard let taskResult = result else {
                // Timeout alcanzado
                wasTimeout = true
                wasCancelled = true
                group.cancelAll()
                break
            }

            completedCount += 1

            switch taskResult {
            case .success(let index, let value):
                successes.append((index, value))

            case .cancelledAfterCompletion(let index, let value):
                // La operación completó pero la task fue cancelada después
                // Aún guardamos el resultado ya que fue exitoso
                successes.append((index, value))
                wasCancelled = true

            case .failure(let index, let error):
                failures.append((index, error))
                if cancelOnFirstError {
                    wasCancelled = true
                    group.cancelAll()
                    break
                }

            case .cancelled(let index):
                failures.append((
                    index,
                    WrappedError(
                        description: "Operation was cancelled",
                        errorType: "CancellationError",
                        operationIndex: index
                    )
                ))
                wasCancelled = true
            }

            // Agregar siguiente operación si hay límite de concurrencia
            if maxConcurrency != nil && !wasCancelled {
                addNextOperationWithCancellationCheck()
            }

            if completedCount == operations.count {
                break
            }
        }

        // Manejar operaciones no completadas
        if wasCancelled {
            let completedIndices = Set(successes.map { $0.index } + failures.map { $0.index })

            for (index, _) in operations.enumerated() where !completedIndices.contains(index) {
                let errorDescription = wasTimeout ? "Operation timed out" : "Operation was cancelled"
                let errorType = wasTimeout ? "TimeoutError" : "CancellationError"

                failures.append((
                    index,
                    WrappedError(
                        description: errorDescription,
                        errorType: errorType,
                        operationIndex: index
                    )
                ))
            }

            // Ejecutar cleanup handler con resultados parciales
            if let onCancellation {
                await onCancellation(successes)
            }
        }

        return BatchResult(
            successes: successes,
            failures: failures,
            duration: ContinuousClock.now - startTime
        )
    }
}

/// Resultado interno para operaciones cancellables.
private enum CancellableTaskResult<T: Sendable>: Sendable {
    case success(index: Int, value: T)
    case failure(index: Int, error: WrappedError)
    case cancelled(index: Int)
    case cancelledAfterCompletion(index: Int, value: T)
}

// MARK: - Throwing Task Group with Cancellation Support

/// Ejecuta operaciones con timeout lanzando excepción si hay cancelación.
///
/// Similar a `withThrowingTaskGroupWithTimeout` pero con mejor propagación
/// de cancelación y cleanup.
///
/// - Parameters:
///   - timeout: Timeout máximo
///   - onCancellation: Handler de cleanup opcional
///   - operations: Operaciones a ejecutar
/// - Returns: Array de resultados en orden
/// - Throws: `CancellationReason.timeout`, `CancellationReason.parentTaskCancelled`,
///           o errores de las operaciones
public func withThrowingCancellableTaskGroup<T: Sendable>(
    timeout: Duration,
    onCancellation: (@Sendable () async -> Void)? = nil,
    operations: [@Sendable () async throws -> T]
) async throws -> [T] {
    guard !operations.isEmpty else {
        return []
    }

    // Verificar cancelación antes de empezar
    if Task.isCancelled {
        await onCancellation?()
        throw CancellationReason.parentTaskCancelled
    }

    return try await withThrowingTaskGroup(of: IndexedTimeoutResult<T>.self) { group in
        // Task de timeout
        group.addTask {
            try await Task.sleep(for: timeout)
            return .timeout
        }

        // Agregar operaciones
        for (index, operation) in operations.enumerated() {
            group.addTask {
                // Verificar cancelación
                if Task.isCancelled {
                    throw CancellationError()
                }

                let value = try await operation()
                return .result(index: index, value: value)
            }
        }

        var results: [(Int, T)] = []
        results.reserveCapacity(operations.count)

        // Recolectar resultados
        do {
            while let signal = try await group.next() {
                // Verificar cancelación durante recolección
                if Task.isCancelled {
                    group.cancelAll()
                    await onCancellation?()
                    throw CancellationReason.parentTaskCancelled
                }

                switch signal {
                case .timeout:
                    group.cancelAll()
                    await onCancellation?()
                    throw CancellationReason.timeout(duration: Double(timeout.components.seconds))

                case .result(let index, let value):
                    results.append((index, value))
                    if results.count == operations.count {
                        group.cancelAll()
                        break
                    }
                }
            }
        } catch is CancellationError {
            group.cancelAll()
            await onCancellation?()
            throw CancellationReason.parentTaskCancelled
        }

        return results.sorted { $0.0 < $1.0 }.map { $0.1 }
    }
}

/// Resultado indexado para task group con timeout.
private enum IndexedTimeoutResult<T: Sendable>: Sendable {
    case timeout
    case result(index: Int, value: T)
}

private func withTaskGroupCollectingResultsNoTimeout<T: Sendable>(
    cancelOnFirstError: Bool,
    maxConcurrency: Int?,
    operations: [@Sendable () async throws -> T],
    startTime: ContinuousClock.Instant
) async -> BatchResult<T> {
    await withTaskGroup(of: TaskResult<T>.self) { group in
        var successes: [(index: Int, value: T)] = []
        var failures: [(index: Int, error: WrappedError)] = []
        var pendingOperations = Array(operations.enumerated())

        func addNextOperation() {
            guard !pendingOperations.isEmpty else { return }
            let (index, operation) = pendingOperations.removeFirst()
            group.addTask {
                do {
                    let value = try await operation()
                    return .success(index: index, value: value)
                } catch {
                    return .failure(index: index, error: WrappedError(error, operationIndex: index))
                }
            }
        }

        // Agregar operaciones iniciales
        let initialCount = maxConcurrency ?? operations.count
        for _ in 0..<min(initialCount, operations.count) {
            addNextOperation()
        }

        // Recolectar resultados
        for await result in group {
            switch result {
            case .success(let index, let value):
                successes.append((index, value))
            case .failure(let index, let error):
                failures.append((index, error))
                if cancelOnFirstError {
                    group.cancelAll()
                    // Marcar pendientes como canceladas
                    for (idx, _) in pendingOperations {
                        failures.append((
                            idx,
                            WrappedError(
                                description: "Cancelled due to earlier failure",
                                errorType: "CancellationError",
                                operationIndex: idx
                            )
                        ))
                    }
                    break
                }
            }

            // Agregar siguiente operación si hay maxConcurrency
            if maxConcurrency != nil && !cancelOnFirstError {
                addNextOperation()
            }
        }

        return BatchResult(
            successes: successes,
            failures: failures,
            duration: ContinuousClock.now - startTime
        )
    }
}
