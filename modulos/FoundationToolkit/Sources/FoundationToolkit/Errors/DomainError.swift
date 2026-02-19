import Foundation

/// Errores relacionados con la capa de dominio.
///
/// Estos errores representan violaciones de reglas de negocio, validaciones fallidas
/// y operaciones inválidas a nivel de la lógica de dominio.
///
/// ## Ejemplo de uso
/// ```swift
/// func createStudent(name: String, age: Int) throws -> Student {
///     guard !name.isEmpty else {
///         throw DomainError.validationFailed(
///             field: "name",
///             reason: "El nombre no puede estar vacío"
///         )
///     }
///     guard age >= 18 else {
///         throw DomainError.businessRuleViolated(
///             rule: "Estudiantes deben ser mayores de edad"
///         )
///     }
///     return Student(name: name, age: age)
/// }
/// ```
public enum DomainError: Error, LocalizedError, Sendable, Equatable {
    /// Una validación de datos ha fallado.
    case validationFailed(field: String, reason: String)

    /// Una regla de negocio ha sido violada.
    case businessRuleViolated(rule: String)

    /// Se intentó realizar una operación inválida o no permitida.
    case invalidOperation(operation: String)

    /// No se encontró una entidad de dominio con el identificador especificado.
    case entityNotFound(type: String, id: String)

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .validationFailed(let field, let reason):
            return "Error de validación en '\(field)': \(reason)"
        case .businessRuleViolated(let rule):
            return "Regla de negocio violada: \(rule)"
        case .invalidOperation(let operation):
            return "Operación inválida: \(operation)"
        case .entityNotFound(let type, let id):
            return "No se encontró la entidad de tipo '\(type)' con ID '\(id)'"
        }
    }

    public var failureReason: String? {
        switch self {
        case .validationFailed(let field, _):
            return "El campo '\(field)' no cumple con los criterios de validación requeridos."
        case .businessRuleViolated:
            return "La operación solicitada viola una o más reglas de negocio del dominio."
        case .invalidOperation:
            return "La operación no puede ejecutarse en el estado actual de la entidad."
        case .entityNotFound(let type, _):
            return "La entidad de tipo '\(type)' no existe en el contexto de dominio actual."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .validationFailed:
            return "Verifique que todos los campos cumplan con los requisitos especificados y vuelva a intentar."
        case .businessRuleViolated:
            return "Revise las reglas de negocio aplicables y ajuste la operación según sea necesario."
        case .invalidOperation:
            return "Asegúrese de que la entidad esté en el estado correcto antes de realizar esta operación."
        case .entityNotFound:
            return "Verifique que el identificador sea correcto o cree la entidad antes de intentar acceder a ella."
        }
    }
}
