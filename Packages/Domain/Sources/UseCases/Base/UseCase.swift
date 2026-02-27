import Foundation
import EduFoundation

/// Protocolo base para todos los casos de uso del sistema EduGo.
///
/// Define el contrato fundamental para la ejecución de lógica de negocio,
/// garantizando thread-safety mediante actor isolation y conformidad con
/// Swift 6.0 Strict Concurrency.
///
/// ## Características
/// - **Associated Types**: `Input` y `Output` genéricos para máxima flexibilidad
/// - **Async/Throws**: Soporte nativo para operaciones asíncronas y manejo de errores
/// - **Sendable**: Conformidad obligatoria para thread-safety
/// - **Actor Isolation**: Diseñado para ejecución segura en contextos concurrentes
///
/// ## Ejemplo de Implementación
/// ```swift
/// actor EnrollStudentUseCase: UseCase {
///     typealias Input = EnrollmentRequest
///     typealias Output = EnrollmentResult
///
///     private let studentRepository: StudentRepositoryProtocol
///     private let courseRepository: CourseRepositoryProtocol
///
///     init(
///         studentRepository: StudentRepositoryProtocol,
///         courseRepository: CourseRepositoryProtocol
///     ) {
///         self.studentRepository = studentRepository
///         self.courseRepository = courseRepository
///     }
///
///     func execute(input: EnrollmentRequest) async throws -> EnrollmentResult {
///         // Validar precondiciones
///         guard input.studentId.isEmpty == false else {
///             throw UseCaseError.preconditionFailed(
///                 description: "El ID del estudiante no puede estar vacío"
///             )
///         }
///
///         // Obtener entidades
///         let student = try await studentRepository.fetch(id: input.studentId)
///         let course = try await courseRepository.fetch(id: input.courseId)
///
///         // Ejecutar lógica de negocio
///         try student.validateEnrollment(in: course)
///
///         // Persistir cambios
///         let enrollment = try await studentRepository.enroll(student, in: course)
///
///         return EnrollmentResult(enrollment: enrollment)
///     }
/// }
/// ```
///
/// ## Manejo de Errores
/// Los casos de uso deben lanzar `UseCaseError` para errores de la capa de aplicación:
/// ```swift
/// func execute(input: Input) async throws -> Output {
///     do {
///         let entity = try await repository.fetch(id: input.id)
///         try entity.validate()
///         return try await process(entity)
///     } catch let error as DomainError {
///         throw UseCaseError.domainError(error)
///     } catch let error as RepositoryError {
///         throw UseCaseError.repositoryError(error)
///     }
/// }
/// ```
///
/// ## Thread-Safety con Actors
/// Se recomienda implementar casos de uso como `actor` para garantizar
/// acceso seguro al estado mutable:
/// ```swift
/// actor CacheableUseCase: UseCase {
///     private var cache: [String: Output] = [:]
///
///     func execute(input: Input) async throws -> Output {
///         if let cached = cache[input.id] {
///             return cached
///         }
///         let result = try await fetchFromSource(input)
///         cache[input.id] = result
///         return result
///     }
/// }
/// ```
public protocol UseCase: Sendable {
    /// Tipo de entrada requerido para ejecutar el caso de uso.
    ///
    /// Debe conformar a `Sendable` para garantizar thread-safety en contextos
    /// concurrentes de Swift 6.0.
    associatedtype Input: Sendable

    /// Tipo de salida producido por el caso de uso.
    ///
    /// Debe conformar a `Sendable` para garantizar thread-safety en contextos
    /// concurrentes de Swift 6.0.
    associatedtype Output: Sendable

    /// Ejecuta el caso de uso con el input proporcionado.
    ///
    /// - Parameter input: Los datos de entrada necesarios para la ejecución
    /// - Returns: El resultado de la ejecución del caso de uso
    /// - Throws: `UseCaseError` si ocurre un error durante la ejecución
    ///
    /// ## Implementación
    /// Las implementaciones deben:
    /// 1. Validar precondiciones del input
    /// 2. Coordinar repositorios y servicios de dominio
    /// 3. Aplicar reglas de negocio
    /// 4. Transformar resultados al tipo `Output`
    /// 5. Propagar errores como `UseCaseError`
    ///
    /// ## Ejemplo
    /// ```swift
    /// func execute(input: FetchUserInput) async throws -> User {
    ///     guard !input.userId.isEmpty else {
    ///         throw UseCaseError.preconditionFailed(
    ///             description: "El ID de usuario es requerido"
    ///         )
    ///     }
    ///     return try await userRepository.fetch(id: input.userId)
    /// }
    /// ```
    func execute(input: Input) async throws -> Output
}

// MARK: - UseCase Extensions

extension UseCase {
    /// Ejecuta el caso de uso capturando errores en un `Result`.
    ///
    /// Alternativa funcional al manejo de errores con `try/catch`,
    /// útil para composición de operaciones y pipelines.
    ///
    /// - Parameter input: Los datos de entrada necesarios para la ejecución
    /// - Returns: `Result` con el output o el error capturado
    ///
    /// ## Ejemplo
    /// ```swift
    /// let result = await useCase.executeAsResult(input: request)
    /// switch result {
    /// case .success(let user):
    ///     print("Usuario: \(user.name)")
    /// case .failure(let error):
    ///     print("Error: \(error.localizedDescription)")
    /// }
    /// ```
    public func executeAsResult(input: Input) async -> Result<Output, Error> {
        do {
            let output = try await execute(input: input)
            return .success(output)
        } catch {
            return .failure(error)
        }
    }
}
