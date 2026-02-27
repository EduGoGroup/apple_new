import EduDynamicUI

/// Protocolo que define el contrato de negocio para una pantalla server-driven.
///
/// Cada pantalla tiene un contrato que determina:
/// - Que endpoints usa para cada evento
/// - Que permisos requiere
/// - Configuracion de datos opcional
/// - Handlers personalizados para eventos especificos
public protocol ScreenContract: Sendable {
    /// Clave unica de la pantalla (e.g. "schools:list").
    var screenKey: String { get }

    /// Recurso que gestiona (e.g. "schools").
    var resource: String { get }

    /// Resuelve el endpoint para un evento dado.
    func endpointFor(event: ScreenEvent, context: EventContext) -> String?

    /// Resuelve el permiso requerido para un evento.
    func permissionFor(event: ScreenEvent) -> String?

    /// Configuracion de datos de la pantalla (paginacion, params por defecto).
    func dataConfig() -> DataConfig?

    /// Handler personalizado para un evento especifico por ID.
    func customEventHandler(for eventId: String) -> (@Sendable (EventContext) async -> EventResult)?
}

// MARK: - Default Implementations

extension ScreenContract {
    public func dataConfig() -> DataConfig? { nil }

    public func customEventHandler(for eventId: String) -> (@Sendable (EventContext) async -> EventResult)? { nil }
}
