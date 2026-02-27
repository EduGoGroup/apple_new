import Foundation

/// Una zona es un contenedor de slots u otras zonas con distribución configurable.
public struct Zone: Codable, Sendable, Identifiable {
    public let id: String
    public let type: ZoneType
    public let distribution: Distribution?
    public let condition: String?
    public let slots: [Slot]?
    public let zones: [Zone]?
    public let itemLayout: ItemLayout?

    enum CodingKeys: String, CodingKey {
        case id, type, distribution, condition, slots, zones, itemLayout
    }
}

/// Layout de un item dentro de una lista.
public struct ItemLayout: Codable, Sendable {
    public let slots: [Slot]
}

/// Tipos de zona disponibles.
public enum ZoneType: String, Codable, Sendable {
    case container
    case formSection = "form-section"
    case simpleList = "simple-list"
    case groupedList = "grouped-list"
    case metricGrid = "metric-grid"
    case actionGroup = "action-group"
    case cardList = "card-list"
}

/// Distribución de los elementos dentro de una zona.
public enum Distribution: String, Codable, Sendable {
    case stacked
    case sideBySide = "side-by-side"
    case grid
    case flowRow = "flow-row"
}
