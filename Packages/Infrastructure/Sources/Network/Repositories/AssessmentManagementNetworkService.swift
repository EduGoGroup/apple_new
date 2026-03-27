import Foundation
import EduCore

// MARK: - Assessment Management Network Service Error

/// Errores especificos del servicio de red de gestion de assessments.
public enum AssessmentManagementNetworkError: Error, Sendable, Equatable {
    /// Error de autenticacion.
    case unauthorized

    /// Assessment no encontrado.
    case assessmentNotFound(String)

    /// Pregunta no encontrada.
    case questionNotFound(String)

    /// Conflicto (ej: publicar assessment sin preguntas).
    case conflict(String)

    /// Solicitud invalida.
    case badRequest(String)

    /// Error de red subyacente.
    case networkError(NetworkError)
}

extension AssessmentManagementNetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "No autorizado. Por favor, inicie sesion"
        case .assessmentNotFound(let id):
            return "Assessment no encontrado: \(id)"
        case .questionNotFound(let id):
            return "Pregunta no encontrada: \(id)"
        case .conflict(let message):
            return "Conflicto: \(message)"
        case .badRequest(let message):
            return "Solicitud invalida: \(message)"
        case .networkError(let error):
            return "Error de red: \(error.localizedDescription)"
        }
    }
}

// MARK: - Assessment Management Network Service

