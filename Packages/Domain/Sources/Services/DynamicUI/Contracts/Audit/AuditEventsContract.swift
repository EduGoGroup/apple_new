/// Contrato para la lista de eventos de auditoría.
///
/// Usa el patrón BaseCrudContract con endpoints del servicio IAM.
/// Solo permite operaciones de lectura (audit:read).
public struct AuditEventsContract: ScreenContract {
    public let screenKey = "audit-events"
    public let resource = "audit"

    private let crud = BaseCrudContract(
        screenKey: "audit-events",
        resource: "audit",
        apiPrefix: "iam:",
        basePath: "/api/v1/audit/events"
    )

    public init() {}

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        switch event {
        case .loadData, .refresh, .loadMore, .search:
            return crud.endpointFor(event: event, context: context)
        case .selectItem:
            guard let id = context.selectedItem?["id"]?.stringValue else { return nil }
            return "iam:/api/v1/audit/events/\(id)"
        default:
            return nil
        }
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        switch event {
        case .loadData, .refresh, .loadMore, .search, .selectItem:
            return "audit:read"
        default:
            return nil
        }
    }
}
