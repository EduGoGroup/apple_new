import Foundation
import SwiftUI
import EduDomain
import EduCore
import EduFoundation
import EduDomain

/// ViewModel para Assessment usando CQRS Mediator.
///
/// Este ViewModel se refactorizó para usar el patrón CQRS en lugar de
/// llamar use cases directamente. Gestiona el ciclo completo de una
/// evaluación: carga, respuestas y envío.
///
/// ## Responsabilidades
/// - Cargar evaluación via GetAssessmentQuery (con proyecciones)
/// - Gestionar respuestas del usuario en memoria
/// - Enviar evaluación via SubmitAssessmentCommand
/// - Suscribirse a AssessmentSubmittedEvent para actualizar estado
///
/// ## Integración con CQRS
/// - **Queries**: GetAssessmentQuery (con cache y proyecciones)
/// - **Commands**: SubmitAssessmentCommand (con validación)
/// - **Events**: AssessmentSubmittedEvent (auto-refresh)
///
/// ## Proyecciones
/// - `.full`: Carga completa con preguntas (para tomar evaluación)
/// - `.preview`: Solo metadata (para vista previa)
/// - `.metadataOnly`: Sin preguntas ni eligibility
///
/// ## Ejemplo de uso
/// ```swift
/// @StateObject private var viewModel = AssessmentViewModel(
///     mediator: mediator,
///     eventBus: eventBus,
///     assessmentId: assessmentId,
///     userId: currentUserId
/// )
/// ```
@MainActor
@Observable
public final class AssessmentViewModel {

    // MARK: - Published State

    /// Detalle de la evaluación
    public var assessmentDetail: AssessmentDetail?

    /// Respuestas del usuario en progreso
    public var answers: [UUID: UserAnswer] = [:]

    /// Indica si está cargando
    public var isLoading: Bool = false

    /// Indica si está enviando
    public var isSubmitting: Bool = false

    /// Error actual si lo hay
    public var error: Error?

    /// Resultado del intento después del envío
    public var attemptResult: AttemptResult?

    /// Tiempo transcurrido en segundos.
    ///
    /// Calculado desde `startDate` cuando el timer esta activo,
    /// para que sea correcto incluso despues de background/suspend.
    public var elapsedSeconds: Int = 0

    /// Fecha de inicio del timer, usada para calcular tiempo real transcurrido.
    private var startDate: Date?

    /// Timer para actualizar `elapsedSeconds` cada segundo en la UI.
    private var timer: Timer?

    // MARK: - Dependencies

    /// Mediator CQRS para dispatch de queries y commands
    private let mediator: Mediator

    /// EventBus para suscripción a eventos
    private let eventBus: EventBus

    /// ID de la evaluación
    private let assessmentId: UUID

    /// ID del usuario
    private let userId: UUID

    /// IDs de suscripciones a eventos (para cleanup)
    private var subscriptionIds: [UUID] = []

    // MARK: - Initialization

    /// Crea un nuevo AssessmentViewModel.
    ///
    /// - Parameters:
    ///   - mediator: Mediator CQRS para ejecutar queries/commands
    ///   - eventBus: EventBus para suscribirse a eventos de dominio
    ///   - assessmentId: ID de la evaluación
    ///   - userId: ID del usuario actual
    public init(
        mediator: Mediator,
        eventBus: EventBus,
        assessmentId: UUID,
        userId: UUID
    ) {
        self.mediator = mediator
        self.eventBus = eventBus
        self.assessmentId = assessmentId
        self.userId = userId

        // Suscribirse a eventos relevantes
        Task {
            await subscribeToEvents()
        }
    }

    // MARK: - Public Methods

    /// Carga la evaluación con proyección específica.
    ///
    /// - Parameters:
    ///   - projection: Proyección de campos a cargar (default: .full)
    ///   - forceRefresh: Forzar recarga ignorando cache
    public func loadAssessment(
        projection: AssessmentProjection = .full,
        forceRefresh: Bool = false
    ) async {
        isLoading = true
        error = nil

        do {
            // Crear query con proyección
            let query = GetAssessmentQuery(
                assessmentId: assessmentId,
                userId: userId,
                projection: projection,
                forceRefresh: forceRefresh,
                metadata: [
                    "source": "AssessmentViewModel",
                    "timestamp": ISO8601DateFormatter().string(from: Date())
                ]
            )

            // Ejecutar query via Mediator
            let detail = try await mediator.send(query)

            // Actualizar estado
            self.assessmentDetail = detail
            self.isLoading = false

            // Si se cargó con preguntas, iniciar timer
            if projection.includeQuestions {
                startTimer()
            }

        } catch {
            self.error = error
            self.isLoading = false

            print("❌ Error loading assessment: \(error.localizedDescription)")
        }
    }

    /// Guarda la respuesta de una pregunta.
    ///
    /// - Parameters:
    ///   - questionId: ID de la pregunta
    ///   - selectedOptionId: ID de la opción seleccionada
    public func saveAnswer(questionId: UUID, selectedOptionId: UUID) {
        let answer = UserAnswer(
            questionId: questionId,
            selectedOptionId: selectedOptionId,
            timeSpentSeconds: elapsedSeconds
        )
        answers[questionId] = answer
    }

