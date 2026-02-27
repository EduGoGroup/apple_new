/// Patrones de pantalla soportados por el sistema Dynamic UI.
public enum ScreenPattern: String, Codable, Sendable, CaseIterable {
    case login
    case form
    case list
    case dashboard
    case settings
    case detail
    case search
    case profile
    case modal
    case notification
    case onboarding
    case emptyState = "empty-state"
}
