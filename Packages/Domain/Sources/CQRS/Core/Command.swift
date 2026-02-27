import Foundation

/// Protocolo base para todos los commands en la arquitectura CQRS.
///
/// Un Command representa una solicitud de modificación del estado del sistema.
/// Cada command define su tipo de resultado asociado y puede implementar validación
/// pre-ejecución mediante hooks.
///
/// # Ejemplo de uso:
/// ```swift
/// struct CreateUserCommand: Command {
///     typealias Result = User
///
///     let username: String
///     let email: String
///     var metadata: [String: String]?
///
///     func validate() throws {
///         guard !username.isEmpty else {
///             throw ValidationError.emptyUsername
///         }
///     }
/// }
/// ```
public protocol Command: Sendable {
    /// Tipo de resultado que retorna este command
    associatedtype Result: Sendable

    /// Metadata opcional para contexto adicional (ej: trace ID, user ID, correlation ID)
    var metadata: [String: String]? { get }

    /// Hook de validación que se ejecuta antes de procesar el command.
    /// Lanza errores si la validación falla.
    func validate() throws
}

// Extensión para proporcionar implementaciones por defecto
public extension Command {
    var metadata: [String: String]? { nil }

    func validate() throws {
        // Implementación por defecto: no realiza validación
    }
}
