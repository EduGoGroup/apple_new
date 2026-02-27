/// Contrato para el CRUD individual de materia.
public struct SubjectCrudContract: ScreenContract {
    public let screenKey = "subjects-crud"
    public let resource = "subjects"

    private let crud = BaseCrudContract(
        screenKey: "subjects-crud",
        resource: "subjects",
        apiPrefix: "admin:",
        basePath: "/api/v1/subjects"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        crud.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        crud.permissionFor(event: event)
    }
}
