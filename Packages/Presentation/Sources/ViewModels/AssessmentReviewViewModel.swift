import Foundation
import Observation
import EduCore
import EduDomain

/// ViewModel para la revision y calificacion de assessments por el profesor.
///
/// Gestiona la carga de intentos, estadisticas, revision de respuestas
/// individuales y finalizacion de intentos via CQRS Mediator.
///
/// ## Responsabilidades
/// - Cargar lista de intentos de un assessment (GetAttemptListQuery)
/// - Cargar estadisticas del assessment (GetAssessmentStatsQuery)
/// - Calificar respuestas individuales (ReviewAnswerCommand)
/// - Finalizar intentos individuales (FinalizeAttemptCommand) o masivamente (FinalizeAllCommand)
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = AssessmentReviewViewModel(mediator: mediator)
///
/// // En la vista
/// .task { await viewModel.loadAttempts(assessmentId: assessmentId) }
/// ```
@MainActor
@Observable
public final class AssessmentReviewViewModel {

    // MARK: - State

    /// Lista de intentos del assessment.
    public var attempts: [TeacherAttemptSummaryDTO] = []

    /// Estadisticas del assessment.
    public var stats: AssessmentStatsDTO?

    /// Detalle del intento seleccionado para revision.
    public var selectedAttempt: AttemptReviewDetailDTO?

    /// Indica si se estan cargando los intentos.
    public var isLoadingAttempts: Bool = false

    /// Indica si se esta cargando el detalle de un intento.
    public var isLoadingDetail: Bool = false

    /// Indica si se esta cargando algo (conveniencia para vistas que no distinguen).
    public var isLoading: Bool {
        isLoadingAttempts || isLoadingDetail
    }

    /// Error de carga de intentos.
    public var attemptsError: Error?

    /// Error de carga de detalle.
    public var detailError: Error?

    /// Error de revision (calificacion, finalizacion).
    public var reviewError: Error?

    /// Error consolidado (devuelve el primero no-nil, para retrocompatibilidad).
    public var error: Error? {
        attemptsError ?? detailError ?? reviewError
    }

    /// Filtro de estado activo (all, pending_review, completed).
    public var filter: String = "all"

    /// Texto de busqueda por nombre de estudiante.
    public var searchText: String = ""

    /// Indica si se esta guardando una revision.
    public var isSavingReview: Bool = false

    /// Indica si se esta finalizando.
    public var isFinalizing: Bool = false

    /// Mensaje de exito temporal.
    public var successMessage: String?

    // MARK: - Dependencies

    private let mediator: Mediator

    // MARK: - Initialization

    /// Crea un nuevo AssessmentReviewViewModel.
    ///
    /// - Parameter mediator: Mediator CQRS para despachar queries y commands.
    public init(mediator: Mediator) {
        self.mediator = mediator
    }

    // MARK: - Public Methods

    /// Carga la lista de intentos de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment.
    public func loadAttempts(assessmentId: String) async {
        guard !isLoadingAttempts else { return }

        isLoadingAttempts = true
        attemptsError = nil

        do {
            let query = GetAttemptListQuery(assessmentId: assessmentId)
            let result = try await mediator.send(query)
            self.attempts = result
            self.isLoadingAttempts = false
        } catch {
            self.attemptsError = error
            self.isLoadingAttempts = false
        }
    }

    /// Carga las estadisticas de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment.
    public func loadStats(assessmentId: String) async {
        attemptsError = nil

        do {
            let query = GetAssessmentStatsQuery(assessmentId: assessmentId)
            let result = try await mediator.send(query)
            self.stats = result
        } catch {
            self.attemptsError = error
        }
    }

    /// Carga el detalle de un intento para revision.
    ///
    /// - Parameter attemptId: ID del intento.
    public func loadAttemptForReview(attemptId: String) async {
        isLoadingDetail = true
        detailError = nil

        do {
            let query = GetAttemptDetailQuery(attemptId: attemptId)
            let result = try await mediator.send(query)
            self.selectedAttempt = result
            self.isLoadingDetail = false
        } catch {
            self.detailError = error
            self.isLoadingDetail = false
        }
    }

