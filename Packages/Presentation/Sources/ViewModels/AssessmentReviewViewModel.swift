import Foundation
import Observation
import EduCore
import EduInfrastructure

/// ViewModel para la revision y calificacion de assessments por el profesor.
///
/// Gestiona la carga de intentos, estadisticas, revision de respuestas
/// individuales y finalizacion de intentos.
///
/// ## Responsabilidades
/// - Cargar lista de intentos de un assessment
/// - Cargar estadisticas del assessment
/// - Cargar detalle de un intento para revision
/// - Calificar respuestas individuales
/// - Finalizar intentos individuales o masivamente
///
/// ## Ejemplo de uso
/// ```swift
/// let viewModel = AssessmentReviewViewModel(
///     networkService: reviewNetworkService
/// )
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

    /// Indica si se esta cargando datos.
    public var isLoading: Bool = false

    /// Error actual si lo hay.
    public var error: Error?

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

    private let networkService: AssessmentReviewNetworkService

    // MARK: - Initialization

    /// Crea un nuevo AssessmentReviewViewModel.
    ///
    /// - Parameter networkService: Servicio de red de revision de assessments.
    public init(networkService: AssessmentReviewNetworkService) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// Carga la lista de intentos de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment.
    public func loadAttempts(assessmentId: String) async {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        do {
            let result = try await networkService.listAttempts(assessmentId: assessmentId)
            self.attempts = result
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
        }
    }

    /// Carga las estadisticas de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment.
    public func loadStats(assessmentId: String) async {
        error = nil

        do {
            let result = try await networkService.getStats(assessmentId: assessmentId)
            self.stats = result
        } catch {
            self.error = error
        }
    }

    /// Carga el detalle de un intento para revision.
    ///
    /// - Parameter attemptId: ID del intento.
    public func loadAttemptForReview(attemptId: String) async {
        isLoading = true
        error = nil

        do {
            let result = try await networkService.getAttemptForReview(attemptId: attemptId)
            self.selectedAttempt = result
            self.isLoading = false
        } catch {
            self.error = error
            self.isLoading = false
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
        error = nil

        do {
            let request = ReviewAnswerRequestDTO(
                pointsAwarded: points,
                feedback: feedback
            )
            try await networkService.reviewAnswer(
                attemptId: attemptId,
                answerId: answerId,
                request: request
            )

            // Recargar el detalle del intento para reflejar cambios
            let updated = try await networkService.getAttemptForReview(attemptId: attemptId)
            self.selectedAttempt = updated
            self.isSavingReview = false
            self.successMessage = "Respuesta calificada"
        } catch {
            self.error = error
            self.isSavingReview = false
        }
    }

    /// Finaliza la revision de un intento individual.
    ///
    /// - Parameter attemptId: ID del intento.
    public func finalizeAttempt(attemptId: String) async {
        isFinalizing = true
        error = nil

        do {
            try await networkService.finalizeAttempt(attemptId: attemptId)
            self.selectedAttempt = nil
            self.isFinalizing = false
            self.successMessage = "Revision finalizada"
        } catch {
            self.error = error
            self.isFinalizing = false
        }
    }

    /// Finaliza todos los intentos de un assessment.
    ///
    /// - Parameter assessmentId: ID del assessment.
    public func finalizeAll(assessmentId: String) async {
        isFinalizing = true
        error = nil

        do {
            try await networkService.finalizeAll(assessmentId: assessmentId)
            // Recargar la lista de intentos
            let updated = try await networkService.listAttempts(assessmentId: assessmentId)
            self.attempts = updated
            self.isFinalizing = false
            self.successMessage = "Todas las revisiones finalizadas"
        } catch {
            self.error = error
            self.isFinalizing = false
        }
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
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
    public var canFinalizeAll: Bool {
        !attempts.isEmpty && pendingReviewCount == 0 && !isFinalizing
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
