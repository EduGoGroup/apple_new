/// Contrato para el dashboard de guardian.
public struct DashboardGuardianContract: ScreenContract {
    public let screenKey = "dashboard-guardian"
    public let resource = "dashboard"

    private let base = BaseDashboardContract(
        screenKey: "dashboard-guardian",
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
