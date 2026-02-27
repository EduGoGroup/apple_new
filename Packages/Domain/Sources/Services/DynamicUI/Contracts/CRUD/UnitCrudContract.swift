/// Contrato para el CRUD individual de unidad academica.
public struct UnitCrudContract: ScreenContract {
    public let screenKey = "units:crud"
    public let resource = "units"

    private let crud = BaseCrudContract(
        screenKey: "units:crud",
        resource: "units",
        apiPrefix: "admin:",
        basePath: "/api/v1/units"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
