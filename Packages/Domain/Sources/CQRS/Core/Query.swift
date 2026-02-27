import Foundation

/// Protocolo base para todas las queries en la arquitectura CQRS.
///
/// Una Query representa una solicitud de lectura de datos que NO modifica el estado del sistema.
/// Cada query define su tipo de resultado asociado y puede incluir metadata opcional.
///
/// # Ejemplo de uso:
/// ```swift
/// struct GetUserQuery: Query {
///     typealias Result = User
///
///     let userId: String
///     var metadata: [String: Any]?
/// }
/// ```
public protocol Query: Sendable {
    /// Tipo de resultado que retorna esta query
    associatedtype Result: Sendable

    /// Metadata opcional para contexto adicional (ej: trace ID, user ID, etc.)
    var metadata: [String: String]? { get }
}

// Extensión para proporcionar implementación por defecto de metadata
public extension Query {
    var metadata: [String: String]? { nil }
}
