/// Contrato base para pantallas de dashboard.
///
/// Provee endpoint de stats y permisos genericos.
/// Cada dashboard por rol extiende este contrato.
public struct BaseDashboardContract: ScreenContract {
    public let screenKey: String
    public let resource = "dashboard"

    /// Prefijo de API para el endpoint de stats.
    public let apiPrefix: String

    /// Endpoint de stats del dashboard.
    public let statsEndpoint: String

    public init(
        screenKey: String,
        apiPrefix: String,
        statsEndpoint: String = "/api/v1/stats/global"
    ) {
        self.screenKey = screenKey
        self.apiPrefix = apiPrefix
        self.statsEndpoint = statsEndpoint
    }

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        switch event {
        case .loadData, .refresh:
            return "\(apiPrefix)\(statsEndpoint)"
        default:
            return nil
        }
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        switch event {
        case .loadData, .refresh:
            return "dashboard:read"
        default:
            return nil
        }
    }
}
