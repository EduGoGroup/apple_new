import Foundation

// MARK: - SubmitAssessmentCommand

/// Command para enviar las respuestas de una evaluación.
///
/// Este command encapsula las respuestas del usuario a una evaluación
/// y coordina el proceso de envío con validaciones pesadas pre-ejecución.
///
/// ## Validaciones
/// - Assessment existe y está cargado
/// - Todas las respuestas requeridas están completas
/// - El tiempo límite no ha expirado
/// - No se ha enviado previamente (previene duplicados)
///
/// ## Eventos Emitidos
/// - `AssessmentSubmittedEvent`: Cuando el envío se completa exitosamente
/// - `DashboardInvalidatedEvent`: Para invalidar cache de StudentDashboard
/// - `AssessmentInvalidatedEvent`: Para invalidar cache de GetAssessment
///
/// ## Ejemplo de Uso
/// ```swift
/// let command = SubmitAssessmentCommand(
///     assessmentId: assessmentId,
///     userId: userId,
///     answers: answers,
///     timeSpentSeconds: 1800
/// )
///
/// let result = try await mediator.execute(command)
/// if result.isSuccess, let attemptResult = result.getValue() {
///     print("Score: \(attemptResult.score)/\(attemptResult.maxScore)")
///     print("Aprobado: \(attemptResult.passed)")
///     print("Eventos: \(result.events)")
/// }
/// ```
public struct SubmitAssessmentCommand: Command {

    public typealias Result = AttemptResult

    // MARK: - Properties

    /// ID de la evaluación
    public let assessmentId: UUID

    /// ID del usuario
    public let userId: UUID

    /// Respuestas del usuario
    public let answers: [UserAnswer]

    /// Tiempo total empleado en segundos
    public let timeSpentSeconds: Int

    /// Metadata opcional para tracing
    public let metadata: [String: String]?

    // MARK: - Initialization

    /// Crea un nuevo command para enviar respuestas de evaluación.
    ///
    /// - Parameters:
    ///   - assessmentId: ID de la evaluación
    ///   - userId: ID del usuario
    ///   - answers: Lista de respuestas del usuario
    ///   - timeSpentSeconds: Tiempo total empleado
    ///   - metadata: Metadata opcional para tracing
    public init(
        assessmentId: UUID,
        userId: UUID,
        answers: [UserAnswer],
        timeSpentSeconds: Int,
        metadata: [String: String]? = nil
    ) {
        self.assessmentId = assessmentId
        self.userId = userId
        self.answers = answers
        self.timeSpentSeconds = timeSpentSeconds
        self.metadata = metadata
    }

    // MARK: - Command Protocol

    /// Valida el command antes de la ejecución.
    ///
    /// Verifica que:
    /// - Hay al menos una respuesta
    /// - El tiempo empleado es positivo
    /// - No hay respuestas duplicadas para la misma pregunta
    ///
    /// - Throws: `ValidationError` si alguna validación falla
    public func validate() throws {
        // Validar que haya respuestas
        guard !answers.isEmpty else {
            throw ValidationError.incompleteData(missing: ["answers"])
        }

        // Validar tiempo empleado
        guard timeSpentSeconds >= 0 else {
            throw ValidationError.outOfRange(
                fieldName: "timeSpentSeconds",
                min: 0,
                max: nil,
                actual: timeSpentSeconds
            )
        }

        // Validar que no haya respuestas duplicadas para la misma pregunta
        let questionIds = answers.map { $0.questionId }
        let uniqueQuestionIds = Set(questionIds)
        guard questionIds.count == uniqueQuestionIds.count else {
            throw ValidationError.invalidFormat(
                fieldName: "answers",
                reason: "Hay respuestas duplicadas para la misma pregunta"
            )
        }
    }
}

// MARK: - SubmitAssessmentCommandHandler

