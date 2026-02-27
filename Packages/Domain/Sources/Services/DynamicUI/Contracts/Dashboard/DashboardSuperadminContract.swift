/// Contrato para el dashboard de superadmin.
public struct DashboardSuperadminContract: ScreenContract {
    public let screenKey = "dashboard:superadmin"
    public let resource = "dashboard"

    private let base = BaseDashboardContract(
        screenKey: "dashboard:superadmin",
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
