/// Contrato para el CRUD individual de material.
public struct MaterialCrudContract: ScreenContract {
    public let screenKey = "materials-crud"
    public let resource = "materials"

    private let crud = BaseCrudContract(
        screenKey: "materials-crud",
        resource: "materials",
        apiPrefix: "mobile:",
        basePath: "/api/v1/materials"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
