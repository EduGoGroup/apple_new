/// Eventos que pueden ocurrir en una pantalla server-driven.
public enum ScreenEvent: String, Sendable {
    case loadData
    case saveNew
    case saveExisting
    case delete
    case search
    case selectItem
    case refresh
    case loadMore
    case create
}
