import Foundation

/// Representa el resultado de la ejecución de un Command.
///
/// `CommandResult` encapsula tanto el éxito como el fallo de un command,
/// incluyendo metadata adicional como eventos de dominio generados y
/// contexto de la ejecución.
///
/// # Ejemplo de uso:
/// ```swift
/// // Resultado exitoso
/// let successResult = CommandResult.success(
///     user,
///     events: ["UserCreatedEvent", "EmailSentEvent"],
///     metadata: ["timestamp": "2024-01-30T12:00:00Z"]
/// )
///
/// // Resultado fallido
/// let failureResult = CommandResult<User>.failure(
///     ValidationError.invalidEmail,
///     metadata: ["attemptedEmail": "invalid@"]
/// )
/// ```
public struct CommandResult<T: Sendable>: Sendable {
    /// Resultado de la operación (éxito o fallo)
    public let result: Result<T, Error>

    /// Lista de nombres de eventos de dominio generados durante la ejecución
    public let events: [String]

    /// Metadata adicional del resultado (timestamps, trace IDs, etc.)
    public let metadata: [String: String]

    /// Indica si el resultado es exitoso
    public var isSuccess: Bool {
        if case .success = result {
            return true
        }
        return false
    }

    /// Indica si el resultado es un fallo
    public var isFailure: Bool {
        !isSuccess
    }

    // MARK: - Inicializadores

    private init(
        result: Result<T, Error>,
        events: [String] = [],
        metadata: [String: String] = [:]
    ) {
        self.result = result
        self.events = events
        self.metadata = metadata
    }

    /// Crea un resultado exitoso.
    ///
    /// - Parameters:
    ///   - value: El valor resultante de la operación
    ///   - events: Lista de eventos de dominio generados
    ///   - metadata: Metadata adicional del resultado
    /// - Returns: `CommandResult` exitoso
    public static func success(
        _ value: T,
        events: [String] = [],
        metadata: [String: String] = [:]
    ) -> CommandResult<T> {
        return CommandResult(
            result: .success(value),
            events: events,
            metadata: metadata
        )
    }

    /// Crea un resultado fallido.
    ///
    /// - Parameters:
    ///   - error: El error que causó el fallo
    ///   - metadata: Metadata adicional del resultado
    /// - Returns: `CommandResult` fallido
    public static func failure(
        _ error: Error,
        metadata: [String: String] = [:]
    ) -> CommandResult<T> {
        return CommandResult(
            result: .failure(error),
            events: [],
            metadata: metadata
        )
    }

    // MARK: - Métodos de acceso

    /// Obtiene el valor si el resultado es exitoso.
    ///
    /// - Returns: El valor si es exitoso, nil si es fallo
    public func getValue() -> T? {
        if case .success(let value) = result {
            return value
        }
        return nil
    }

    /// Obtiene el error si el resultado es un fallo.
    ///
    /// - Returns: El error si es fallo, nil si es exitoso
    public func getError() -> Error? {
        if case .failure(let error) = result {
            return error
        }
        return nil
    }

    /// Transforma el resultado aplicando una función al valor exitoso.
    ///
    /// - Parameter transform: Función de transformación
    /// - Returns: Nuevo `CommandResult` con el valor transformado
    public func map<U: Sendable>(_ transform: (T) -> U) -> CommandResult<U> {
        switch result {
        case .success(let value):
            return CommandResult<U>(
                result: .success(transform(value)),
                events: events,
                metadata: metadata
            )
        case .failure(let error):
            return CommandResult<U>(
                result: .failure(error),
                events: events,
                metadata: metadata
            )
        }
    }
}
