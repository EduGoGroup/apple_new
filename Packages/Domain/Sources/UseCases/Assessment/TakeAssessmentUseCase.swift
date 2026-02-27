import Foundation
import EduFoundation

// MARK: - Assessment State Machine

/// Estados del flujo de tomar una evaluación.
///
/// Transiciones válidas:
/// - IDLE → LOADING (al iniciar carga)
/// - LOADING → READY (carga exitosa)
/// - LOADING → IDLE (error, permite reintentar)
/// - READY → IN_PROGRESS (al iniciar attempt)
/// - IN_PROGRESS → SUBMITTING (al enviar respuestas)
/// - IN_PROGRESS → READY (reset explícito)
/// - SUBMITTING → COMPLETED (submit exitoso)
/// - SUBMITTING → IN_PROGRESS (error, permite reintentar)
public enum TakeAssessmentFlowState: String, Sendable, Equatable, Codable {
    /// Estado inicial, sin datos cargados
    case idle
    /// Cargando assessment desde servidor/cache
    case loading
    /// Assessment listo para iniciar
    case ready
    /// Evaluación en progreso
    case inProgress = "in_progress"
    /// Enviando respuestas al servidor
    case submitting
    /// Evaluación completada
    case completed
}

/// Errores de transición de estado inválida.
public enum TakeAssessmentFlowError: Error, Sendable, Equatable {
    case invalidTransition(from: TakeAssessmentFlowState, to: TakeAssessmentFlowState)
    case cannotSubmitFromState(TakeAssessmentFlowState)
    case cannotStartFromState(TakeAssessmentFlowState)
    case attemptExpired
    case incompleteAnswers(missing: Int)
    case duplicateSubmission
    case assessmentNotLoaded
    case noAttemptInProgress
}

extension TakeAssessmentFlowError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidTransition(let from, let to):
            return "Transición inválida de \(from.rawValue) a \(to.rawValue)"
        case .cannotSubmitFromState(let state):
            return "No se puede enviar desde estado \(state.rawValue)"
        case .cannotStartFromState(let state):
            return "No se puede iniciar desde estado \(state.rawValue)"
        case .attemptExpired:
            return "El tiempo para completar la evaluación ha expirado"
        case .incompleteAnswers(let missing):
            return "Faltan \(missing) respuestas requeridas"
        case .duplicateSubmission:
            return "Esta evaluación ya fue enviada"
        case .assessmentNotLoaded:
            return "La evaluación no ha sido cargada"
        case .noAttemptInProgress:
            return "No hay un intento en progreso"
        }
    }
}

// MARK: - Input/Output Types

/// Input para tomar una evaluación.
public struct TakeAssessmentInput: Sendable, Equatable {
    /// ID de la evaluación
    public let assessmentId: UUID
    /// ID del usuario
    public let userId: UUID

    public init(assessmentId: UUID, userId: UUID) {
        self.assessmentId = assessmentId
        self.userId = userId
    }
}

/// Pregunta de una evaluación.
public struct AssessmentQuestion: Sendable, Equatable, Identifiable, Codable {
    public let id: UUID
    public let text: String
    public let options: [QuestionOption]
    public let isRequired: Bool
    public let orderIndex: Int

    public init(
        id: UUID,
        text: String,
        options: [QuestionOption],
        isRequired: Bool = true,
        orderIndex: Int
    ) {
        self.id = id
        self.text = text
        self.options = options
        self.isRequired = isRequired
        self.orderIndex = orderIndex
    }
}

/// Opción de respuesta para una pregunta.
public struct QuestionOption: Sendable, Equatable, Identifiable, Codable {
    public let id: UUID
    public let text: String
    public let orderIndex: Int

    public init(id: UUID, text: String, orderIndex: Int) {
        self.id = id
        self.text = text
        self.orderIndex = orderIndex
    }
}

