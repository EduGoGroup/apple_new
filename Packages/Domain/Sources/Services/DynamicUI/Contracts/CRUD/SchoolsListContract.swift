/// Contrato para la lista de escuelas.
public struct SchoolsListContract: ScreenContract {
    public let screenKey = "schools:list"
    public let resource = "schools"

    private let crud = BaseCrudContract(
        screenKey: "schools:list",
        resource: "schools",
        apiPrefix: "admin:",
        basePath: "/api/v1/schools"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