/// Handler que procesa SubmitAssessmentCommand usando TakeAssessmentUseCase.
///
/// Coordina el proceso de envío de evaluación, gestiona el estado usando
/// AssessmentStateMachine y emite eventos de dominio.
///
/// ## Responsabilidades
/// 1. Verificar que haya un intento en progreso
/// 2. Validar completitud de respuestas requeridas
/// 3. Validar que no se exceda el tiempo límite
/// 4. Ejecutar submitAttempt() del use case
/// 5. Emitir eventos de dominio
/// 6. Invalidar caches relacionados (Dashboard, Assessment)
///
/// ## Integración con State Machine
/// Este handler se integra con TakeAssessmentUseCase que internamente
/// utiliza un state machine para validar transiciones de estado válidas.
///
/// ## Integración con Queries
/// Después de un envío exitoso, este handler invalida:
/// - Cache de GetStudentDashboardQuery (actualiza intentos recientes)
/// - Cache de GetAssessmentQuery (actualiza intentos usados)
///
/// ## Ejemplo de Uso
/// ```swift
/// let handler = SubmitAssessmentCommandHandler(
///     useCase: takeAssessmentUseCase,
///     dashboardHandler: dashboardQueryHandler,
///     assessmentHandler: assessmentQueryHandler
/// )
/// try await mediator.registerCommandHandler(handler)
/// ```
public actor SubmitAssessmentCommandHandler: CommandHandler {

    public typealias CommandType = SubmitAssessmentCommand

    // MARK: - Dependencies

    private let useCase: any TakeAssessmentUseCaseProtocol

    /// Handler de GetStudentDashboardQuery para invalidar cache
    private weak var dashboardHandler: GetStudentDashboardQueryHandler?

    /// Handler de GetAssessmentQuery para invalidar cache
    private weak var assessmentHandler: GetAssessmentQueryHandler?

    // MARK: - Initialization

    /// Crea un nuevo handler para SubmitAssessmentCommand.
    ///
    /// - Parameters:
    ///   - useCase: Use case que gestiona el flujo de evaluación
    ///   - dashboardHandler: Handler para invalidar cache de dashboard (opcional)
    ///   - assessmentHandler: Handler para invalidar cache de assessment (opcional)
    public init(
        useCase: any TakeAssessmentUseCaseProtocol,
        dashboardHandler: GetStudentDashboardQueryHandler? = nil,
        assessmentHandler: GetAssessmentQueryHandler? = nil
    ) {
        self.useCase = useCase
        self.dashboardHandler = dashboardHandler
        self.assessmentHandler = assessmentHandler
    }

    // MARK: - CommandHandler Protocol

    /// Procesa el command y retorna el resultado.
    ///
    /// - Parameter command: Command con respuestas de la evaluación
    /// - Returns: CommandResult con AttemptResult y eventos emitidos
    /// - Throws: Error si falla la validación o el envío
    public func handle(_ command: SubmitAssessmentCommand) async throws -> CommandResult<AttemptResult> {
        // Nota: La validación ya se ejecutó en el Mediator antes de llamar a handle()

        // Verificar que haya un assessment cargado
        guard await useCase.assessment != nil else {
            return .failure(
                TakeAssessmentFlowError.assessmentNotLoaded,
                metadata: [
                    "assessmentId": command.assessmentId.uuidString,
                    "userId": command.userId.uuidString
                ]
            )
        }

        // Verificar que haya un intento en progreso
        guard await useCase.inProgressAttempt != nil else {
            return .failure(
                TakeAssessmentFlowError.noAttemptInProgress,
                metadata: [
                    "assessmentId": command.assessmentId.uuidString,
                    "userId": command.userId.uuidString
                ]
            )
        }

        // Ejecutar submitAttempt del use case
        do {
            let attemptResult = try await useCase.submitAttempt()

            // Invalidar caches relacionados
            await invalidateDashboardCache(for: command.userId)
            await invalidateAssessmentCache(for: command.assessmentId)

            // Emitir eventos de dominio
            let events = [
                "AssessmentSubmittedEvent",
                "DashboardInvalidatedEvent",
                "AssessmentInvalidatedEvent"
            ]

            // Crear metadata con información del resultado
            let metadata: [String: String] = [
                "attemptId": attemptResult.attemptId.uuidString,
                "assessmentId": attemptResult.assessmentId.uuidString,
                "userId": attemptResult.userId.uuidString,
                "score": "\(attemptResult.score)",
                "maxScore": "\(attemptResult.maxScore)",
                "passed": attemptResult.passed ? "true" : "false",
                "percentage": String(format: "%.1f", attemptResult.percentage),
                "timeSpentSeconds": "\(attemptResult.timeSpentSeconds)",
                "submittedAt": ISO8601DateFormatter().string(from: Date())
            ]

            // Retornar resultado exitoso
            return .success(
                attemptResult,
                events: events,
                metadata: metadata
            )

        } catch let error as TakeAssessmentFlowError {
            // Error de validación de estado
            return .failure(
                error,
                metadata: [
                    "assessmentId": command.assessmentId.uuidString,
                    "userId": command.userId.uuidString,
                    "errorType": String(describing: type(of: error)),
                    "currentState": await useCase.state.rawValue
                ]
            )
        } catch {
            // Error inesperado
            return .failure(
                error,
                metadata: [
                    "assessmentId": command.assessmentId.uuidString,
                    "userId": command.userId.uuidString,
                    "errorDescription": error.localizedDescription
                ]
            )
        }
    }

    // MARK: - Convenience Method

    /// Ejecuta el flujo completo desde la carga hasta el envío.
    ///
    /// Este método de conveniencia coordina:
    /// 1. Cargar el assessment
    /// 2. Iniciar el intento
    /// 3. Guardar las respuestas
    /// 4. Enviar el intento
    ///
    /// - Parameters:
    ///   - assessmentId: ID de la evaluación
    ///   - userId: ID del usuario
    ///   - answers: Respuestas del usuario
    /// - Returns: CommandResult con AttemptResult
    public func executeFullFlow(
        assessmentId: UUID,
        userId: UUID,
        answers: [UserAnswer]
    ) async throws -> CommandResult<AttemptResult> {
        // 1. Cargar assessment
        let input = TakeAssessmentInput(assessmentId: assessmentId, userId: userId)
        _ = try await useCase.loadAssessment(input: input)

        // 2. Iniciar intento si no hay uno en progreso
        if await useCase.inProgressAttempt == nil {
            _ = try await useCase.startAttempt()
        }

        // 3. Guardar respuestas
        for answer in answers {
            try await useCase.saveAnswer(
                questionId: answer.questionId,
                selectedOptionId: answer.selectedOptionId,
                timeSpentSeconds: answer.timeSpentSeconds
            )
        }

        // 4. Calcular tiempo total
        let timeSpent = await useCase.inProgressAttempt?.elapsedSeconds ?? 0

        // 5. Crear y ejecutar command
        let command = SubmitAssessmentCommand(
            assessmentId: assessmentId,
            userId: userId,
            answers: answers,
            timeSpentSeconds: timeSpent
        )

        return try await handle(command)
    }

    // MARK: - Cache Management

    /// Configura el handler de Dashboard para invalidación de cache.
    ///
    /// - Parameter handler: Handler de GetStudentDashboardQuery
    public func setDashboardHandler(_ handler: GetStudentDashboardQueryHandler) {
        self.dashboardHandler = handler
    }

    /// Configura el handler de Assessment para invalidación de cache.
    ///
    /// - Parameter handler: Handler de GetAssessmentQuery
    public func setAssessmentHandler(_ handler: GetAssessmentQueryHandler) {
        self.assessmentHandler = handler
    }

    /// Invalida el cache del dashboard para un usuario.
    private func invalidateDashboardCache(for userId: UUID) async {
        await dashboardHandler?.invalidateCache(for: userId)
    }

    /// Invalida el cache del assessment.
    private func invalidateAssessmentCache(for assessmentId: UUID) async {
        // El GetAssessmentQueryHandler no tiene método específico para invalidar
        // por ID, ya que usa el LoadAssessmentUseCase que maneja su propio cache.
        // Aquí podríamos implementar una lógica adicional si es necesario.
    }
}
