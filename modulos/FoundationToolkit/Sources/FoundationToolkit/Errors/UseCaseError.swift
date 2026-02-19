import Foundation

/// Errores relacionados con la capa de aplicación (casos de uso).
///
/// Estos errores representan fallos en la ejecución de casos de uso, incluyendo
/// precondiciones no cumplidas, problemas de autorización, y wrapping de errores
/// de capas inferiores (dominio y repositorio).
///
/// ## Patrón de Wrapping
/// `UseCaseError` puede encapsular errores de las capas inferiores mediante los casos
/// `.domainError` y `.repositoryError`:
///
/// ```swift
/// class EnrollStudentUseCase {
///     func execute(studentId: String, courseId: String) async throws {
///         do {
///             let student = try await studentRepo.fetch(id: studentId)
///             try student.validateEnrollment(courseId: courseId)
///         } catch let error as DomainError {
///             throw UseCaseError.domainError(error)
///         } catch let error as RepositoryError {
///             throw UseCaseError.repositoryError(error)
///         }
///     }
/// }
/// ```
public enum UseCaseError: Error, LocalizedError, Sendable {
    /// Una precondición necesaria para ejecutar el caso de uso no se cumplió.
    case preconditionFailed(description: String)

    /// El usuario no tiene autorización para ejecutar esta acción.
    case unauthorized(action: String)

    /// Encapsula un error de la capa de dominio.
    case domainError(DomainError)

    /// Encapsula un error de la capa de repositorio.
    case repositoryError(RepositoryError)

    /// La ejecución del caso de uso falló por una razón no categorizada.
    case executionFailed(reason: String)

    /// La ejecución del caso de uso excedió el tiempo límite permitido.
    case timeout

    // MARK: - Computed Properties para Unwrapping

    /// Accede al `DomainError` encapsulado, si existe.
    public var underlyingDomainError: DomainError? {
        if case .domainError(let error) = self {
            return error
        }
        return nil
    }

    /// Accede al `RepositoryError` encapsulado, si existe.
    public var underlyingRepositoryError: RepositoryError? {
        if case .repositoryError(let error) = self {
            return error
        }
        return nil
    }

    // MARK: - LocalizedError

    public var errorDescription: String? {
        switch self {
        case .preconditionFailed(let description):
            return "Precondición no cumplida: \(description)"
        case .unauthorized(let action):
            return "No autorizado: \(action)"
        case .domainError(let error):
            return "Error de dominio: \(error.localizedDescription)"
        case .repositoryError(let error):
            return "Error de repositorio: \(error.localizedDescription)"
        case .executionFailed(let reason):
            return "Ejecución fallida: \(reason)"
        case .timeout:
            return "La operación excedió el tiempo límite permitido"
        }
    }

    public var failureReason: String? {
        switch self {
        case .preconditionFailed:
            return "Una o más precondiciones necesarias para ejecutar el caso de uso no se cumplieron."
        case .unauthorized:
            return "El usuario actual no tiene los permisos necesarios para realizar esta acción."
        case .domainError(let error):
            return error.failureReason
        case .repositoryError(let error):
            return error.failureReason
        case .executionFailed:
            return "El caso de uso no pudo completarse exitosamente debido a un error durante la ejecución."
        case .timeout:
            return "La operación tomó más tiempo del permitido y fue cancelada automáticamente."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .preconditionFailed:
            return "Asegúrese de cumplir con todas las precondiciones necesarias antes de ejecutar esta acción."
        case .unauthorized:
            return "Contacte a un administrador para obtener los permisos necesarios o inicie sesión con una cuenta autorizada."
        case .domainError(let error):
            return error.recoverySuggestion
        case .repositoryError(let error):
            return error.recoverySuggestion
        case .executionFailed:
            return "Vuelva a intentar la operación. Si el problema persiste, contacte al soporte técnico."
        case .timeout:
            return "Verifique su conexión a internet e intente nuevamente. Si el problema persiste, la operación puede requerir optimización."
        }
    }
}
