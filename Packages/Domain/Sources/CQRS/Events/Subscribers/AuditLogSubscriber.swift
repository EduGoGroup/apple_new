import Foundation
import OSLog

/// Protocolo para servicios de auditoría que persisten registros.
///
/// Implementa este protocolo para conectar el AuditLogSubscriber
/// a tu sistema de auditoría (base de datos, servicio externo, etc.)
public protocol AuditLogService: Sendable {
    /// Registra una entrada de auditoría.
    ///
    /// - Parameter entry: La entrada a registrar
    func log(_ entry: AuditEntry) async
}

/// Entrada de auditoría que representa una operación registrada.
public struct AuditEntry: Sendable {
    /// Identificador único de la entrada
    public let id: UUID

    /// Tipo de evento que generó esta entrada
    public let eventType: String

    /// Identificador del evento original
    public let eventId: UUID

    /// Timestamp de cuando ocurrió el evento
    public let occurredAt: Date

    /// Timestamp de cuando se registró la auditoría
    public let loggedAt: Date

    /// ID del usuario asociado (si aplica)
    public let userId: UUID?

    /// ID del recurso afectado (material, assessment, etc.)
    public let resourceId: UUID?

    /// Tipo de recurso afectado
    public let resourceType: String?

    /// Acción realizada
    public let action: AuditAction

    /// Resultado de la operación
    public let outcome: AuditOutcome

    /// Detalles adicionales en formato clave-valor
    public let details: [String: String]

    /// Crea una nueva entrada de auditoría.
    public init(
        eventType: String,
        eventId: UUID,
        occurredAt: Date,
        userId: UUID? = nil,
        resourceId: UUID? = nil,
        resourceType: String? = nil,
        action: AuditAction,
        outcome: AuditOutcome = .success,
        details: [String: String] = [:]
    ) {
        self.id = UUID()
        self.eventType = eventType
        self.eventId = eventId
        self.occurredAt = occurredAt
        self.loggedAt = Date()
        self.userId = userId
        self.resourceId = resourceId
        self.resourceType = resourceType
        self.action = action
        self.outcome = outcome
        self.details = details
    }
}

/// Acciones auditables en el sistema.
public enum AuditAction: String, Sendable {
    case login = "LOGIN"
    case logout = "LOGOUT"
    case upload = "UPLOAD"
    case download = "DOWNLOAD"
    case create = "CREATE"
    case update = "UPDATE"
    case delete = "DELETE"
    case submit = "SUBMIT"
    case view = "VIEW"
    case share = "SHARE"
}

/// Resultado de una operación auditada.
public enum AuditOutcome: String, Sendable {
    case success = "SUCCESS"
    case failure = "FAILURE"
    case partial = "PARTIAL"
}

