import Foundation

/// Errores específicos del Mediator
public enum MediatorError: Error, Sendable {
    /// No se encontró un handler registrado para el tipo de query o command
    case handlerNotFound(type: String)

    /// Error de validación al procesar un command
    case validationError(message: String, underlyingError: Error?)

    /// Error durante la ejecución del handler
    case executionError(message: String, underlyingError: Error?)

    /// Error de registro de handler (ej: handler duplicado)
    case registrationError(message: String)
}

// MARK: - CustomStringConvertible

extension MediatorError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .handlerNotFound(let type):
            return "Handler not found for type: \(type)"
        case .validationError(let message, let error):
            return "Validation error: \(message)\(error.map { ". Underlying error: \($0)" } ?? "")"
        case .executionError(let message, let error):
            return "Execution error: \(message)\(error.map { ". Underlying error: \($0)" } ?? "")"
        case .registrationError(let message):
            return "Registration error: \(message)"
        }
    }
}

// MARK: - LocalizedError

extension MediatorError: LocalizedError {
    public var errorDescription: String? {
        description
    }
}
