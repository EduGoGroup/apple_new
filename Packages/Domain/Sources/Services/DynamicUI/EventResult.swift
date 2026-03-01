import EduCore

/// Resultado de la ejecucion de un evento en el orchestrator.
public enum EventResult: Sendable {
    case success(message: String = "", data: JSONValue? = nil)
    case navigateTo(screenKey: String, params: [String: String] = [:])
    case error(message: String, canRetry: Bool = false)
    case permissionDenied
    case logout
    case cancelled
    case noOp
    case submitTo(endpoint: String, method: String, fieldValues: [String: JSONValue])
    case pendingDelete(screenKey: String, itemId: String, endpoint: String, method: String = "DELETE")
    case optimisticSuccess(updateId: String, message: String = "", optimisticData: JSONValue? = nil)
}
