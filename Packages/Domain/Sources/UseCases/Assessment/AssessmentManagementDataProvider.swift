import Foundation
import EduCore
import EduInfrastructure

// MARK: - Assessment Management Data Provider Protocol

/// Protocolo que define el acceso a datos de gestion de assessments.
///
/// Definido en Domain para permitir que Presentation dependa
/// de la abstraccion sin conocer la implementacion en Infrastructure.
///
/// La implementacion concreta (`AssessmentManagementNetworkService`) vive en Infrastructure.
/// La inyeccion se realiza en la composicion de la app.
///
/// ## Endpoints soportados
/// - CRUD de assessments (crear, actualizar, listar, detalle)
/// - Publicar / archivar assessments
/// - CRUD de preguntas
/// - Asignaciones de assessments
public protocol AssessmentManagementDataProvider: Sendable {

    // MARK: - Assessments

    /// Crea un nuevo assessment.
    func createAssessment(_ request: CreateAssessmentRequestDTO) async throws -> AssessmentManagementResponseDTO

    /// Actualiza un assessment existente (solo en estado draft).
    func updateAssessment(id: String, _ request: CreateAssessmentRequestDTO) async throws -> AssessmentManagementResponseDTO

    /// Lista assessments con filtro opcional por estado y paginacion.
    func listAssessments(status: String?, page: Int, limit: Int) async throws -> PaginatedResponse<AssessmentManagementResponseDTO>

    /// Obtiene el detalle de un assessment por ID.
    func getAssessment(id: String) async throws -> AssessmentManagementResponseDTO

    /// Publica un assessment (cambia estado de draft a published).
    func publishAssessment(id: String) async throws -> AssessmentManagementResponseDTO

    /// Archiva un assessment.
    func archiveAssessment(id: String) async throws -> AssessmentManagementResponseDTO

    // MARK: - Questions

    /// Crea una nueva pregunta en un assessment.
    func createQuestion(assessmentId: String, _ request: CreateQuestionRequestDTO) async throws -> QuestionResponseDTO

    /// Lista las preguntas de un assessment.
    func listQuestions(assessmentId: String) async throws -> [QuestionResponseDTO]

    /// Actualiza una pregunta existente.
    func updateQuestion(assessmentId: String, questionId: String, _ request: CreateQuestionRequestDTO) async throws -> QuestionResponseDTO

    /// Elimina una pregunta de un assessment.
    func deleteQuestion(assessmentId: String, questionId: String) async throws

    /// Reordena las preguntas de un assessment.
    func reorderQuestions(assessmentId: String, _ request: ReorderQuestionsRequestDTO) async throws

    // MARK: - Assignments

    /// Asigna un assessment a estudiantes o unidades academicas.
    func assignAssessment(assessmentId: String, _ request: AssignAssessmentRequestDTO) async throws -> [AssignmentResponseDTO]

    /// Lista las asignaciones de un assessment.
    func listAssignments(assessmentId: String) async throws -> [AssignmentResponseDTO]

    /// Elimina una asignacion de un assessment.
    func removeAssignment(assessmentId: String, assignmentId: String) async throws
}
