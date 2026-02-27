/// Contrato para relaciones de guardian.
public struct GuardianContract: ScreenContract {
    public let screenKey = "guardian:list"
    public let resource = "guardian-relations"

    private let crud = BaseCrudContract(
        screenKey: "guardian:list",
        resource: "guardian-relations",
        apiPrefix: "admin:",
        basePath: "/api/v1/guardian-relations"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
