/// Contrato para el dashboard de teacher.
public struct DashboardTeacherContract: ScreenContract {
    public let screenKey = "dashboard:teacher"
    public let resource = "dashboard"

    private let base = BaseDashboardContract(
        screenKey: "dashboard:teacher",
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
