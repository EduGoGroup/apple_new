/// Contrato para la pantalla de configuracion.
///
/// Maneja eventos custom: cambio de tema, logout, cambio de idioma.
public struct SettingsContract: ScreenContract {
    public let screenKey = "settings"
    public let resource = "settings"

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        nil
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        nil
    }

    public func customEventHandler(for eventId: String) -> (@Sendable (EventContext) async -> EventResult)? {
        switch eventId {
        case "change-theme":
            return { _ in .success(message: "Theme changed") }
        case "logout":
            return { _ in .logout }
        case "change-language":
            return { _ in .success(message: "Language changed") }
        default:
            return nil
        }
    }
}
