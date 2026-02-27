/// Contrato para el dashboard de school admin.
public struct DashboardSchoolAdminContract: ScreenContract {
    public let screenKey = "dashboard:school_admin"
    public let resource = "dashboard"

    private let base = BaseDashboardContract(
        screenKey: "dashboard:school_admin",
        apiPrefix: "admin:"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        base.endpointFor(event: event, context: context)
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        base.permissionFor(event: event)
    }
}
