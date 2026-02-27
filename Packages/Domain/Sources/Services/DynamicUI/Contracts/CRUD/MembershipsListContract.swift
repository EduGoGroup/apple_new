/// Contrato para la lista de memberships.
public struct MembershipsListContract: ScreenContract {
    public let screenKey = "memberships:list"
    public let resource = "memberships"

    private let crud = BaseCrudContract(
        screenKey: "memberships:list",
        resource: "memberships",
        apiPrefix: "admin:",
        basePath: "/api/v1/memberships"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
