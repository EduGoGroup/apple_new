/// Contrato para la lista de roles.
public struct RolesListContract: ScreenContract {
    public let screenKey = "roles:list"
    public let resource = "roles"

    private let crud = BaseCrudContract(
        screenKey: "roles:list",
        resource: "roles",
        apiPrefix: "iam:",
        basePath: "/api/v1/roles"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
