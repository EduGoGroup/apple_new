import Foundation

// MARK: - ContextSwitchedEvent

/// Evento de dominio emitido cuando un usuario cambia de contexto escolar.
///
/// Este evento captura el cambio de membership/escuela activa del usuario,
/// permitiendo que los suscriptores (cache, UI, analytics) reaccionen
/// al cambio de contexto.
///
/// ## Información Capturada
/// - Usuario que realizó el cambio
/// - Membership y escuela anterior
/// - Membership y escuela nueva
/// - Metadata para tracing
///
/// ## Suscriptores Típicos
/// - `CacheInvalidationSubscriber`: Invalida UserContextReadModel y DashboardReadModel
/// - `AnalyticsSubscriber`: Registra el cambio de contexto
/// - `NotificationSubscriber`: Actualiza notificaciones pendientes
///
/// ## Ejemplo de Uso
/// ```swift
/// let event = ContextSwitchedEvent(
///     userId: currentUserId,
///     previousMembershipId: oldMembership.id,
///     newMembershipId: newMembership.id,
///     previousSchoolId: oldSchool.id,
///     newSchoolId: newSchool.id,
///     newSchoolName: newSchool.name
/// )
///
/// await eventBus.publish(event)
/// ```
public struct ContextSwitchedEvent: DomainEvent {

    // MARK: - DomainEvent Properties

    /// Identificador único del evento
    public let eventId: UUID

    /// Timestamp de cuando ocurrió el evento
    public let occurredAt: Date

    /// Metadata adicional para tracing y debugging
    public let metadata: [String: String]

    // MARK: - Event-Specific Properties

    /// ID del usuario que cambió de contexto
    public let userId: UUID

    /// ID del membership anterior (antes del cambio)
    public let previousMembershipId: UUID

    /// ID del nuevo membership activo
    public let newMembershipId: UUID

    /// ID de la escuela anterior
    public let previousSchoolId: UUID

    /// ID de la nueva escuela
    public let newSchoolId: UUID

    /// Nombre de la nueva escuela (para logging/display)
    public let newSchoolName: String

    /// Nombre de la nueva unidad académica
    public let newUnitName: String

    /// Si el cambio fue al mismo contexto (noop)
    public let wasSameContext: Bool

    // MARK: - DomainEvent Computed Properties

    /// Tipo de evento para routing
    public var eventType: String {
        "context.switched"
    }

    // MARK: - Initialization

    /// Crea un nuevo evento de cambio de contexto.
    ///
    /// - Parameters:
    ///   - eventId: ID único del evento (default: generado)
    ///   - occurredAt: Timestamp del evento (default: ahora)
    ///   - userId: ID del usuario que cambió de contexto
    ///   - previousMembershipId: ID del membership anterior
    ///   - newMembershipId: ID del nuevo membership
    ///   - previousSchoolId: ID de la escuela anterior
    ///   - newSchoolId: ID de la nueva escuela
    ///   - newSchoolName: Nombre de la nueva escuela
    ///   - newUnitName: Nombre de la nueva unidad
    ///   - wasSameContext: Si fue cambio al mismo contexto
    ///   - metadata: Metadata adicional
    public init(
        eventId: UUID = UUID(),
        occurredAt: Date = Date(),
        userId: UUID,
        previousMembershipId: UUID,
        newMembershipId: UUID,
        previousSchoolId: UUID,
        newSchoolId: UUID,
        newSchoolName: String,
        newUnitName: String,
        wasSameContext: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.eventId = eventId
        self.occurredAt = occurredAt
        self.userId = userId
        self.previousMembershipId = previousMembershipId
        self.newMembershipId = newMembershipId
        self.previousSchoolId = previousSchoolId
        self.newSchoolId = newSchoolId
        self.newSchoolName = newSchoolName
        self.newUnitName = newUnitName
        self.wasSameContext = wasSameContext

        // Enriquecer metadata con información del evento
        var enrichedMetadata = metadata
        enrichedMetadata["userId"] = userId.uuidString
        enrichedMetadata["previousMembershipId"] = previousMembershipId.uuidString
        enrichedMetadata["newMembershipId"] = newMembershipId.uuidString
        enrichedMetadata["previousSchoolId"] = previousSchoolId.uuidString
        enrichedMetadata["newSchoolId"] = newSchoolId.uuidString
        enrichedMetadata["wasSameContext"] = wasSameContext ? "true" : "false"
        self.metadata = enrichedMetadata
    }
}

// MARK: - Equatable

extension ContextSwitchedEvent: Equatable {
    public static func == (lhs: ContextSwitchedEvent, rhs: ContextSwitchedEvent) -> Bool {
        lhs.eventId == rhs.eventId
    }
}

// MARK: - CustomStringConvertible

extension ContextSwitchedEvent: CustomStringConvertible {
    public var description: String {
        if wasSameContext {
            return "ContextSwitchedEvent(userId: \(userId), sameContext: \(newSchoolName))"
        }
        return "ContextSwitchedEvent(userId: \(userId), school: \(newSchoolName), unit: \(newUnitName))"
    }
}
