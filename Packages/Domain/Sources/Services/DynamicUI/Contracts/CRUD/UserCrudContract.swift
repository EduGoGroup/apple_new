/// Contrato para el CRUD individual de usuario.
public struct UserCrudContract: ScreenContract {
    public let screenKey = "users:crud"
    public let resource = "users"

    private let crud = BaseCrudContract(
        screenKey: "users:crud",
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
