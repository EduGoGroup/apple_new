import Foundation
import OSLog
import EduModels

/// Resuelve el valor de un slot usando 3 fuentes en orden de prioridad.
public struct SlotBindingResolver: Sendable {
    private static let logger = os.Logger(
        subsystem: "com.edugo.dynamicui",
        category: "SlotBindingResolver"
    )

    public init() {}

    /// Resuelve el valor de un slot de forma defensiva.
    /// Prioridad: 1) field -> datos del dataEndpoint
    ///            2) bind "slot:key" -> slotData estatico
    ///            3) value -> valor literal del slot
    ///
    /// En caso de error inesperado, retorna el valor literal del slot como fallback.
    public func resolve(
        slot: Slot,
        data: [String: JSONValue]?,
        slotData: [String: JSONValue]?
    ) -> JSONValue? {
        do {
            return try resolveInternal(slot: slot, data: data, slotData: slotData)
        } catch {
            Self.logger.error(
                "[SlotBindingResolver] Error resolving slot '\(slot.id)': \(error.localizedDescription). Using fallback."
            )
            return slot.value
        }
    }

    private func resolveInternal(
        slot: Slot,
        data: [String: JSONValue]?,
        slotData: [String: JSONValue]?
    ) throws -> JSONValue? {
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