/// Subscriber que registra eventos de dominio para auditoría.
///
/// AuditLogSubscriber escucha eventos importantes del sistema y genera
/// registros de auditoría para cumplimiento, seguridad y análisis.
///
/// # Eventos auditados
/// - `MaterialUploadedEvent`: Registro de subida de materiales
/// - `AssessmentSubmittedEvent`: Registro de envío de evaluaciones
/// - `LoginSuccessEvent`: Registro de autenticaciones
///
/// # Características
/// - Non-blocking: No afecta el rendimiento de las operaciones principales
/// - Enriquecimiento automático de metadata
/// - Soporte para múltiples backends de auditoría
/// - Logging estructurado con OSLog como fallback
///
/// # Ejemplo de uso:
/// ```swift
/// // Con servicio de auditoría personalizado
/// let subscriber = AuditLogSubscriber(auditService: myAuditService)
/// await subscriber.registerWithEventBus(eventBus)
///
/// // Solo con logging (para desarrollo)
/// let devSubscriber = AuditLogSubscriber()
/// await devSubscriber.registerWithEventBus(eventBus)
/// ```
public actor AuditLogSubscriber {

    // MARK: - Dependencies

    /// Servicio de auditoría para persistir registros
    private let auditService: AuditLogService?

    /// Logger para debugging y fallback
    private let logger: Logger

    /// Indica si el logging está habilitado
    private let loggingEnabled: Bool

    /// IDs de suscripciones activas
    private var subscriptionIds: [UUID] = []

    // MARK: - Initialization

    /// Crea un nuevo subscriber de auditoría.
    ///
    /// - Parameters:
    ///   - auditService: Servicio para persistir auditorías (opcional)
    ///   - loggingEnabled: Habilita logging a OSLog
    public init(
        auditService: AuditLogService? = nil,
        loggingEnabled: Bool = true
    ) {
        self.auditService = auditService
        self.loggingEnabled = loggingEnabled
        self.logger = Logger(subsystem: "com.edugo.cqrs", category: "AuditLog")
    }

    // MARK: - Registration

    /// Registra este subscriber con un EventBus para todos los eventos auditables.
    ///
    /// - Parameter eventBus: El EventBus donde registrarse
    public func registerWithEventBus(_ eventBus: EventBus) async {
        // Limpiar suscripciones anteriores
        await unregisterFromEventBus(eventBus)

        // Registrar para MaterialUploadedEvent
        let materialSubId = await eventBus.subscribe(
            to: MaterialUploadedEvent.self
        ) { [weak self] event in
            await self?.handleMaterialUploaded(event)
        }
        subscriptionIds.append(materialSubId)

        // Registrar para AssessmentSubmittedEvent
        let assessmentSubId = await eventBus.subscribe(
            to: AssessmentSubmittedEvent.self
        ) { [weak self] event in
            await self?.handleAssessmentSubmitted(event)
        }
        subscriptionIds.append(assessmentSubId)

        // Registrar para LoginSuccessEvent
        let loginSubId = await eventBus.subscribe(
            to: LoginSuccessEvent.self
        ) { [weak self] event in
            await self?.handleLoginSuccess(event)
        }
        subscriptionIds.append(loginSubId)

        if loggingEnabled {
            logger.info("AuditLogSubscriber registered for 3 event types")
        }
    }

    /// Cancela todas las suscripciones de este subscriber.
    ///
    /// - Parameter eventBus: El EventBus de donde cancelar suscripciones
    public func unregisterFromEventBus(_ eventBus: EventBus) async {
        for subscriptionId in subscriptionIds {
            await eventBus.unsubscribe(subscriptionId)
        }
        subscriptionIds.removeAll()

        if loggingEnabled {
            logger.info("AuditLogSubscriber unregistered")
        }
    }

    // MARK: - Event Handlers

    /// Maneja el evento de material subido para auditoría.
    private func handleMaterialUploaded(_ event: MaterialUploadedEvent) async {
        let entry = AuditEntry(
            eventType: event.eventType,
            eventId: event.eventId,
            occurredAt: event.occurredAt,
            userId: event.uploadedBy,
            resourceId: event.materialId,
            resourceType: "Material",
            action: .upload,
            outcome: .success,
            details: [
                "title": event.title,
                "fileName": event.fileName,
                "subjectId": event.subjectId.uuidString,
                "unitId": event.unitId.uuidString
            ]
        )

        await logEntry(entry)
    }

    /// Maneja el evento de evaluación enviada para auditoría.
    private func handleAssessmentSubmitted(_ event: AssessmentSubmittedEvent) async {
        let entry = AuditEntry(
            eventType: event.eventType,
            eventId: event.eventId,
            occurredAt: event.occurredAt,
            userId: event.userId,
            resourceId: event.assessmentId,
            resourceType: "Assessment",
            action: .submit,
            outcome: event.passed ? .success : .partial,
            details: [
                "attemptId": event.attemptId.uuidString,
                "score": "\(event.score)/\(event.maxScore)",
                "percentage": String(format: "%.1f%%", event.percentage),
                "passed": event.passed ? "true" : "false",
                "timeSpentSeconds": "\(event.timeSpentSeconds)"
            ]
        )

        await logEntry(entry)
    }

    /// Maneja el evento de login exitoso para auditoría.
    private func handleLoginSuccess(_ event: LoginSuccessEvent) async {
        var details = event.metadata
        details["email"] = event.email

        let entry = AuditEntry(
            eventType: event.eventType,
            eventId: event.eventId,
            occurredAt: event.occurredAt,
            userId: event.userId,
            resourceId: nil,
            resourceType: "Session",
            action: .login,
            outcome: .success,
            details: details
        )

        await logEntry(entry)
    }

    // MARK: - Logging

    /// Registra una entrada de auditoría.
    private func logEntry(_ entry: AuditEntry) async {
        // Enviar al servicio de auditoría si está disponible
        if let auditService = auditService {
            await auditService.log(entry)
        }

        // Logging estructurado con OSLog
        if loggingEnabled {
            let userInfo = entry.userId.map { "user=\($0)" } ?? "user=system"
            let resourceInfo = entry.resourceId.map { "resource=\($0)" } ?? ""

            logger.info("""
                AUDIT: \(entry.action.rawValue) \(entry.resourceType ?? "unknown", privacy: .public) \
                [\(entry.outcome.rawValue)] \(userInfo) \(resourceInfo) \
                eventId=\(entry.eventId)
                """)
        }
    }
}

// MARK: - Default OSLog Audit Service

/// Implementación por defecto de AuditLogService que usa OSLog.
///
/// Útil para desarrollo y debugging. Para producción, se recomienda
/// implementar un servicio que persista los registros.
public actor OSLogAuditService: AuditLogService {
    private let logger: Logger

    public init(subsystem: String = "com.edugo.cqrs", category: String = "Audit") {
        self.logger = Logger(subsystem: subsystem, category: category)
    }

    public func log(_ entry: AuditEntry) async {
        logger.log(level: .info, """
            ═══════════════════════════════════════════
            AUDIT ENTRY
            ───────────────────────────────────────────
            ID: \(entry.id)
            Event Type: \(entry.eventType)
            Event ID: \(entry.eventId)
            Action: \(entry.action.rawValue)
            Outcome: \(entry.outcome.rawValue)
            User: \(entry.userId?.uuidString ?? "N/A")
            Resource: \(entry.resourceType ?? "N/A") (\(entry.resourceId?.uuidString ?? "N/A"))
            Occurred: \(entry.occurredAt)
            Logged: \(entry.loggedAt)
            Details: \(entry.details)
            ═══════════════════════════════════════════
            """)
    }
}
