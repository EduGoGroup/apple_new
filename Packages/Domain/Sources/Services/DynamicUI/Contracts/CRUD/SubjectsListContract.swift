import EduDynamicUI

/// Contrato para la lista de materias.
public struct SubjectsListContract: ScreenContract {
    public let screenKey = "subjects-list"
    public let resource = "subjects"

    private let crud = BaseCrudContract(
        screenKey: "subjects-list",
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

    public func dataConfig() -> DataConfig? {
        DataConfig(
            pagination: PaginationConfig(pageSize: 20, limitParam: "limit", offsetParam: "offset"),
            fieldMapping: ["name": "title", "description": "subtitle", "is_active": "status"],
            defaultValues: ["file_type_icon": "description"]
        )
    }
}
