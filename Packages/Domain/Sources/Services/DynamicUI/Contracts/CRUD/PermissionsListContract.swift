/// Contrato para la lista de permisos.
public struct PermissionsListContract: ScreenContract {
    public let screenKey = "permissions:list"
    public let resource = "permissions"

    private let crud = BaseCrudContract(
        screenKey: "permissions:list",
        resource: "permissions",
        apiPrefix: "iam:",
        basePath: "/api/v1/permissions"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
