import Foundation
import EduModels

/// Un slot representa un componente individual dentro de una zona.
public struct Slot: Codable, Sendable, Identifiable {
    public let id: String
    public let controlType: ControlType
    public let bind: String?
    public let field: String?
    public let label: String?
    public let value: JSONValue?
    public let placeholder: String?
    public let icon: String?
    public let required: Bool?
    public let readOnly: Bool?
    public let style: String?
    public let width: String?
    public let weight: Double?

    enum CodingKeys: String, CodingKey {
        case id, controlType, bind, field, label, value, placeholder, icon
        case required, readOnly, style, width, weight
    }
}
