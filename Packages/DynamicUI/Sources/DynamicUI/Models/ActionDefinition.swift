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
public enum ActionTrigger: String, Codable, Sendable {
    case buttonClick = "button_click"
    case itemClick = "item_click"
    case pullRefresh = "pull_refresh"
    case fabClick = "fab_click"
    case swipe = "swipe"
    case longPress = "long_press"
}

/// Tipo de acción a ejecutar.
public enum ActionType: String, Codable, Sendable {
    case navigate = "NAVIGATE"
    case navigateBack = "NAVIGATE_BACK"
    case apiCall = "API_CALL"
    case submitForm = "SUBMIT_FORM"
    case refresh = "REFRESH"
    case confirm = "CONFIRM"
    case logout = "LOGOUT"
    case custom = "CUSTOM"
    case openUrl = "OPEN_URL"
}
