import Foundation

/// Evento de dominio emitido cuando un usuario se autentica exitosamente.
///
/// Este evento contiene información del usuario autenticado para que
/// los subscribers puedan reaccionar al login, como invalidar caches
/// de sesiones anteriores, registrar auditoría, o actualizar métricas.
///
/// # Datos incluidos
/// - Identificador del usuario
/// - Email del usuario
/// - Información de la sesión (device, IP, etc. en metadata)
///
/// # Subscribers típicos
/// - CacheInvalidationSubscriber: Invalida UserContext cache
/// - AuditLogSubscriber: Registra el login para auditoría de seguridad
/// - SessionSubscriber: Actualiza información de sesión activa
/// - AnalyticsSubscriber: Registra métricas de uso
///
/// # Ejemplo de uso:
/// ```swift
/// let event = LoginSuccessEvent(
///     userId: user.id,
///     email: user.email,
///     metadata: [
///         "deviceType": "iOS",
///         "appVersion": "1.0.0",
///         "correlationId": correlationId
///     ]
/// )
///
/// await eventBus.publish(event)
/// ```
public struct LoginSuccessEvent: DomainEvent {
    // MARK: - DomainEvent Properties

    public let eventId: UUID
    public let occurredAt: Date
    public let metadata: [String: String]

    // MARK: - Event-Specific Properties

    /// ID del usuario autenticado
    public let userId: UUID

    /// Email del usuario (para logging y debugging)
    public let email: String

    // MARK: - Initialization

    /// Crea un nuevo evento de login exitoso.
    ///
    /// - Parameters:
    ///   - userId: ID del usuario autenticado
    ///   - email: Email del usuario
    ///   - metadata: Metadata adicional (deviceType, appVersion, IP, etc.)
    public init(
        userId: UUID,
        email: String,
        metadata: [String: String] = [:]
    ) {
        self.eventId = UUID()
        self.occurredAt = Date()
        self.userId = userId
        self.email = email

        // Enriquecer metadata con información del login
        var enrichedMetadata = metadata
        enrichedMetadata["userId"] = userId.uuidString
        enrichedMetadata["email"] = email
        enrichedMetadata["loginAt"] = ISO8601DateFormatter().string(from: Date())
        self.metadata = enrichedMetadata
    }
}
