import Foundation

/// Evento de dominio emitido cuando un material educativo es subido exitosamente.
///
/// Este evento contiene toda la información necesaria para que los subscribers
/// reaccionen a la subida de un material, como invalidar caches o registrar
/// auditoría.
///
/// # Datos incluidos
/// - Identificador del material
/// - Título y nombre del archivo
/// - IDs de contexto (subject, unit)
/// - Metadata extensible
///
/// # Subscribers típicos
/// - CacheInvalidationSubscriber: Invalida ListMaterialsQuery cache
/// - AuditLogSubscriber: Registra la operación para auditoría
/// - NotificationSubscriber: Notifica a estudiantes suscritos
///
/// # Ejemplo de uso:
/// ```swift
/// let event = MaterialUploadedEvent(
///     materialId: material.id,
///     title: material.title,
///     fileName: fileURL.lastPathComponent,
///     subjectId: command.subjectId,
///     unitId: command.unitId,
///     uploadedBy: userId
/// )
///
/// await eventBus.publish(event)
/// ```
public struct MaterialUploadedEvent: DomainEvent {
    // MARK: - DomainEvent Properties

    public let eventId: UUID
    public let occurredAt: Date
    public let metadata: [String: String]

    // MARK: - Event-Specific Properties

    /// ID del material subido
    public let materialId: UUID

    /// Título del material
    public let title: String

    /// Nombre del archivo subido
    public let fileName: String

    /// ID de la materia asociada
    public let subjectId: UUID

    /// ID de la unidad académica
    public let unitId: UUID

    /// ID del usuario que subió el material (opcional)
    public let uploadedBy: UUID?

    // MARK: - Initialization

    /// Crea un nuevo evento de material subido.
    ///
    /// - Parameters:
    ///   - materialId: ID del material subido
    ///   - title: Título del material
    ///   - fileName: Nombre del archivo
    ///   - subjectId: ID de la materia
    ///   - unitId: ID de la unidad académica
    ///   - uploadedBy: ID del usuario que subió (opcional)
    ///   - metadata: Metadata adicional (opcional)
    public init(
        materialId: UUID,
        title: String,
        fileName: String,
        subjectId: UUID,
        unitId: UUID,
        uploadedBy: UUID? = nil,
        metadata: [String: String] = [:]
    ) {
        self.eventId = UUID()
        self.occurredAt = Date()
        self.materialId = materialId
        self.title = title
        self.fileName = fileName
        self.subjectId = subjectId
        self.unitId = unitId
        self.uploadedBy = uploadedBy

        // Enriquecer metadata con información del evento
        var enrichedMetadata = metadata
        enrichedMetadata["materialId"] = materialId.uuidString
        enrichedMetadata["subjectId"] = subjectId.uuidString
        enrichedMetadata["unitId"] = unitId.uuidString
        if let uploadedBy = uploadedBy {
            enrichedMetadata["uploadedBy"] = uploadedBy.uuidString
        }
        self.metadata = enrichedMetadata
    }
}
