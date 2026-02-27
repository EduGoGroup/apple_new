import Foundation

/// Errores que pueden ocurrir durante la ejecución de operaciones batch en task groups.
///
/// Proporciona errores específicos para el manejo de fallos en operaciones
/// concurrentes, siguiendo las mejores prácticas de Swift 6.2 strict concurrency.
///
/// ## Casos de Uso
///
/// ```swift
/// do {
///     let results = try await coordinator.executeBatch(operations)
/// } catch let error as TaskGroupError {
///     switch error {
///     case .partialFailure(let successes, let errors):
///         print("Completados: \(successes.count), Fallidos: \(errors.count)")
///     case .cancelled:
///         print("Operación cancelada")
///     case .timeout(let duration):
///         print("Timeout después de \(duration)s")
///     case .allFailed(let errors):
///         print("Todas las operaciones fallaron: \(errors.count) errores")
///     }
/// }
/// ```
public enum TaskGroupError: Error, Sendable {
    /// Algunas operaciones fallaron pero otras tuvieron éxito.
    ///
    /// Este error permite recuperar resultados parciales cuando algunas
    /// operaciones del batch completaron exitosamente.
    ///
    /// - Parameters:
    ///   - successCount: Número de operaciones exitosas
    ///   - errors: Errores de las operaciones fallidas
    case partialFailure(successCount: Int, errors: [WrappedError])

    /// La operación fue cancelada.
    ///
    /// Se lanza cuando `Task.isCancelled` es true o cuando se recibe
    /// una señal de cancelación explícita.
    case cancelled

    /// La operación excedió el tiempo límite configurado.
    ///
    /// - Parameter duration: Duración del timeout en segundos
    case timeout(duration: TimeInterval)

    /// Todas las operaciones del batch fallaron.
    ///
    /// - Parameter errors: Lista de todos los errores ocurridos
    case allFailed(errors: [WrappedError])

    /// No se proporcionaron operaciones para ejecutar.
    case emptyBatch

    /// Número máximo de reintentos excedido.
    ///
    /// - Parameters:
    ///   - attempts: Número de intentos realizados
    ///   - lastError: Último error antes de abandonar
    case maxRetriesExceeded(attempts: Int, lastError: WrappedError)
}

/// Wrapper para errores que permite conformar a Sendable y Equatable.
///
/// Encapsula cualquier Error para permitir su uso seguro en contextos
/// concurrentes y comparaciones.
public struct WrappedError: Error, Sendable, Equatable {
    /// Descripción del error original.
    public let description: String

    /// Tipo del error original como String.
    public let errorType: String

    /// Índice de la operación que falló (si aplica).
    public let operationIndex: Int?

    /// Inicializa un WrappedError desde cualquier Error.
    /// - Parameters:
    ///   - error: Error original a encapsular
    ///   - operationIndex: Índice opcional de la operación
    public init(_ error: any Error, operationIndex: Int? = nil) {
        self.description = String(describing: error)
        self.errorType = String(describing: type(of: error))
        self.operationIndex = operationIndex
    }

    /// Inicializa un WrappedError desde una descripción.
    /// - Parameters:
    ///   - description: Descripción del error
    ///   - errorType: Tipo del error
    ///   - operationIndex: Índice opcional de la operación
    public init(description: String, errorType: String = "Unknown", operationIndex: Int? = nil) {
        self.description = description
        self.errorType = errorType
        self.operationIndex = operationIndex
    }

    public static func == (lhs: WrappedError, rhs: WrappedError) -> Bool {
        lhs.description == rhs.description &&
        lhs.errorType == rhs.errorType &&
        lhs.operationIndex == rhs.operationIndex
    }
}

// MARK: - LocalizedError

extension TaskGroupError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .partialFailure(let successCount, let errors):
            return "Operación parcialmente exitosa: \(successCount) completadas, \(errors.count) fallidas"

        case .cancelled:
            return "La operación fue cancelada"

        case .timeout(let duration):
            return "La operación excedió el tiempo límite de \(Int(duration)) segundos"

        case .allFailed(let errors):
            return "Todas las operaciones fallaron (\(errors.count) errores)"

        case .emptyBatch:
            return "No se proporcionaron operaciones para ejecutar"

        case .maxRetriesExceeded(let attempts, let lastError):
            return "Máximo de reintentos excedido (\(attempts) intentos). Último error: \(lastError.description)"
        }
    }
}

// MARK: - CustomDebugStringConvertible

extension TaskGroupError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .partialFailure(let successCount, let errors):
            let errorDescriptions = errors.prefix(3).map { "[\($0.operationIndex ?? -1)]: \($0.description)" }
            let suffix = errors.count > 3 ? "... and \(errors.count - 3) more" : ""
            return "TaskGroupError.partialFailure(success: \(successCount), errors: [\(errorDescriptions.joined(separator: ", "))\(suffix)])"

        case .cancelled:
            return "TaskGroupError.cancelled"

        case .timeout(let duration):
            return "TaskGroupError.timeout(duration: \(duration)s)"

        case .allFailed(let errors):
            return "TaskGroupError.allFailed(count: \(errors.count))"

        case .emptyBatch:
            return "TaskGroupError.emptyBatch"

        case .maxRetriesExceeded(let attempts, let lastError):
            return "TaskGroupError.maxRetriesExceeded(attempts: \(attempts), lastError: \(lastError.errorType))"
        }
    }
}

// MARK: - Convenience Accessors

extension TaskGroupError {
    /// Retorna los errores contenidos en este error, si los hay.
    public var containedErrors: [WrappedError] {
        switch self {
        case .partialFailure(_, let errors):
            return errors
        case .allFailed(let errors):
            return errors
        case .maxRetriesExceeded(_, let lastError):
            return [lastError]
        case .cancelled, .timeout, .emptyBatch:
            return []
        }
    }

    /// Indica si hubo al menos una operación exitosa.
    public var hasPartialSuccess: Bool {
        if case .partialFailure(let count, _) = self {
            return count > 0
        }
        return false
    }

    /// Indica si el error es recuperable (puede reintentarse).
    public var isRetriable: Bool {
        switch self {
        case .cancelled, .emptyBatch:
            return false
        case .timeout, .partialFailure, .allFailed, .maxRetriesExceeded:
            return true
        }
    }
}

extension WrappedError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}

extension WrappedError: CustomDebugStringConvertible {
    public var debugDescription: String {
        if let index = operationIndex {
            return "WrappedError[\(index)](\(errorType): \(description))"
        }
        return "WrappedError(\(errorType): \(description))"
    }
}
