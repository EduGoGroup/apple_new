import Foundation

/// Evento de dominio emitido cuando el perfil de usuario es actualizado exitosamente.
///
/// Este evento permite a los subscribers refrescar información de perfil,
/// invalidar caches o sincronizar estado local.
public struct UserProfileUpdatedEvent: DomainEvent {
    // MARK: - DomainEvent Properties

    public let eventId: UUID
    public let occurredAt: Date
    public let metadata: [String: String]

    // MARK: - Event-Specific Properties

    /// ID del usuario actualizado
    public let userId: UUID

    /// Nombre actualizado
    public let firstName: String

    /// Apellido actualizado
    public let lastName: String

    /// Email actualizado
    public let email: String

    // MARK: - Initialization

    /// Crea un nuevo evento de perfil actualizado.
    ///
    /// - Parameters:
    ///   - userId: ID del usuario actualizado
    ///   - firstName: Nombre actualizado
    ///   - lastName: Apellido actualizado
    ///   - email: Email actualizado
    ///   - metadata: Metadata adicional (opcional)
    public init(
        userId: UUID,
        firstName: String,
        lastName: String,
        email: String,
        metadata: [String: String] = [:]
    ) {
        self.eventId = UUID()
        self.occurredAt = Date()
        self.userId = userId
        self.firstName = firstName
        self.lastName = lastName
        self.email = email

        var enrichedMetadata = metadata
        enrichedMetadata["userId"] = userId.uuidString
        enrichedMetadata["email"] = email
        self.metadata = enrichedMetadata
    }
}
