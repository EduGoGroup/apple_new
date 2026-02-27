/// Contrato para la lista de unidades academicas.
public struct UnitsListContract: ScreenContract {
    public let screenKey = "units:list"
    public let resource = "units"

    private let crud = BaseCrudContract(
        screenKey: "units:list",
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
