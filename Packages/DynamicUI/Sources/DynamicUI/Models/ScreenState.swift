import EduModels

/// Contexto de ejecución de una acción.
public struct ActionContext: Sendable {
    public let screenKey: String
    public let actionId: String
    public let config: [String: JSONValue]?
    public let fieldValues: [String: String]
    public let selectedItemId: String?
    public let selectedItem: [String: JSONValue]?

    public init(
        screenKey: String,
        actionId: String,
        config: [String: JSONValue]? = nil,
        fieldValues: [String: String] = [:],
        selectedItemId: String? = nil,
        selectedItem: [String: JSONValue]? = nil
    ) {
        self.screenKey = screenKey
        self.actionId = actionId
        self.config = config
        self.fieldValues = fieldValues
        self.selectedItemId = selectedItemId
        self.selectedItem = selectedItem
    }
}

/// Resultado de ejecutar una acción.
public enum ActionResult: Sendable {
    case navigateTo(screenKey: String, params: [String: String]?)
    case success(message: String?)
    case error(message: String)
    case logout
    case cancelled
    case refresh
}

/// Estado de carga de una pantalla.
public enum ScreenState: Sendable {
    case loading
    case ready(ScreenDefinition)
    case error(String)
}

/// Estado de carga de datos dinámicos.
public enum DataState: Sendable {
    case idle
    case loading
    case success(items: [[String: JSONValue]], hasMore: Bool, loadingMore: Bool)
    case error(String)
}
