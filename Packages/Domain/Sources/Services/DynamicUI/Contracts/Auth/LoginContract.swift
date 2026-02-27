/// Contrato para la pantalla de login.
///
/// No requiere permisos. El evento custom "submit-login"
/// delega a AuthService para autenticacion.
public struct LoginContract: ScreenContract {
    public let screenKey = "login"
    public let resource = "auth"

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        nil
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        nil
    }

    public func customEventHandler(for eventId: String) -> (@Sendable (EventContext) async -> EventResult)? {
        switch eventId {
        case "submit-login":
            return { context in
                let email = context.fieldValues["email"] ?? ""
                let password = context.fieldValues["password"] ?? ""
                guard !email.isEmpty, !password.isEmpty else {
                    return .error(message: "Email and password are required")
                }
                return .submitTo(
                    endpoint: "iam:/api/v1/auth/login",
                    method: "POST",
                    fieldValues: [
                        "email": .string(email),
                        "password": .string(password)
                    ]
                )
            }
        default:
            return nil
        }
    }
}
