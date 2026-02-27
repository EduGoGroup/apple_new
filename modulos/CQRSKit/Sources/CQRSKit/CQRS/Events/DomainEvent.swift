import Foundation

/// Protocolo base para todos los eventos de dominio en la arquitectura CQRS.
///
/// Un DomainEvent representa algo que ocurrió en el dominio y que otros
/// componentes pueden estar interesados en conocer. Los eventos son inmutables
/// y contienen toda la información necesaria para que los subscribers procesen
/// el evento sin necesidad de consultar otras fuentes.
///
/// # Características
/// - Inmutables por diseño
/// - Contienen timestamp de ocurrencia
/// - Identificador único para trazabilidad
/// - Metadata extensible para contexto adicional
///
/// # Ejemplo de uso:
/// ```swift
/// struct UserCreatedEvent: DomainEvent {
///     let eventId: UUID
///     let occurredAt: Date
///     let metadata: [String: String]
///     let eventType: String = "UserCreatedEvent"
///
///     let userId: UUID
///     let username: String
///
///     init(userId: UUID, username: String, metadata: [String: String] = [:]) {
///         self.eventId = UUID()
///         self.occurredAt = Date()
///         self.metadata = metadata
///         self.userId = userId
///         self.username = username
///     }
/// }
/// ```
public protocol DomainEvent: Sendable {
    /// Identificador único del evento para trazabilidad y deduplicación
    var eventId: UUID { get }

    /// Timestamp de cuando ocurrió el evento en el dominio
    var occurredAt: Date { get }

    /// Metadata adicional para contexto (ej: correlationId, causationId, userId)
    var metadata: [String: String] { get }

    /// Nombre del tipo de evento para routing y logging
    var eventType: String { get }
}

// MARK: - Extensiones por defecto

public extension DomainEvent {
    /// Nombre del tipo derivado automáticamente del tipo Swift
    var eventType: String {
        String(describing: type(of: self))
    }

    /// Metadata vacía por defecto
    var metadata: [String: String] {
        [:]
    }
}

// MARK: - Type-Erased Wrapper

/// Wrapper type-erased para almacenar eventos heterogéneos.
///
/// `AnyDomainEvent` permite almacenar y manipular eventos de diferentes tipos
/// concretos en colecciones homogéneas, manteniendo la información base
/// del evento original.
///
/// # Ejemplo de uso:
/// ```swift
/// let events: [AnyDomainEvent] = [
///     AnyDomainEvent(UserCreatedEvent(...)),
///     AnyDomainEvent(MaterialUploadedEvent(...))
/// ]
///
/// for event in events {
///     print("Event: \(event.eventType) at \(event.occurredAt)")
///     if let userEvent = event.unwrap(as: UserCreatedEvent.self) {
///         print("User created: \(userEvent.username)")
///     }
/// }
/// ```
public struct AnyDomainEvent: DomainEvent, Sendable {
    public let eventId: UUID
    public let occurredAt: Date
    public let metadata: [String: String]
    public let eventType: String

    /// Almacenamiento interno del evento original
    private let _wrapped: any DomainEvent

    /// Crea un wrapper type-erased de un evento de dominio.
    ///
    /// - Parameter event: El evento a envolver
    public init<E: DomainEvent>(_ event: E) {
        self.eventId = event.eventId
        self.occurredAt = event.occurredAt
        self.metadata = event.metadata
        self.eventType = event.eventType
        self._wrapped = event
    }

    /// Intenta extraer el evento original con su tipo concreto.
    ///
    /// - Parameter type: El tipo esperado del evento
    /// - Returns: El evento con su tipo concreto, o nil si no coincide
    public func unwrap<E: DomainEvent>(as type: E.Type) -> E? {
        _wrapped as? E
    }
}