    /// Envía la evaluación con las respuestas del usuario.
    ///
    /// Ejecuta SubmitAssessmentCommand que valida automáticamente:
    /// - Todas las respuestas requeridas están completas
    /// - No se excedió el tiempo límite
    /// - No se ha enviado previamente
    public func submitAssessment() async {
        guard let assessment = assessmentDetail?.assessment else {
            error = TakeAssessmentFlowError.assessmentNotLoaded
            return
        }

        isSubmitting = true
        error = nil

        // Detener timer
        stopTimer()

        do {
            // Crear command con respuestas
            let command = SubmitAssessmentCommand(
                assessmentId: assessmentId,
                userId: userId,
                answers: Array(answers.values),
                timeSpentSeconds: elapsedSeconds,
                metadata: [
                    "source": "AssessmentViewModel",
                    "questionsAnswered": "\(answers.count)",
                    "totalQuestions": "\(assessment.questions.count)"
                ]
            )

            // Ejecutar command via Mediator (con validación automática)
            let result = try await mediator.execute(command)

            // Verificar resultado
            if result.isSuccess, let attempt = result.getValue() {
                // Envío exitoso
                self.attemptResult = attempt
                self.isSubmitting = false

                // Limpiar respuestas
                self.answers.removeAll()
                self.elapsedSeconds = 0

                print("✅ Assessment submitted. Score: \(attempt.score)/\(attempt.maxScore)")
                print("   Eventos: \(result.events)")

            } else if let error = result.getError() {
                // Envío falló
                self.error = error
                self.isSubmitting = false

                print("❌ Submit failed: \(error.localizedDescription)")
            }

        } catch {
            self.error = error
            self.isSubmitting = false

            print("❌ Error submitting assessment: \(error.localizedDescription)")
        }
    }

    /// Limpia el error actual.
    public func clearError() {
        error = nil
    }

    /// Reinicia el estado del ViewModel para un nuevo intento.
    public func reset() {
        answers.removeAll()
        elapsedSeconds = 0
        startDate = nil
        attemptResult = nil
        error = nil
        stopTimer()
    }

    // MARK: - Timer Management

    /// Inicia el timer de tracking de tiempo.
    ///
    /// Usa `startDate` para calcular el tiempo real transcurrido en cada tick,
    /// lo que garantiza precision incluso si la app estuvo en background.
    private func startTimer() {
        stopTimer() // Detener timer anterior si existe

        startDate = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let start = self.startDate else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }

    /// Detiene el timer de tracking de tiempo.
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Event Subscriptions

    /// Suscribe el ViewModel a eventos relevantes.
    private func subscribeToEvents() async {
        // Suscribirse a AssessmentSubmittedEvent para actualizar después del envío
        let subscriptionId = await eventBus.subscribe(to: AssessmentSubmittedEvent.self) { [weak self] event in
            guard let self = self else { return }

            // Verificar que el evento sea para esta evaluación y usuario
            if event.assessmentId == self.assessmentId && event.userId == self.userId {
                await MainActor.run {
                    // El resultado ya se actualizó en submitAssessment()
                    // Aquí podríamos hacer cleanup adicional si es necesario
                    print("📢 Received AssessmentSubmittedEvent")
                }
            }
        }
        subscriptionIds.append(subscriptionId)
    }
}

// MARK: - Convenience Computed Properties

extension AssessmentViewModel {
    /// Indica si hay evaluación cargada
    public var hasAssessment: Bool {
        assessmentDetail != nil
    }

    /// Indica si hay un error
    public var hasError: Bool {
        error != nil
    }

    /// Indica si todas las preguntas han sido respondidas
    public var allQuestionsAnswered: Bool {
        guard let assessment = assessmentDetail?.assessment else { return false }
        return answers.count == assessment.questions.count
    }

    /// Indica si el botón de envío debe estar habilitado
    public var canSubmit: Bool {
        hasAssessment && allQuestionsAnswered && !isSubmitting
    }

    /// Indica si el usuario puede tomar la evaluación
    public var canTakeAssessment: Bool {
        assessmentDetail?.eligibility.canTake ?? false
    }

    /// Número de intentos restantes
    public var attemptsLeft: Int {
        assessmentDetail?.eligibility.attemptsLeft ?? 0
    }

    /// Mensaje de error legible
    public var errorMessage: String? {
        guard let error = error else { return nil }

        // Personalizar mensajes según tipo de error
        if let stateError = error as? TakeAssessmentFlowError {
            switch stateError {
            case .assessmentNotLoaded:
                return "La evaluación no está cargada"
            case .noAttemptInProgress:
                return "No hay un intento en progreso"
            case .duplicateSubmission:
                return "Este intento ya fue enviado"
            case .invalidTransition, .cannotSubmitFromState, .cannotStartFromState:
                return "Operación no permitida en el estado actual"
            case .attemptExpired:
                return "El tiempo para completar la evaluación ha expirado"
            case .incompleteAnswers(let missing):
                return "Faltan \(missing) respuestas requeridas"
            }
        }

        if let validationError = error as? ValidationError {
            return validationError.localizedDescription
        }

        if let mediatorError = error as? MediatorError {
            switch mediatorError {
            case .handlerNotFound:
                return "Error de configuración del sistema"
            case .validationError(let message, _):
                return message
            case .executionError(let message, _):
                return message
            case .registrationError:
                return "Error de configuración del sistema"
            }
        }

        return error.localizedDescription
    }

    /// Tiempo formateado (MM:SS)
    public var formattedTime: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
