/// Contrato para la lista de usuarios.
public struct UsersListContract: ScreenContract {
    public let screenKey = "users:list"
    public let resource = "users"

    private let crud = BaseCrudContract(
        screenKey: "users:list",
        resource: "users",
        apiPrefix: "admin:",
        basePath: "/api/v1/users"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
