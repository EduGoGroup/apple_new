import Foundation

// MARK: - Progress Request DTO

/// Request para actualizar el progreso de un usuario en un material.
///
/// Usado en `PUT /v1/progress` (operación upsert idempotente).
public struct UpsertProgressRequest: Encodable, Sendable, Equatable {
    /// ID del material.
    public let materialId: String

    /// ID del usuario.
    public let userId: String

    /// Porcentaje de progreso (0-100).
    public let percentage: Int

    /// Inicializa una request de actualización de progreso.
    /// - Parameters:
    ///   - materialId: ID del material (UUID).
    ///   - userId: ID del usuario (UUID).
    ///   - percentage: Porcentaje de progreso (0-100).
    public init(materialId: String, userId: String, percentage: Int) {
        self.materialId = materialId
        self.userId = userId
        self.percentage = percentage
    }

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case materialId = "material_id"
        case userId = "user_id"
        case percentage
    }
}

// MARK: - Progress Response DTO

/// Respuesta del endpoint de progreso.
///
/// Respuesta de `PUT /v1/progress`.
public struct ProgressDTO: Decodable, Sendable, Equatable {
    /// ID del usuario.
    public let userId: String

    /// ID del material.
    public let materialId: String

    /// Porcentaje de progreso (0-100).
    public let percentage: Int

    /// Fecha de última actualización.
    public let lastUpdated: Date

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case materialId = "material_id"
        case percentage
        case lastUpdated = "last_updated"
    }
}