/// Servicio de red para gestion de assessments (CRUD, preguntas, asignaciones).
///
/// ## Endpoints
/// - `POST /api/v1/assessments` - Crear assessment
/// - `PUT /api/v1/assessments/{id}` - Actualizar assessment (draft only)
/// - `GET /api/v1/assessments` - Listar assessments
/// - `GET /api/v1/assessments/{id}` - Detalle assessment
/// - `PATCH /api/v1/assessments/{id}/publish` - Publicar
/// - `PATCH /api/v1/assessments/{id}/archive` - Archivar
/// - `POST /api/v1/assessments/{id}/questions` - Crear pregunta
/// - `GET /api/v1/assessments/{id}/questions` - Listar preguntas
/// - `PUT /api/v1/assessments/{id}/questions/{questionId}` - Actualizar pregunta
/// - `DELETE /api/v1/assessments/{id}/questions/{questionId}` - Eliminar pregunta
/// - `POST /api/v1/assessments/{id}/questions/reorder` - Reordenar preguntas
/// - `POST /api/v1/assessments/{id}/assign` - Asignar assessment
/// - `GET /api/v1/assessments/{id}/assignments` - Listar asignaciones
/// - `DELETE /api/v1/assessments/{id}/assignments/{assignmentId}` - Eliminar asignacion
///
/// ## Ejemplo de uso
/// ```swift
/// let service = AssessmentManagementNetworkService(
///     client: authenticatedClient,
///     baseURL: "https://api-mobile.edugo.com"
/// )
///
/// let assessment = try await service.createAssessment(
///     CreateAssessmentRequestDTO(title: "Examen Parcial", sourceType: "manual")
/// )
/// ```
public actor AssessmentManagementNetworkService {

    // MARK: - Properties

    private let client: any NetworkClientProtocol
    private let baseURL: String

    // MARK: - Constants

    private enum Endpoints {
        static let assessments = "/api/v1/assessments"

        static func assessment(id: String) -> String {
            "/api/v1/assessments/\(id)"
        }

        static func publish(id: String) -> String {
            "/api/v1/assessments/\(id)/publish"
        }

        static func archive(id: String) -> String {
            "/api/v1/assessments/\(id)/archive"
        }

        static func questions(assessmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/questions"
        }

        static func question(assessmentId: String, questionId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/questions/\(questionId)"
        }

        static func reorderQuestions(assessmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/questions/reorder"
        }

        static func assign(assessmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/assign"
        }

        static func assignments(assessmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/assignments"
        }

        static func assignment(assessmentId: String, assignmentId: String) -> String {
            "/api/v1/assessments/\(assessmentId)/assignments/\(assignmentId)"
        }
    }

    // MARK: - Initialization

    /// Inicializa el servicio de red de gestion de assessments.
    /// - Parameters:
    ///   - client: Cliente de red para realizar las requests.
    ///   - baseURL: URL base del API mobile (ej: "https://api-mobile.edugo.com").
    public init(client: any NetworkClientProtocol, baseURL: String) {
        self.client = client
        var sanitized = baseURL
        while sanitized.hasSuffix("/") { sanitized = String(sanitized.dropLast()) }
        self.baseURL = sanitized
    }

    // MARK: - Assessment CRUD

    /// Crea un nuevo assessment.
    ///
    /// - Parameter request: Datos del assessment a crear.
    /// - Returns: DTO del assessment creado.
    public func createAssessment(_ request: CreateAssessmentRequestDTO) async throws -> AssessmentManagementResponseDTO {
        let url = baseURL + Endpoints.assessments
        do {
            return try await client.post(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error)
        }
    }

    /// Actualiza un assessment existente (solo en estado draft).
    ///
    /// - Parameters:
    ///   - id: ID del assessment.
    ///   - request: Datos actualizados del assessment.
    /// - Returns: DTO del assessment actualizado.
    public func updateAssessment(id: String, _ request: CreateAssessmentRequestDTO) async throws -> AssessmentManagementResponseDTO {
        let url = baseURL + Endpoints.assessment(id: id)
        do {
            return try await client.put(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: id)
        }
    }

    /// Lista assessments con filtro opcional por estado y paginacion.
    ///
    /// - Parameters:
    ///   - status: Filtro de estado ("draft", "published", "archived"). Nil para todos.
    ///   - page: Numero de pagina (1-based).
    ///   - limit: Tamano de pagina.
    /// - Returns: Respuesta paginada de assessments.
    public func listAssessments(status: String?, page: Int, limit: Int) async throws -> PaginatedResponse<AssessmentManagementResponseDTO> {
        var url = baseURL + Endpoints.assessments + "?page=\(page)&limit=\(limit)"
        if let status {
            url += "&status=\(status)"
        }
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error)
        }
    }

    /// Obtiene el detalle de un assessment por ID.
    ///
    /// - Parameter id: ID del assessment (UUID string).
    /// - Returns: DTO del assessment.
    public func getAssessment(id: String) async throws -> AssessmentManagementResponseDTO {
        let url = baseURL + Endpoints.assessment(id: id)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: id)
        }
    }

    /// Publica un assessment (cambia estado de draft a published).
    ///
    /// - Parameter id: ID del assessment.
    /// - Returns: DTO del assessment actualizado.
    public func publishAssessment(id: String) async throws -> AssessmentManagementResponseDTO {
        let url = baseURL + Endpoints.publish(id: id)
        do {
            return try await client.patch(url, body: EmptyPatchBody())
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: id)
        }
    }

    /// Archiva un assessment.
    ///
    /// - Parameter id: ID del assessment.
    /// - Returns: DTO del assessment actualizado.
    public func archiveAssessment(id: String) async throws -> AssessmentManagementResponseDTO {
        let url = baseURL + Endpoints.archive(id: id)
        do {
            return try await client.patch(url, body: EmptyPatchBody())
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: id)
        }
    }

    // MARK: - Questions

    /// Crea una nueva pregunta en un assessment.
    ///
    /// - Parameters:
    ///   - assessmentId: ID del assessment.
    ///   - request: Datos de la pregunta a crear.
    /// - Returns: DTO de la pregunta creada.
    public func createQuestion(assessmentId: String, _ request: CreateQuestionRequestDTO) async throws -> QuestionResponseDTO {
        let url = baseURL + Endpoints.questions(assessmentId: assessmentId)
        do {
            return try await client.post(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Lista las preguntas de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment.
    /// - Returns: Lista de DTOs de preguntas.
    public func listQuestions(assessmentId: String) async throws -> [QuestionResponseDTO] {
        let url = baseURL + Endpoints.questions(assessmentId: assessmentId)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Actualiza una pregunta existente.
    ///
    /// - Parameters:
    ///   - assessmentId: ID del assessment.
    ///   - questionId: ID de la pregunta.
    ///   - request: Datos actualizados de la pregunta.
    /// - Returns: DTO de la pregunta actualizada.
    public func updateQuestion(assessmentId: String, questionId: String, _ request: CreateQuestionRequestDTO) async throws -> QuestionResponseDTO {
        let url = baseURL + Endpoints.question(assessmentId: assessmentId, questionId: questionId)
        do {
            return try await client.put(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Elimina una pregunta de un assessment.
    ///
    /// - Parameters:
    ///   - assessmentId: ID del assessment.
    ///   - questionId: ID de la pregunta.
    public func deleteQuestion(assessmentId: String, questionId: String) async throws {
        let url = baseURL + Endpoints.question(assessmentId: assessmentId, questionId: questionId)
        do {
            let _: EmptyResponse = try await client.delete(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Reordena las preguntas de un assessment.
    ///
    /// - Parameters:
    ///   - assessmentId: ID del assessment.
    ///   - request: Nuevo orden de preguntas.
    public func reorderQuestions(assessmentId: String, _ request: ReorderQuestionsRequestDTO) async throws {
        let url = baseURL + Endpoints.reorderQuestions(assessmentId: assessmentId)
        do {
            let _: EmptyResponse = try await client.post(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    // MARK: - Assignments

    /// Asigna un assessment a estudiantes o unidades academicas.
    ///
    /// - Parameters:
    ///   - assessmentId: ID del assessment.
    ///   - request: Datos de la asignacion.
    /// - Returns: Lista de DTOs de asignaciones creadas.
    public func assignAssessment(assessmentId: String, _ request: AssignAssessmentRequestDTO) async throws -> [AssignmentResponseDTO] {
        let url = baseURL + Endpoints.assign(assessmentId: assessmentId)
        do {
            return try await client.post(url, body: request)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Lista las asignaciones de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment.
    /// - Returns: Lista de DTOs de asignaciones.
    public func listAssignments(assessmentId: String) async throws -> [AssignmentResponseDTO] {
        let url = baseURL + Endpoints.assignments(assessmentId: assessmentId)
        do {
            return try await client.get(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    /// Elimina una asignacion de un assessment.
    ///
    /// - Parameters:
    ///   - assessmentId: ID del assessment.
    ///   - assignmentId: ID de la asignacion.
    public func removeAssignment(assessmentId: String, assignmentId: String) async throws {
        let url = baseURL + Endpoints.assignment(assessmentId: assessmentId, assignmentId: assignmentId)
        do {
            let _: EmptyResponse = try await client.delete(url)
        } catch let error as NetworkError {
            throw mapError(error, assessmentId: assessmentId)
        }
    }

    // MARK: - Private Methods

    private func mapError(
        _ error: NetworkError,
        assessmentId: String? = nil
    ) -> AssessmentManagementNetworkError {
        switch error {
        case .unauthorized:
            return .unauthorized
        case .notFound:
            if let assessmentId {
                return .assessmentNotFound(assessmentId)
            }
            return .networkError(error)
        case .serverError(let statusCode, let message) where statusCode == 409:
            return .conflict(message ?? "Conflicto en la operacion")
        case .serverError(let statusCode, let message) where statusCode == 400:
            return .badRequest(message ?? "Solicitud invalida")
        default:
            return .networkError(error)
        }
    }
}

// MARK: - Empty Patch Body

/// Body vacio para requests PATCH que no requieren datos.
private struct EmptyPatchBody: Encodable, Sendable {
    enum CodingKeys: CodingKey {}
}
