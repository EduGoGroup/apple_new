import Foundation

/// Errores relacionados con la capa de aplicación (casos de uso) del sistema EduGo.
///
/// Estos errores representan fallos en la ejecución de casos de uso, incluyendo
/// precondiciones no cumplidas, problemas de autorización, y wrapping de errores
/// de capas inferiores (dominio y repositorio).
///
/// ## Conformidades
/// - `Error`: Para que pueda ser lanzado con `throw`
/// - `LocalizedError`: Para proporcionar mensajes descriptivos en español
/// - `Sendable`: Para cumplir con Swift 6.2 Strict Concurrency
///
/// ## Patrón de Wrapping
/// `UseCaseError` puede encapsular errores de las capas inferiores mediante los casos
/// `.domainError` y `.repositoryError`. Esto permite propagar errores específicos
/// de cada capa manteniendo la información original:
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
///
/// ## Unwrapping de Errores
/// Use las propiedades computadas para acceder a errores encapsulados:
/// ```swift
/// do {
///     try await useCase.execute()
/// } catch let error as UseCaseError {
///     if let domainError = error.underlyingDomainError {
///         print("Error de dominio: \(domainError)")
///     }
/// }
/// ```
public enum UseCaseError: Error, LocalizedError, Sendable {
    /// Una precondición necesaria para ejecutar el caso de uso no se cumplió.
    ///
    /// - Parameter description: Descripción de la precondición que falló
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw UseCaseError.preconditionFailed(
    ///     description: "El estudiante debe estar activo para inscribirse en materias"
    /// )
    /// ```
    case preconditionFailed(description: String)

    /// El usuario no tiene autorización para ejecutar esta acción.
    ///
    /// - Parameter action: La acción que requiere autorización
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw UseCaseError.unauthorized(
    ///     action: "Modificar calificaciones de otros profesores"
    /// )
    /// ```
    case unauthorized(action: String)

    /// Encapsula un error de la capa de dominio.
    ///
    /// - Parameter error: El `DomainError` original
    ///
    /// ## Ejemplo
    /// ```swift
    /// do {
    ///     try validateStudent(name: name)
    /// } catch let error as DomainError {
    ///     throw UseCaseError.domainError(error)
    /// }
    /// ```
    case domainError(DomainError)

    /// Encapsula un error de la capa de repositorio.
    ///
    /// - Parameter error: El `RepositoryError` original
    ///
    /// ## Ejemplo
    /// ```swift
    /// do {
    ///     let student = try await repository.fetch(id: id)
    /// } catch let error as RepositoryError {
    ///     throw UseCaseError.repositoryError(error)
    /// }
    /// ```
    case repositoryError(RepositoryError)

    /// La ejecución del caso de uso falló por una razón no categorizada.
    ///
    /// - Parameter reason: La razón del fallo
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw UseCaseError.executionFailed(
    ///     reason: "No se pudo completar el proceso de inscripción debido a un error interno"
    /// )
    /// ```
    case executionFailed(reason: String)

    /// La ejecución del caso de uso excedió el tiempo límite permitido.
    ///
    /// ## Ejemplo
    /// ```swift
    /// try await withTimeout(seconds: 30) {
    ///     try await longRunningOperation()
    /// }
    /// // Si falla por timeout:
    /// throw UseCaseError.timeout
    /// ```
    case timeout

    // MARK: - Computed Properties para Unwrapping

    /// Accede al `DomainError` encapsulado, si existe.
    ///
    /// - Returns: El `DomainError` original, o `nil` si este error no encapsula uno
    ///
    /// ## Ejemplo
    /// ```swift
    /// if let domainError = useCaseError.underlyingDomainError {
    ///     switch domainError {
    ///     case .validationFailed(let field, let reason):
    ///         print("Validación falló en \(field): \(reason)")
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    public var underlyingDomainError: DomainError? {
        if case .domainError(let error) = self {
            return error
        }
        return nil
    }

    /// Accede al `RepositoryError` encapsulado, si existe.
    ///
    /// - Returns: El `RepositoryError` original, o `nil` si este error no encapsula uno
    ///
    /// ## Ejemplo
    /// ```swift
    /// if let repoError = useCaseError.underlyingRepositoryError {
    ///     switch repoError {
    ///     case .connectionError:
    ///         print("Error de conexión, reintentando...")
    ///     default:
    ///         break
    ///     }
    /// }
    /// ```
    public var underlyingRepositoryError: RepositoryError? {
        if case .repositoryError(let error) = self {
            return error
        }
        return nil
    }

    // MARK: - LocalizedError

    /// Descripción legible del error en español.
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

    /// Razón técnica del fallo.
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

    /// Sugerencia de recuperación para el usuario.
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
