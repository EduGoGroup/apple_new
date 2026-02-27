/// Contrato para el CRUD individual de membership.
public struct MembershipCrudContract: ScreenContract {
    public let screenKey = "memberships-crud"
    public let resource = "memberships"

    private let crud = BaseCrudContract(
        screenKey: "memberships-crud",
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
