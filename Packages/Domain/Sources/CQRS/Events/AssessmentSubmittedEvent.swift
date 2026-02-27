import Foundation

/// Evento de dominio emitido cuando una evaluación es enviada exitosamente.
///
/// Este evento contiene toda la información necesaria para que los subscribers
/// reaccionen al envío de una evaluación, como actualizar dashboards,
/// invalidar caches o enviar notificaciones.
///
/// # Datos incluidos
/// - Identificadores del intento, assessment y usuario
/// - Resultado de la evaluación (score, passed, percentage)
/// - Tiempo empleado
///
/// # Subscribers típicos
/// - CacheInvalidationSubscriber: Invalida Dashboard y Assessment caches
/// - AuditLogSubscriber: Registra el intento para auditoría
/// - NotificationSubscriber: Notifica al profesor si es necesario
/// - AnalyticsSubscriber: Registra métricas de aprendizaje
///
/// # Ejemplo de uso:
/// ```swift
/// let event = AssessmentSubmittedEvent(
///     attemptId: result.attemptId,
///     assessmentId: result.assessmentId,
///     userId: result.userId,
///     score: result.score,
///     maxScore: result.maxScore,
///     passed: result.passed,
///     percentage: result.percentage,
///     timeSpentSeconds: result.timeSpentSeconds
/// )
///
/// await eventBus.publish(event)
/// ```
public struct AssessmentSubmittedEvent: DomainEvent {
    // MARK: - DomainEvent Properties

    public let eventId: UUID
    public let occurredAt: Date
    public let metadata: [String: String]

    // MARK: - Event-Specific Properties

    /// ID del intento de evaluación
    public let attemptId: UUID

    /// ID de la evaluación
    public let assessmentId: UUID

    /// ID del usuario que envió la evaluación
    public let userId: UUID

    /// Puntaje obtenido
    public let score: Int

    /// Puntaje máximo posible
    public let maxScore: Int

    /// Indica si aprobó la evaluación
    public let passed: Bool

    /// Porcentaje de aciertos
    public let percentage: Double

    /// Tiempo empleado en segundos
    public let timeSpentSeconds: Int

    // MARK: - Initialization

    /// Crea un nuevo evento de evaluación enviada.
    ///
    /// - Parameters:
    ///   - attemptId: ID del intento
    ///   - assessmentId: ID de la evaluación
    ///   - userId: ID del usuario
    ///   - score: Puntaje obtenido
    ///   - maxScore: Puntaje máximo
    ///   - passed: Si aprobó
    ///   - percentage: Porcentaje de aciertos
    ///   - timeSpentSeconds: Tiempo empleado
    ///   - metadata: Metadata adicional (opcional)
    public init(
        attemptId: UUID,
        assessmentId: UUID,
        userId: UUID,
        score: Int,
        maxScore: Int,
        passed: Bool,
        percentage: Double,
        timeSpentSeconds: Int,
        metadata: [String: String] = [:]
    ) {
        self.eventId = UUID()
        self.occurredAt = Date()
        self.attemptId = attemptId
        self.assessmentId = assessmentId
        self.userId = userId
        self.score = score
        self.maxScore = maxScore
        self.passed = passed
        self.percentage = percentage
        self.timeSpentSeconds = timeSpentSeconds

        // Enriquecer metadata con información del resultado
        var enrichedMetadata = metadata
        enrichedMetadata["attemptId"] = attemptId.uuidString
        enrichedMetadata["assessmentId"] = assessmentId.uuidString
        enrichedMetadata["userId"] = userId.uuidString
        enrichedMetadata["score"] = "\(score)/\(maxScore)"
        enrichedMetadata["passed"] = passed ? "true" : "false"
        enrichedMetadata["percentage"] = String(format: "%.1f%%", percentage)
        self.metadata = enrichedMetadata
    }
}
