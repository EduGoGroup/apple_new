import Foundation
import EduModels

/// Resuelve el valor de un slot usando 3 fuentes en orden de prioridad.
public struct SlotBindingResolver: Sendable {
    public init() {}

    /// Resuelve el valor de un slot.
    /// Prioridad: 1) field -> datos del dataEndpoint
    ///            2) bind "slot:key" -> slotData estatico
    ///            3) value -> valor literal del slot
    public func resolve(
        slot: Slot,
        data: [String: JSONValue]?,
        slotData: [String: JSONValue]?
    ) -> JSONValue? {
        // Priority 1: field -> data from dataEndpoint
        if let field = slot.field, let data, let value = data[field] {
            return value
        }

        // Priority 2: bind "slot:key" -> static slotData
        if let bind = slot.bind, bind.hasPrefix("slot:") {
            let key = String(bind.dropFirst("slot:".count))
            if let slotData, let value = slotData[key] {
                return value
            }
        }

        // Priority 3: literal value from slot definition
        return slot.value
    }
}
