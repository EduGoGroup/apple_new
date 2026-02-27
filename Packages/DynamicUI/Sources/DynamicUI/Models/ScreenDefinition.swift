import Foundation
import EduModels

/// Definición completa de una pantalla server-driven.
public struct ScreenDefinition: Codable, Sendable, Identifiable {
    public let screenId: String
    public let screenKey: String
    public let screenName: String
    public let pattern: ScreenPattern
    public let version: Int
    public let template: ScreenTemplate
    public let slotData: [String: JSONValue]?
    public let dataEndpoint: String?
    public let dataConfig: DataConfig?
    public let actions: [ActionDefinition]
    public let handlerKey: String?
    public let updatedAt: String

    public var id: String { screenId }

    enum CodingKeys: String, CodingKey {
        case screenId, screenKey, screenName
        case pattern, version, template
        case slotData, dataEndpoint, dataConfig
        case actions, handlerKey, updatedAt
    }
}