/// Evaluación completa cargada del servidor.
public struct Assessment: Sendable, Equatable, Identifiable, Codable {
    public let id: UUID
    public let materialId: UUID
    public let title: String
    public let description: String?
    public let questions: [AssessmentQuestion]
    public let timeLimitSeconds: Int?
    public let maxAttempts: Int
    public let passThreshold: Int
    public let attemptsUsed: Int
    public let expiresAt: Date?

    public init(
        id: UUID,
        materialId: UUID,
        title: String,
        description: String? = nil,
        questions: [AssessmentQuestion],
        timeLimitSeconds: Int? = nil,
        maxAttempts: Int = 3,
        passThreshold: Int = 70,
        attemptsUsed: Int = 0,
        expiresAt: Date? = nil
    ) {
        self.id = id
        self.materialId = materialId
        self.title = title
        self.description = description
        self.questions = questions
        self.timeLimitSeconds = timeLimitSeconds
        self.maxAttempts = maxAttempts
        self.passThreshold = passThreshold
        self.attemptsUsed = attemptsUsed
        self.expiresAt = expiresAt
    }

    /// Verifica si el usuario puede tomar la evaluación.
    public var canTake: Bool {
        let hasAttemptsLeft = attemptsUsed < maxAttempts
        let notExpired = expiresAt.map { $0 > Date() } ?? true
        return hasAttemptsLeft && notExpired
    }

    /// Intentos restantes.
    public var attemptsLeft: Int {
        max(0, maxAttempts - attemptsUsed)
    }
}

/// Respuesta del usuario a una pregunta.
public struct UserAnswer: Sendable, Equatable, Codable {
    public let questionId: UUID
    public let selectedOptionId: UUID
    public let timeSpentSeconds: Int
    public let answeredAt: Date

    public init(
        questionId: UUID,
        selectedOptionId: UUID,
        timeSpentSeconds: Int,
        answeredAt: Date = Date()
    ) {
        self.questionId = questionId
        self.selectedOptionId = selectedOptionId
        self.timeSpentSeconds = timeSpentSeconds
        self.answeredAt = answeredAt
    }
}

/// Feedback de una pregunta después del submit.
public struct AnswerFeedback: Sendable, Equatable, Codable {
    public let questionId: UUID
    public let isCorrect: Bool
    public let correctOptionId: UUID
    public let explanation: String?

    public init(
        questionId: UUID,
        isCorrect: Bool,
        correctOptionId: UUID,
        explanation: String? = nil
    ) {
        self.questionId = questionId
        self.isCorrect = isCorrect
        self.correctOptionId = correctOptionId
        self.explanation = explanation
    }
}

/// Resultado de un intento de evaluación.
public struct AttemptResult: Sendable, Equatable, Codable {
    public let attemptId: UUID
    public let assessmentId: UUID
    public let userId: UUID
    public let score: Int
    public let maxScore: Int
    public let passed: Bool
    public let correctAnswers: Int
    public let totalQuestions: Int
    public let timeSpentSeconds: Int
    public let feedback: [AnswerFeedback]
    public let startedAt: Date
    public let completedAt: Date
    public let canRetake: Bool

    public init(
        attemptId: UUID,
        assessmentId: UUID,
        userId: UUID,
        score: Int,
        maxScore: Int,
        passed: Bool,
        correctAnswers: Int,
        totalQuestions: Int,
        timeSpentSeconds: Int,
        feedback: [AnswerFeedback],
        startedAt: Date,
        completedAt: Date,
        canRetake: Bool
    ) {
        self.attemptId = attemptId
        self.assessmentId = assessmentId
        self.userId = userId
        self.score = score
        self.maxScore = maxScore
        self.passed = passed
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.timeSpentSeconds = timeSpentSeconds
        self.feedback = feedback
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.canRetake = canRetake
    }

    /// Porcentaje de aciertos.
    public var percentage: Double {
        guard maxScore > 0 else { return 0 }
        return Double(score) / Double(maxScore) * 100
    }
}

/// Estado persistido de un intento en progreso.
public struct InProgressAttempt: Sendable, Equatable, Codable {
    public let attemptId: UUID
    public let assessmentId: UUID
    public let userId: UUID
    public let answers: [UserAnswer]
    public let startedAt: Date
    public let lastUpdatedAt: Date
    public let idempotencyKey: String

