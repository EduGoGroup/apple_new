import EduCore

/// Contrato base que implementa el patron CRUD generico.
///
/// Genera endpoints y permisos estandar para operaciones
/// de lectura, creacion, actualizacion y eliminacion.
public struct BaseCrudContract: ScreenContract {
    public let screenKey: String
    public let resource: String

    /// Prefijo de API (e.g. "admin:", "mobile:", "iam:").
    public let apiPrefix: String

    /// Ruta base del recurso (e.g. "/api/v1/schools").
    public let basePath: String

    public init(
        screenKey: String,
        resource: String,
        apiPrefix: String,
        basePath: String
    ) {
        self.screenKey = screenKey
        self.resource = resource
        self.apiPrefix = apiPrefix
        self.basePath = basePath
    }

    public func endpointFor(event: ScreenEvent, context: EventContext) -> String? {
        switch event {
        case .loadData, .refresh:
            return "\(apiPrefix)\(basePath)"
        case .loadMore:
            return "\(apiPrefix)\(basePath)"
        case .search:
            let query = context.searchQuery ?? ""
            let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "\(apiPrefix)\(basePath)?search=\(encoded)"
        case .saveNew:
            return "\(apiPrefix)\(basePath)"
        case .saveExisting:
            guard let id = context.selectedItem?["id"]?.stringValue else { return nil }
            return "\(apiPrefix)\(basePath)/\(id)"
        case .delete:
            guard let id = context.selectedItem?["id"]?.stringValue else { return nil }
            return "\(apiPrefix)\(basePath)/\(id)"
        case .selectItem:
            return nil
        case .create:
            return nil
        }
    }

    public func permissionFor(event: ScreenEvent) -> String? {
        switch event {
        case .loadData, .refresh, .loadMore, .search, .selectItem:
            return "\(resource):read"
        case .saveNew, .create:
            return "\(resource):create"
        case .saveExisting:
            return "\(resource):update"
        case .delete:
            return "\(resource):delete"
        }
    }
}
