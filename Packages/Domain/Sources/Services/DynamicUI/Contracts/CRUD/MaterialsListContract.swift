/// Contrato para la lista de materiales.
public struct MaterialsListContract: ScreenContract {
    public let screenKey = "materials:list"
    public let resource = "materials"

    private let crud = BaseCrudContract(
        screenKey: "materials:list",
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