    public init(
        attemptId: UUID,
        assessmentId: UUID,
        userId: UUID,
        answers: [UserAnswer] = [],
        startedAt: Date = Date(),
        lastUpdatedAt: Date = Date(),
        idempotencyKey: String = UUID().uuidString
    ) {
        self.attemptId = attemptId
        self.assessmentId = assessmentId
        self.userId = userId
        self.answers = answers
        self.startedAt = startedAt
        self.lastUpdatedAt = lastUpdatedAt
        self.idempotencyKey = idempotencyKey
    }

    /// Crea una copia con una respuesta actualizada o agregada.
    public func withAnswer(_ answer: UserAnswer) -> InProgressAttempt {
        var updatedAnswers = answers.filter { $0.questionId != answer.questionId }
        updatedAnswers.append(answer)
        return InProgressAttempt(
            attemptId: attemptId,
            assessmentId: assessmentId,
            userId: userId,
            answers: updatedAnswers,
            startedAt: startedAt,
            lastUpdatedAt: Date(),
            idempotencyKey: idempotencyKey
        )
    }

    /// Tiempo transcurrido desde el inicio.
    public var elapsedSeconds: Int {
        Int(Date().timeIntervalSince(startedAt))
    }
}

/// Submission pendiente para sync offline.
public struct PendingSubmission: Sendable, Equatable, Codable, Identifiable {
    public let id: UUID
    public let attemptId: UUID
    public let assessmentId: UUID
    public let userId: UUID
    public let answers: [UserAnswer]
    public let timeSpentSeconds: Int
    public let idempotencyKey: String
    public let createdAt: Date
    public var retryCount: Int

    public init(
        id: UUID = UUID(),
        attemptId: UUID,
        assessmentId: UUID,
        userId: UUID,
        answers: [UserAnswer],
        timeSpentSeconds: Int,
        idempotencyKey: String,
        createdAt: Date = Date(),
        retryCount: Int = 0
    ) {
        self.id = id
        self.attemptId = attemptId
        self.assessmentId = assessmentId
        self.userId = userId
        self.answers = answers
        self.timeSpentSeconds = timeSpentSeconds
        self.idempotencyKey = idempotencyKey
        self.createdAt = createdAt
        self.retryCount = retryCount
    }
}

// MARK: - Repository Protocols

/// Protocolo del repositorio de assessments.
public protocol AssessmentsRepositoryProtocol: Sendable {
    /// Obtiene un assessment por ID.
    func get(id: UUID) async throws -> Assessment

    /// Obtiene un assessment desde cache local.
    func getCached(id: UUID) async -> Assessment?

    /// Guarda un assessment en cache.
    func cache(_ assessment: Assessment) async
}

/// Protocolo del repositorio de attempts.
public protocol AttemptsRepositoryProtocol: Sendable {
    /// Inicia un nuevo intento.
    func startAttempt(assessmentId: UUID, userId: UUID) async throws -> UUID

    /// Envía las respuestas de un intento.
    func submitAttempt(
        attemptId: UUID,
        answers: [UserAnswer],
        timeSpentSeconds: Int,
        idempotencyKey: String
    ) async throws -> AttemptResult
}

/// Protocolo del servicio de almacenamiento local.
public protocol LocalStorageServiceProtocol: Sendable {
    /// Guarda el estado actual del assessment.
    func saveState(_ state: TakeAssessmentFlowState, for assessmentId: UUID) async

    /// Obtiene el estado guardado.
    func getState(for assessmentId: UUID) async -> TakeAssessmentFlowState?

    /// Guarda un intento en progreso.
    func saveInProgressAttempt(_ attempt: InProgressAttempt) async

    /// Obtiene un intento en progreso.
    func getInProgressAttempt(for assessmentId: UUID) async -> InProgressAttempt?

    /// Elimina un intento en progreso.
    func removeInProgressAttempt(for assessmentId: UUID) async

