import Foundation

/// Evento de dominio emitido cuando un material es asignado a una unidad académica.
///
/// Este evento contiene toda la información necesaria para que los subscribers
/// reaccionen a la asignación, como invalidar caches de materiales para la unidad
/// o enviar notificaciones adicionales.
///
/// # Datos incluidos
/// - Identificador de la asignación
/// - Material y unidad involucrados
/// - Usuario que realizó la asignación
/// - Configuración de la asignación (visibilidad, fecha límite)
///
/// # Subscribers típicos
/// - CacheInvalidationSubscriber: Invalida MaterialListReadModel para la unidad
/// - NotificationSubscriber: Envía notificaciones adicionales si es necesario
/// - AuditLogSubscriber: Registra la asignación para auditoría
///
/// # Ejemplo de uso:
/// ```swift
/// let event = MaterialAssignedEvent(
///     assignmentId: assignment.id,
///     materialId: material.id,
///     materialTitle: material.title,
///     unitId: unit.id,
///     unitName: unit.name,
///     assignedBy: teacherId,
///     dueDate: nextWeek,
///     isVisible: true,
///     wasAlreadyAssigned: false
/// )
///
/// await eventBus.publish(event)
/// ```
public struct MaterialAssignedEvent: DomainEvent {
    // MARK: - DomainEvent Properties

    public let eventId: UUID
    public let occurredAt: Date
    public let metadata: [String: String]

    // MARK: - Event-Specific Properties

    /// ID de la asignación creada
    public let assignmentId: UUID

    /// ID del material asignado
    public let materialId: UUID

    /// Título del material (para logging)
    public let materialTitle: String

    /// ID de la unidad académica
    public let unitId: UUID

    /// Nombre de la unidad (para logging)
    public let unitName: String

    /// ID del usuario que realizó la asignación
    public let assignedBy: UUID

    /// Fecha límite de la asignación (opcional)
    public let dueDate: Date?

    /// Si el material es visible para estudiantes
    public let isVisible: Bool

    /// Si ya estaba asignado (operación idempotente)
    public let wasAlreadyAssigned: Bool

    // MARK: - Initialization

    /// Crea un nuevo evento de material asignado.
    ///
    /// - Parameters:
    ///   - assignmentId: ID de la asignación
    ///   - materialId: ID del material
    ///   - materialTitle: Título del material
    ///   - unitId: ID de la unidad
    ///   - unitName: Nombre de la unidad
    ///   - assignedBy: ID del usuario que asigna
    ///   - dueDate: Fecha límite opcional
    ///   - isVisible: Si es visible
    ///   - wasAlreadyAssigned: Si ya estaba asignado
    ///   - metadata: Metadata adicional
    public init(
        assignmentId: UUID,
        materialId: UUID,
        materialTitle: String,
        unitId: UUID,
        unitName: String,
        assignedBy: UUID,
        dueDate: Date? = nil,
        isVisible: Bool = true,
        wasAlreadyAssigned: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.eventId = UUID()
        self.occurredAt = Date()
        self.assignmentId = assignmentId
        self.materialId = materialId
        self.materialTitle = materialTitle
        self.unitId = unitId
        self.unitName = unitName
        self.assignedBy = assignedBy
        self.dueDate = dueDate
        self.isVisible = isVisible
        self.wasAlreadyAssigned = wasAlreadyAssigned

        // Enriquecer metadata
        var enrichedMetadata = metadata
        enrichedMetadata["assignmentId"] = assignmentId.uuidString
        enrichedMetadata["materialId"] = materialId.uuidString
        enrichedMetadata["unitId"] = unitId.uuidString
        enrichedMetadata["assignedBy"] = assignedBy.uuidString
        enrichedMetadata["wasAlreadyAssigned"] = wasAlreadyAssigned ? "true" : "false"
        if let dueDate = dueDate {
            enrichedMetadata["dueDate"] = ISO8601DateFormatter().string(from: dueDate)
        }
        self.metadata = enrichedMetadata
    }
}
