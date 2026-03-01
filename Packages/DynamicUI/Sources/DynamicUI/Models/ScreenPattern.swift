/// Patrones de pantalla soportados por el sistema Dynamic UI.
public enum ScreenPattern: Sendable, Hashable {
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
    case emptyState
    // Unknown — forward compatibility
    case unknown(String)

    /// Mapping from raw string to known case.
    private static let knownCases: [String: ScreenPattern] = [
        "login": .login,
        "form": .form,
        "list": .list,
        "dashboard": .dashboard,
        "settings": .settings,
        "detail": .detail,
        "search": .search,
        "profile": .profile,
        "modal": .modal,
        "notification": .notification,
        "onboarding": .onboarding,
        "empty-state": .emptyState,
    ]

    /// Initialize from a raw string value. Unknown values are preserved.
    public init(rawValue: String) {
        if let known = Self.knownCases[rawValue] {
            self = known
        } else {
            self = .unknown(rawValue)
        }
    }

    public var rawValue: String {
        switch self {
        case .login: return "login"
        case .form: return "form"
        case .list: return "list"
        case .dashboard: return "dashboard"
        case .settings: return "settings"
        case .detail: return "detail"
        case .search: return "search"
        case .profile: return "profile"
        case .modal: return "modal"
        case .notification: return "notification"
        case .onboarding: return "onboarding"
        case .emptyState: return "empty-state"
        case .unknown(let value): return value
        }
    }
}

extension ScreenPattern: CaseIterable {
    public static var allCases: [ScreenPattern] {
        [.login, .form, .list, .dashboard, .settings, .detail,
         .search, .profile, .modal, .notification, .onboarding, .emptyState]
    }
}

extension ScreenPattern: Codable {
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
