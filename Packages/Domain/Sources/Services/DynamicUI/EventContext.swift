import EduCore

/// Contexto necesario para ejecutar un evento en el orchestrator.
public struct EventContext: Sendable {
    public let screenKey: String
    public let userContext: ScreenUserContext
    public let selectedItem: [String: JSONValue]?
    public let fieldValues: [String: String]
    public let searchQuery: String?
    public let paginationOffset: Int

    public init(
        screenKey: String,
        userContext: ScreenUserContext,
        selectedItem: [String: JSONValue]? = nil,
        fieldValues: [String: String] = [:],
        searchQuery: String? = nil,
        paginationOffset: Int = 0
    ) {
        self.screenKey = screenKey
        self.userContext = userContext
        self.selectedItem = selectedItem
        self.fieldValues = fieldValues
        self.searchQuery = searchQuery
        self.paginationOffset = paginationOffset
    }
}
