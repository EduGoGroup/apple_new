/// Contrato para el dashboard de student.
public struct DashboardStudentContract: ScreenContract {
    public let screenKey = "dashboard:student"
    public let resource = "dashboard"

    private let base = BaseDashboardContract(
        screenKey: "dashboard:student",
        apiPrefix: "mobile:"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        base.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        base.permissionFor(event: event)
    }
}
