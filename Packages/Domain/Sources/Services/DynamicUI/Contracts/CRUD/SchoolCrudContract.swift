/// Contrato para el CRUD individual de escuela.
public struct SchoolCrudContract: ScreenContract {
    public let screenKey = "schools-crud"
    public let resource = "schools"

    private let crud = BaseCrudContract(
        screenKey: "schools-crud",
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
