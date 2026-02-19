import Foundation

/// Protocolo para categorización de logs por módulo o funcionalidad.
///
/// Las categorías permiten filtrar y organizar logs según su origen.
/// Cada módulo puede definir sus propias categorías implementando este protocolo.
///
/// ## Ejemplo de uso:
/// ```swift
/// enum AuthCategory: String, LogCategory {
///     case login = "auth.login"
///     case logout = "auth.logout"
///     case tokenRefresh = "auth.token"
/// }
///
/// await logger.info("Usuario autenticado", category: AuthCategory.login)
/// ```
public protocol LogCategory: Sendable {

    /// Identificador único de la categoría.
    var identifier: String { get }

    /// Nombre legible de la categoría para UI/debugging.
    var displayName: String { get }
}

// MARK: - Default Implementation

public extension LogCategory where Self: RawRepresentable, RawValue == String {

    var identifier: String { rawValue }

    var displayName: String {
        let components = identifier.split(separator: ".")
        return components
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

// MARK: - Category Extensions

public extension LogCategory {

    /// Verifica si esta categoría pertenece a un subsistema específico.
    func belongsTo(subsystem: String) -> Bool {
        identifier.contains(subsystem)
    }
}

// MARK: - Dynamic Category

/// Categoría dinámica creada en runtime.
///
/// Útil cuando necesitas crear categorías que no están predefinidas.
///
/// ## Ejemplo:
/// ```swift
/// let category = DynamicLogCategory(
///     identifier: "com.myapp.network.request",
///     displayName: "Network Request"
/// )
/// await logger.info("Request sent", category: category)
/// ```
public struct DynamicLogCategory: LogCategory, Sendable {

    public let identifier: String
    public let displayName: String

    public init(identifier: String, displayName: String? = nil) {
        self.identifier = identifier
        self.displayName = displayName ?? {
            let components = identifier.split(separator: ".")
            return components
                .map { $0.prefix(1).uppercased() + $0.dropFirst() }
                .joined(separator: " ")
        }()
    }
}
