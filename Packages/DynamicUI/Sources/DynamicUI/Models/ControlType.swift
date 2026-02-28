/// Tipos de control disponibles para slots en el sistema Dynamic UI.
public enum ControlType: String, Codable, Sendable {
    // Inputs
    case textInput = "text-input"
    case emailInput = "email-input"
    case passwordInput = "password-input"
    case numberInput = "number-input"
    case searchBar = "search-bar"
    // Selection
    case checkbox
    case `switch`
    case radioGroup = "radio-group"
    case select
    // Buttons
    case filledButton = "filled-button"
    case outlinedButton = "outlined-button"
    case textButton = "text-button"
    case iconButton = "icon-button"
    // Display
    case label
    case icon
    case avatar
    case image
    case divider
    case chip
    case rating
    // Compound
    case listItem = "list-item"
    case listItemNavigation = "list-item-navigation"
    case metricCard = "metric-card"
    // Remote
    case remoteSelect = "remote_select"
}