    /// Califica una respuesta individual.
    ///
    /// - Parameters:
    ///   - attemptId: ID del intento.
    ///   - answerId: ID de la respuesta.
    ///   - points: Puntos otorgados.
    ///   - feedback: Feedback del revisor.
    public func reviewAnswer(
        attemptId: String,
        answerId: String,
        points: Double,
        feedback: String
    ) async {
        isSavingReview = true
        reviewError = nil

        do {
            let command = ReviewAnswerCommand(
                attemptId: attemptId,
                answerId: answerId,
                points: points,
                feedback: feedback
            )
            let result = try await mediator.execute(command)

            if result.isSuccess, let updated = result.getValue() {
                self.selectedAttempt = updated
                self.isSavingReview = false
                self.successMessage = "Respuesta calificada"
            } else if let error = result.getError() {
                self.reviewError = error
                self.isSavingReview = false
            }
        } catch {
            self.reviewError = error
            self.isSavingReview = false
        }
    }

    /// Finaliza la revision de un intento individual.
    ///
    /// - Parameter attemptId: ID del intento.
    public func finalizeAttempt(attemptId: String) async {
        isFinalizing = true
        reviewError = nil

        do {
            let command = FinalizeAttemptCommand(attemptId: attemptId)
            let result = try await mediator.execute(command)

            if result.isSuccess {
                self.selectedAttempt = nil
                self.isFinalizing = false
                self.successMessage = "Revision finalizada"
            } else if let error = result.getError() {
                self.reviewError = error
                self.isFinalizing = false
            }
        } catch {
            self.reviewError = error
            self.isFinalizing = false
        }
    }

    /// Finaliza todos los intentos de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment.
    public func finalizeAll(assessmentId: String) async {
        isFinalizing = true
        reviewError = nil

        do {
            let command = FinalizeAllCommand(assessmentId: assessmentId)
            let result = try await mediator.execute(command)

            if result.isSuccess, let updated = result.getValue() {
                self.attempts = updated
                self.isFinalizing = false
                self.successMessage = "Todas las revisiones finalizadas"
            } else if let error = result.getError() {
                self.reviewError = error
                self.isFinalizing = false
            }
        } catch {
            self.reviewError = error
            self.isFinalizing = false
        }
    }

    /// Limpia todos los errores.
    public func clearError() {
        attemptsError = nil
        detailError = nil
        reviewError = nil
    }

    /// Limpia el mensaje de exito.
    public func clearSuccess() {
        successMessage = nil
    }

    // MARK: - Computed Properties

    /// Intentos filtrados por estado y texto de busqueda.
    public var filteredAttempts: [TeacherAttemptSummaryDTO] {
        var result = attempts

        // Filtrar por estado
        if filter != "all" {
            result = result.filter { $0.status == filter }
        }

        // Filtrar por texto de busqueda
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !trimmed.isEmpty {
            result = result.filter { attempt in
                attempt.studentName.lowercased().contains(trimmed)
                || attempt.studentEmail.lowercased().contains(trimmed)
            }
        }

        return result
    }

    /// Indica si hay un error.
    public var hasError: Bool {
        error != nil
    }

    /// Mensaje de error legible.
    public var errorMessage: String? {
        error?.localizedDescription
    }

    /// Indica si hay intentos cargados.
    public var hasAttempts: Bool {
        !attempts.isEmpty
    }

    /// Numero de intentos pendientes de revision.
    public var pendingReviewCount: Int {
        attempts.filter { $0.status == "pending_review" }.count
    }

    /// Indica si se puede finalizar todos (hay intentos pendientes revisados).
    ///
    /// Requiere que existan intentos, ninguno pendiente de revision, al menos
    /// uno en estado completable, y que no se este finalizando actualmente.
    public var canFinalizeAll: Bool {
        !attempts.isEmpty
        && pendingReviewCount == 0
        && attempts.contains(where: { $0.status == "completed" || $0.status == "pending_review" })
        && !isFinalizing
    }

    /// Indica si el intento seleccionado tiene respuestas pendientes.
    public var selectedAttemptHasPendingAnswers: Bool {
        guard let attempt = selectedAttempt else { return true }
        return attempt.answers.contains { $0.reviewStatus == "pending" }
    }

    /// Mensaje para estado vacio.
    public var emptyStateMessage: String {
        if filter != "all" || !searchText.isEmpty {
            return "No se encontraron intentos con los filtros aplicados"
        }
        return "No hay intentos registrados para esta evaluacion"
    }
}
