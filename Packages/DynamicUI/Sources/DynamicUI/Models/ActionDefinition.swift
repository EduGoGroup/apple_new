import Foundation
import EduModels

/// Definición de una acción que puede ejecutarse en una pantalla.
public struct ActionDefinition: Codable, Sendable, Identifiable {
    public let id: String
    public let trigger: ActionTrigger
    public let triggerSlotId: String?
    public let type: ActionType
    public let config: [String: JSONValue]?

    enum CodingKeys: String, CodingKey {
        case id, trigger, triggerSlotId, type, config
    }
}

/// Tipo de interacción que dispara una acción.
public enum ActionTrigger: Sendable, Hashable {
    case buttonClick
    case itemClick
    case pullRefresh
    case fabClick
    case swipe
    case longPress
    // Unknown — forward compatibility
    case unknown(String)

    private static let knownCases: [String: ActionTrigger] = [
        "button_click": .buttonClick,
        "item_click": .itemClick,
        "pull_refresh": .pullRefresh,
        "fab_click": .fabClick,
        "swipe": .swipe,
        "long_press": .longPress,
    ]

    public var rawValue: String {
        switch self {
        case .buttonClick: return "button_click"
        case .itemClick: return "item_click"
        case .pullRefresh: return "pull_refresh"
        case .fabClick: return "fab_click"
        case .swipe: return "swipe"
        case .longPress: return "long_press"
        case .unknown(let value): return value
        }
    }
}

extension ActionTrigger: Codable {
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

/// Tipo de acción a ejecutar.
public enum ActionType: Sendable, Hashable {
    case navigate
    case navigateBack
    case apiCall
    case submitForm
    case refresh
    case confirm
    case logout
    case custom
    case openUrl
    // Unknown — forward compatibility
    case unknown(String)

    private static let knownCases: [String: ActionType] = [
        "NAVIGATE": .navigate,
        "NAVIGATE_BACK": .navigateBack,
        "API_CALL": .apiCall,
        "SUBMIT_FORM": .submitForm,
        "REFRESH": .refresh,
        "CONFIRM": .confirm,
        "LOGOUT": .logout,
        "CUSTOM": .custom,
        "OPEN_URL": .openUrl,
    ]

    public var rawValue: String {
        switch self {
        case .navigate: return "NAVIGATE"
        case .navigateBack: return "NAVIGATE_BACK"
        case .apiCall: return "API_CALL"
        case .submitForm: return "SUBMIT_FORM"
        case .refresh: return "REFRESH"
        case .confirm: return "CONFIRM"
        case .logout: return "LOGOUT"
        case .custom: return "CUSTOM"
        case .openUrl: return "OPEN_URL"
        case .unknown(let value): return value
        }
    }
}

extension ActionType: Codable {
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
