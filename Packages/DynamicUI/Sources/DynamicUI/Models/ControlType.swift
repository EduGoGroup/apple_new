/// Tipos de control disponibles para slots en el sistema Dynamic UI.
public enum ControlType: Sendable, Hashable {
    // Inputs
    case textInput
    case emailInput
    case passwordInput
    case numberInput
    case searchBar
    // Selection
    case checkbox
    case `switch`
    case radioGroup
    case select
    // Buttons
    case filledButton
    case outlinedButton
    case textButton
    case iconButton
    // Display
    case label
    case icon
    case avatar
    case image
    case divider
    case chip
    case rating
    // Compound
    case listItem
    case listItemNavigation
    case metricCard
    // Remote
    case remoteSelect
    // Unknown — forward compatibility
    case unknown(String)

    /// Mapping from raw string to known case.
    private static let knownCases: [String: ControlType] = [
        "text-input": .textInput,
        "email-input": .emailInput,
        "password-input": .passwordInput,
        "number-input": .numberInput,
        "search-bar": .searchBar,
        "checkbox": .checkbox,
        "switch": .switch,
        "radio-group": .radioGroup,
        "select": .select,
        "filled-button": .filledButton,
        "outlined-button": .outlinedButton,
        "text-button": .textButton,
        "icon-button": .iconButton,
        "label": .label,
        "icon": .icon,
        "avatar": .avatar,
        "image": .image,
        "divider": .divider,
        "chip": .chip,
        "rating": .rating,
        "list-item": .listItem,
        "list-item-navigation": .listItemNavigation,
        "metric-card": .metricCard,
        "remote_select": .remoteSelect,
    ]

    /// Initialize from a raw string value. Unknown values are preserved.
    public init(rawValue: String) {
        if let known = Self.knownCases[rawValue] {
            self = known
        } else {
            self = .unknown(rawValue)
        }
    }

    /// Mapping from known case to raw string.
    var rawValue: String {
        switch self {
        case .textInput: return "text-input"
        case .emailInput: return "email-input"
        case .passwordInput: return "password-input"
        case .numberInput: return "number-input"
        case .searchBar: return "search-bar"
        case .checkbox: return "checkbox"
        case .switch: return "switch"
        case .radioGroup: return "radio-group"
        case .select: return "select"
        case .filledButton: return "filled-button"
        case .outlinedButton: return "outlined-button"
        case .textButton: return "text-button"
        case .iconButton: return "icon-button"
        case .label: return "label"
        case .icon: return "icon"
        case .avatar: return "avatar"
        case .image: return "image"
        case .divider: return "divider"
        case .chip: return "chip"
        case .rating: return "rating"
        case .listItem: return "list-item"
        case .listItemNavigation: return "list-item-navigation"
        case .metricCard: return "metric-card"
        case .remoteSelect: return "remote_select"
        case .unknown(let value): return value
        }
    }
}

extension ControlType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        if let known = Self.knownCases[rawValue] {
            self = known
        } else {
            self = .unknown(rawValue)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
