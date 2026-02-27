import Foundation

/// Errores relacionados con la capa de dominio del sistema EduGo.
///
/// Estos errores representan violaciones de reglas de negocio, validaciones fallidas
/// y operaciones inválidas a nivel de la lógica de dominio.
///
/// ## Conformidades
/// - `Error`: Para que pueda ser lanzado con `throw`
/// - `LocalizedError`: Para proporcionar mensajes descriptivos en español
/// - `Sendable`: Para cumplir con Swift 6.2 Strict Concurrency
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
    ///
    /// - Parameters:
    ///   - field: El nombre del campo que falló la validación
    ///   - reason: La razón específica por la cual falló
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw DomainError.validationFailed(
    ///     field: "email",
    ///     reason: "Formato de correo electrónico inválido"
    /// )
    /// ```
    case validationFailed(field: String, reason: String)

    /// Una regla de negocio ha sido violada.
    ///
    /// - Parameter rule: Descripción de la regla de negocio que se violó
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw DomainError.businessRuleViolated(
    ///     rule: "Un estudiante no puede estar inscrito en más de 6 materias simultáneamente"
    /// )
    /// ```
    case businessRuleViolated(rule: String)

    /// Se intentó realizar una operación inválida o no permitida.
    ///
    /// - Parameter operation: Descripción de la operación que se intentó realizar
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw DomainError.invalidOperation(
    ///     operation: "No se puede calificar un examen que aún no ha sido enviado"
    /// )
    /// ```
    case invalidOperation(operation: String)

    /// No se encontró una entidad de dominio con el identificador especificado.
    ///
    /// - Parameters:
    ///   - type: El tipo de entidad que se buscaba
    ///   - id: El identificador único de la entidad
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw DomainError.entityNotFound(
    ///     type: "Student",
    ///     id: "12345"
    /// )
    /// ```
    case entityNotFound(type: String, id: String)

    // MARK: - LocalizedError

    /// Descripción legible del error en español.
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

    /// Razón técnica del fallo.
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

    /// Sugerencia de recuperación para el usuario.
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