    /// Agrega una submission pendiente.
    func addPendingSubmission(_ submission: PendingSubmission) async

    /// Obtiene todas las submissions pendientes.
    func getPendingSubmissions() async -> [PendingSubmission]

    /// Elimina una submission pendiente.
    func removePendingSubmission(id: UUID) async

    /// Actualiza el retry count de una submission.
    func updatePendingSubmissionRetryCount(id: UUID, retryCount: Int) async
}

// MARK: - TakeAssessmentUseCase

/// Actor que maneja el flujo completo de tomar una evaluación con state machine.
///
/// Implementa:
/// - State machine con transiciones validadas
/// - Persistencia local de progreso (offline support)
/// - Queue de submissions pendientes para sync
/// - Validaciones de tiempo límite y completitud
/// - Idempotency para prevenir duplicados
///
/// ## Flujo de Uso
/// ```swift
/// let useCase = TakeAssessmentUseCase(...)
/// let input = TakeAssessmentInput(assessmentId: id, userId: userId)
///
/// // 1. Cargar assessment
/// let assessment = try await useCase.loadAssessment(input: input)
///
/// // 2. Iniciar intento
/// let attemptId = try await useCase.startAttempt()
///
/// // 3. Guardar respuestas (puede ser offline)
/// try await useCase.saveAnswer(questionId: q1, selectedOptionId: opt1, timeSpent: 30)
///
/// // 4. Enviar respuestas
/// let result = try await useCase.submitAttempt()
/// ```
public actor TakeAssessmentUseCase {

    // MARK: - Dependencies

    private let assessmentsRepository: AssessmentsRepositoryProtocol
    private let attemptsRepository: AttemptsRepositoryProtocol
    private let localStorage: LocalStorageServiceProtocol

    // MARK: - State

    private var currentState: TakeAssessmentFlowState = .idle
    private var currentAssessment: Assessment?
    private var currentAttempt: InProgressAttempt?
    private var currentInput: TakeAssessmentInput?
    private var submittedIdempotencyKeys: Set<String> = []

    // MARK: - Configuration

    private let maxRetries = 3

    // MARK: - Initialization

    public init(
        assessmentsRepository: AssessmentsRepositoryProtocol,
        attemptsRepository: AttemptsRepositoryProtocol,
        localStorage: LocalStorageServiceProtocol
    ) {
        self.assessmentsRepository = assessmentsRepository
        self.attemptsRepository = attemptsRepository
        self.localStorage = localStorage
    }

    // MARK: - Public API

    /// Estado actual del flujo.
    public var state: TakeAssessmentFlowState {
        currentState
    }

    /// Assessment actualmente cargado.
    public var assessment: Assessment? {
        currentAssessment
    }

    /// Intento actualmente en progreso.
    public var inProgressAttempt: InProgressAttempt? {
        currentAttempt
    }

    /// Carga un assessment desde el servidor o cache.
    ///
    /// - Parameter input: Input con assessmentId y userId
    /// - Returns: Assessment cargado
    /// - Throws: Error si la carga falla y no hay cache
    public func loadAssessment(input: TakeAssessmentInput) async throws -> Assessment {
        guard currentState == .idle || currentState == .ready else {
            throw TakeAssessmentFlowError.invalidTransition(from: currentState, to: .loading)
        }

        currentInput = input
        try await transitionTo(.loading)

        do {
            // Intentar cargar del servidor
            let assessment = try await assessmentsRepository.get(id: input.assessmentId)

            // Cachear para uso offline
            await assessmentsRepository.cache(assessment)

            currentAssessment = assessment
            try await transitionTo(.ready)

            // Verificar si hay un intento en progreso guardado
            if let savedAttempt = await localStorage.getInProgressAttempt(for: input.assessmentId),
               savedAttempt.userId == input.userId {
                currentAttempt = savedAttempt
                try await transitionTo(.inProgress)
            }

            return assessment

        } catch {
            // Intentar usar cache si falla la red
            if let cached = await assessmentsRepository.getCached(id: input.assessmentId) {
                currentAssessment = cached
                try await transitionTo(.ready)

                // Verificar intento en progreso
                if let savedAttempt = await localStorage.getInProgressAttempt(for: input.assessmentId),
                   savedAttempt.userId == input.userId {
                    currentAttempt = savedAttempt
                    try await transitionTo(.inProgress)
                }

                return cached
            }

            // No hay cache, volver a idle y propagar error
            try await transitionTo(.idle)
            throw error
        }
    }

    /// Inicia un nuevo intento de la evaluación.
    ///
    /// - Returns: ID del intento creado
    /// - Throws: Error si el estado no permite iniciar o la evaluación expiró
    public func startAttempt() async throws -> UUID {
        guard currentState == .ready else {
            throw TakeAssessmentFlowError.cannotStartFromState(currentState)
        }

        guard let assessment = currentAssessment else {
            throw TakeAssessmentFlowError.assessmentNotLoaded
        }

        guard let input = currentInput else {
            throw TakeAssessmentFlowError.assessmentNotLoaded
        }

        guard assessment.canTake else {
            if assessment.attemptsLeft == 0 {
                throw UseCaseError.preconditionFailed(
                    description: "No quedan intentos disponibles"
                )
            } else {
                throw UseCaseError.preconditionFailed(
                    description: "La evaluación ha expirado"
                )
            }
        }

        // Crear intento en el servidor
        let attemptId = try await attemptsRepository.startAttempt(
            assessmentId: assessment.id,
            userId: input.userId
        )

        // Crear estado local
        let attempt = InProgressAttempt(
            attemptId: attemptId,
            assessmentId: assessment.id,
            userId: input.userId
        )

        currentAttempt = attempt
        await localStorage.saveInProgressAttempt(attempt)

        try await transitionTo(.inProgress)

        return attemptId
    }

    /// Guarda una respuesta del usuario.
    ///
    /// Persiste localmente para soporte offline.
    ///
    /// - Parameters:
    ///   - questionId: ID de la pregunta
    ///   - selectedOptionId: ID de la opción seleccionada
    ///   - timeSpentSeconds: Tiempo empleado en la pregunta
    public func saveAnswer(
        questionId: UUID,
        selectedOptionId: UUID,
        timeSpentSeconds: Int
    ) async throws {
        guard currentState == .inProgress else {
            throw TakeAssessmentFlowError.noAttemptInProgress
        }

        guard var attempt = currentAttempt else {
            throw TakeAssessmentFlowError.noAttemptInProgress
        }

        // Verificar tiempo límite
        if let assessment = currentAssessment,
           let timeLimit = assessment.timeLimitSeconds,
           attempt.elapsedSeconds > timeLimit {
            throw TakeAssessmentFlowError.attemptExpired
        }

        let answer = UserAnswer(
            questionId: questionId,
            selectedOptionId: selectedOptionId,
            timeSpentSeconds: timeSpentSeconds
        )

        attempt = attempt.withAnswer(answer)
        currentAttempt = attempt

        // Persistir localmente
        await localStorage.saveInProgressAttempt(attempt)
    }

    /// Envía las respuestas y completa el intento.
    ///
    /// - Returns: Resultado del intento con score y feedback
    /// - Throws: Error si las respuestas están incompletas o el tiempo expiró
    public func submitAttempt() async throws -> AttemptResult {
        guard currentState == .inProgress else {
            throw TakeAssessmentFlowError.cannotSubmitFromState(currentState)
        }

        guard let attempt = currentAttempt else {
            throw TakeAssessmentFlowError.noAttemptInProgress
        }

        guard let assessment = currentAssessment else {
            throw TakeAssessmentFlowError.assessmentNotLoaded
        }

        // Verificar duplicado
        if submittedIdempotencyKeys.contains(attempt.idempotencyKey) {
            throw TakeAssessmentFlowError.duplicateSubmission
        }

        // Verificar tiempo límite
        if let timeLimit = assessment.timeLimitSeconds,
           attempt.elapsedSeconds > timeLimit {
            throw TakeAssessmentFlowError.attemptExpired
        }

        // Verificar completitud
        let requiredQuestionIds = Set(assessment.questions.filter { $0.isRequired }.map { $0.id })
        let answeredQuestionIds = Set(attempt.answers.map { $0.questionId })
        let missingCount = requiredQuestionIds.subtracting(answeredQuestionIds).count

        if missingCount > 0 {
            throw TakeAssessmentFlowError.incompleteAnswers(missing: missingCount)
        }

        try await transitionTo(.submitting)

        do {
            let result = try await attemptsRepository.submitAttempt(
                attemptId: attempt.attemptId,
                answers: attempt.answers,
                timeSpentSeconds: attempt.elapsedSeconds,
                idempotencyKey: attempt.idempotencyKey
            )

            // Marcar como enviado
            submittedIdempotencyKeys.insert(attempt.idempotencyKey)

            // Limpiar estado local
            await localStorage.removeInProgressAttempt(for: assessment.id)

            currentAttempt = nil
            try await transitionTo(.completed)

            return result

        } catch {
            // Guardar para retry offline
            let pending = PendingSubmission(
                attemptId: attempt.attemptId,
                assessmentId: assessment.id,
                userId: attempt.userId,
                answers: attempt.answers,
                timeSpentSeconds: attempt.elapsedSeconds,
                idempotencyKey: attempt.idempotencyKey
            )
            await localStorage.addPendingSubmission(pending)

            // Volver a in_progress para permitir reintento
            try await transitionTo(.inProgress)

            throw error
        }
    }

    /// Reinicia el estado para tomar otra evaluación.
    public func reset() async {
        currentState = .idle
        currentAssessment = nil
        currentAttempt = nil
        currentInput = nil

        if let input = currentInput {
            await localStorage.saveState(.idle, for: input.assessmentId)
        }
    }

    /// Intenta sincronizar submissions pendientes.
    ///
    /// - Returns: Número de submissions sincronizadas exitosamente
    public func syncPendingSubmissions() async -> Int {
        let pending = await localStorage.getPendingSubmissions()
        var syncedCount = 0

        for submission in pending {
            guard submission.retryCount < maxRetries else {
                continue
            }

            do {
                _ = try await attemptsRepository.submitAttempt(
                    attemptId: submission.attemptId,
                    answers: submission.answers,
                    timeSpentSeconds: submission.timeSpentSeconds,
                    idempotencyKey: submission.idempotencyKey
                )

                await localStorage.removePendingSubmission(id: submission.id)
                submittedIdempotencyKeys.insert(submission.idempotencyKey)
                syncedCount += 1

            } catch {
                await localStorage.updatePendingSubmissionRetryCount(
                    id: submission.id,
                    retryCount: submission.retryCount + 1
                )
            }
        }

        return syncedCount
    }

    /// Verifica si hay un intento pendiente de recuperar.
    ///
    /// - Parameter input: Input con assessmentId y userId
    /// - Returns: Intento en progreso si existe
    public func checkForRecoverableAttempt(input: TakeAssessmentInput) async -> InProgressAttempt? {
        await localStorage.getInProgressAttempt(for: input.assessmentId)
    }

    // MARK: - Private Methods

    /// Valida y ejecuta una transición de estado.
    private func transitionTo(_ newState: TakeAssessmentFlowState) async throws {
        let validTransitions: [TakeAssessmentFlowState: Set<TakeAssessmentFlowState>] = [
            .idle: [.loading],
            .loading: [.ready, .idle],
            .ready: [.inProgress, .loading],
            .inProgress: [.submitting, .ready],
            .submitting: [.completed, .inProgress],
            .completed: [.idle]
        ]

        guard let allowed = validTransitions[currentState],
              allowed.contains(newState) else {
            throw TakeAssessmentFlowError.invalidTransition(from: currentState, to: newState)
        }

        currentState = newState

        if let input = currentInput {
            await localStorage.saveState(newState, for: input.assessmentId)
        }
    }
}
